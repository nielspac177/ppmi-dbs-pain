#!/usr/bin/env Rscript
# 26b_pain_motor_coupling_matched.R
# ------------------------------------------------------------
# Matched-cohort version of 26_pain_motor_coupling.R
# (n = 170; 64 DBS / 106 Never-DBS after 1:2 PSM on age, sex,
# disease duration, UPDRS-III, H&Y, LEDD, BMI).
#
# Same four analyses:
#   1. Baseline ordinal logit (MSS-tier ~ pain_cat [+ covariates])
#   2. Pain x arm interaction (LRT)
#   3. Within-patient Delta-Delta Spearman (pain vs UPDRS-III)
#   4. Window-by-window cross-sectional Spearman by arm
# ------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(purrr)
  library(tibble); library(MASS); library(broom); library(patchwork)
})
source("helpers/pain_helpers.R")

rel_raw <- load_matched_long()
cat("Matched rows:", nrow(rel_raw),
    "  Patients:", dplyr::n_distinct(rel_raw$PATNO), "\n")

# ----------------------------------------------------------
# Symmetric anchor:
#   DBS       -> keep first-dbs-date anchor already in CSV.
#   Never-DBS -> anchor at midpoint of each patient's own
#                INFODT_orig follow-up window (so they have
#                symmetric negative/positive bins rather than
#                an entirely post-anchor axis).
# ----------------------------------------------------------
dbs_anchors <- rel_raw %>%
  dplyr::filter(will_receive_dbs, !is.na(anchor_date)) %>%
  dplyr::distinct(PATNO, anchor_date)

ctl_anchors <- rel_raw %>%
  dplyr::filter(!will_receive_dbs, !is.na(INFODT_orig)) %>%
  dplyr::group_by(PATNO) %>%
  dplyr::summarise(
    # Cast to Date first: INFODT_orig reads in as POSIXct, and
    # `POSIXct + numeric` adds SECONDS (not days), which silently
    # collapsed the midpoint onto first_visit in earlier runs.
    first_visit = as.Date(min(INFODT_orig, na.rm = TRUE)),
    last_visit  = as.Date(max(INFODT_orig, na.rm = TRUE)),
    anchor_date = first_visit +
      as.numeric(difftime(last_visit, first_visit, units = "days")) / 2,
    .groups = "drop"
  ) %>%
  dplyr::select(PATNO, anchor_date)

anchors_sym <- dplyr::bind_rows(dbs_anchors, ctl_anchors) %>%
  dplyr::distinct(PATNO, .keep_all = TRUE)

rel <- rel_raw %>%
  dplyr::select(-anchor_date, -time_days, -time_pos,
                -time_pos_months, -months, -time_bin) %>%
  dplyr::left_join(anchors_sym, by = "PATNO") %>%
  dplyr::filter(!is.na(anchor_date)) %>%
  dplyr::mutate(
    # Force both sides to Date-typed arithmetic by using difftime on
    # consistent types. INFODT_orig comes in as POSIXct from readr.
    time_days   = as.numeric(difftime(as.Date(INFODT_orig),
                                      as.Date(anchor_date),
                                      units = "days")),
    time_months = time_days / DAYS_PER_MONTH,
    time_bin    = floor(time_days / 180),
    months      = time_bin * 6
  ) %>%
  dplyr::filter(is.finite(time_bin))

cat("Re-anchored rows:", nrow(rel),
    "  patients:", dplyr::n_distinct(rel$PATNO), "\n")
cat("Never-DBS months range after re-anchor:\n")
print(rel %>%
        dplyr::filter(!will_receive_dbs) %>%
        dplyr::summarise(min = min(months), max = max(months),
                         median_per_pt_min = median(months),
                         .groups = "drop"))

tier_mss <- function(u3) factor(
  dplyr::case_when(
    is.na(u3)   ~ NA_character_,
    u3 <= 32    ~ "Mild",
    u3 <= 58    ~ "Moderate",
    TRUE        ~ "Severe"
  ),
  levels = c("Mild", "Moderate", "Severe"),
  ordered = TRUE
)

tier_pain <- function(p) factor(
  dplyr::case_when(
    is.na(p) ~ NA_character_,
    p == 0   ~ "Pain-free",
    TRUE     ~ "Pain"
  ),
  levels = c("Pain-free", "Pain")
)

# ==========================================================
# 1. Baseline (pre-anchor) cross-section, matched cohort
# ==========================================================
baseline <- rel %>%
  dplyr::filter(months >= -24, months <= 0,
                !is.na(NP1PAIN), !is.na(updrs3_score)) %>%
  dplyr::arrange(PATNO, dplyr::desc(months)) %>%
  dplyr::group_by(PATNO, will_receive_dbs) %>%
  dplyr::slice_head(n = 1) %>%
  dplyr::ungroup() %>%
  dplyr::transmute(
    PATNO, will_receive_dbs,
    age    = age_at_visit,
    sex    = SEX,
    LEDD,
    pain_cat = tier_pain(NP1PAIN),
    mss_cat  = tier_mss(updrs3_score),
    updrs3_score, NP1PAIN,
    arm = factor(dplyr::if_else(will_receive_dbs, "DBS", "Never-DBS"),
                 levels = c("Never-DBS", "DBS"))
  ) %>%
  tidyr::drop_na(pain_cat, mss_cat)

cat("\nBaseline cross-section n:", nrow(baseline), "\n")
cat(" MSS tier table:\n"); print(table(baseline$mss_cat, useNA = "ifany"))
cat(" Pain tier x arm:\n")
print(table(baseline$pain_cat, baseline$arm))

# Matching already balanced age, sex, LEDD, arm, so we drop the
# covariate adjustment and report the unadjusted estimator only.
# Two analytic choices side-by-side:
#   (i)  ordinal logit on the 3-tier MSS variable (polr)
#   (ii) binary logistic at pre-specified cuts (>= 33 and >= 59).
# We report both; primary outcome will be whichever has the more
# useful / interpretable result.

baseline <- baseline %>%
  dplyr::mutate(
    mss_ge33 = as.integer(updrs3_score >= 33),   # at least moderate
    mss_ge59 = as.integer(updrs3_score >= 59)    # severe
  )

cat("\n==========================================================\n")
cat("(i) ORDINAL LOGIT on 3-tier MSS (Mild / Moderate / Severe)\n")
cat("==========================================================\n")

fit_ord_main <- MASS::polr(mss_cat ~ pain_cat, data = baseline,
                           Hess = TRUE, method = "logistic")
cat("\n -- Main: MSS-tier ~ pain_cat (unadjusted) --\n")
z <- summary(fit_ord_main)$coefficients
pv <- 2 * (1 - stats::pnorm(abs(z[, "t value"])))
print(cbind(z, p = pv))
tidy_ord <- broom::tidy(fit_ord_main, conf.int = TRUE,
                        exponentiate = TRUE)
print(tidy_ord)

fit_ord_me  <- MASS::polr(mss_cat ~ pain_cat + arm, data = baseline,
                          Hess = TRUE)
fit_ord_int <- MASS::polr(mss_cat ~ pain_cat * arm, data = baseline,
                          Hess = TRUE)
cat("\n -- Interaction: MSS-tier ~ pain * arm --\n")
zi <- summary(fit_ord_int)$coefficients
pvi <- 2 * (1 - stats::pnorm(abs(zi[, "t value"])))
print(cbind(zi, p = pvi))
lrt_ord <- anova(fit_ord_me, fit_ord_int)
cat(sprintf(" LRT pain:arm (vs main-effects ordinal model): p = %.3f\n",
            lrt_ord$`Pr(Chi)`[2]))

# Stratum-specific ordinal OR
cat(" Stratum-specific ordinal OR (chronic vs pain-free):\n")
for (a in c("Never-DBS", "DBS")) {
  sub <- baseline %>% dplyr::filter(arm == a)
  if (length(unique(sub$mss_cat)) < 2 ||
      length(unique(sub$pain_cat)) < 2) next
  f <- MASS::polr(mss_cat ~ pain_cat, data = sub, Hess = TRUE)
  cf <- summary(f)$coefficients["pain_catPain", ]
  ci <- suppressMessages(stats::confint.default(f))
  or <- exp(cf["Value"])
  lo <- exp(ci["pain_catPain", 1])
  hi <- exp(ci["pain_catPain", 2])
  pv <- 2 * (1 - stats::pnorm(abs(cf["t value"])))
  cat(sprintf("  [%s] OR = %.2f (95%% CI %.2f, %.2f), p = %.3f, n = %d\n",
              a, or, lo, hi, pv, nrow(sub)))
}

cat("\n==========================================================\n")
cat("(ii) BINARY LOGISTIC at pre-specified UPDRS-III cuts\n")
cat("==========================================================\n")

run_logit <- function(cut_var, label) {
  cat(sprintf("\n----- (1) Binary logistic: P(%s) ~ pain_cat -----\n", label))
  f_main <- stats::as.formula(paste(cut_var, "~ pain_cat"))
  fit    <- stats::glm(f_main, data = baseline, family = stats::binomial())
  print(summary(fit)$coefficients)
  cf <- stats::coef(summary(fit))["pain_catPain", ]
  ci <- suppressMessages(stats::confint.default(fit))["pain_catPain", ]
  cat(sprintf("OR pain = %.2f (95%% CI %.2f, %.2f), p = %.3f\n",
              exp(cf["Estimate"]), exp(ci[1]), exp(ci[2]),
              cf["Pr(>|z|)"]))

  # Main-effects (pain + arm) vs with interaction (pain * arm).
  # Arm is the exposure; matching balanced its confounders, so
  # including arm as a main effect is correct here.
  f_me  <- stats::as.formula(paste(cut_var, "~ pain_cat + arm"))
  f_int <- stats::as.formula(paste(cut_var, "~ pain_cat * arm"))
  fit_me <- stats::glm(f_me,  data = baseline, family = stats::binomial())
  fit_i  <- stats::glm(f_int, data = baseline, family = stats::binomial())
  cat(sprintf("\n  Interaction (pain x arm):\n"))
  print(summary(fit_i)$coefficients)
  lrt <- stats::anova(fit_me, fit_i, test = "LRT")
  cat(sprintf("  LRT pain:arm (vs main-effects model): p = %.3f\n",
              lrt$`Pr(>Chi)`[2]))

  # Stratum-specific OR
  for (a in c("Never-DBS", "DBS")) {
    sub <- baseline %>% dplyr::filter(arm == a)
    if (length(unique(sub[[cut_var]])) < 2 ||
        length(unique(sub$pain_cat)) < 2) next
    f_sub <- stats::glm(f_main, data = sub, family = stats::binomial())
    cf <- stats::coef(summary(f_sub))["pain_catPain", ]
    ci <- suppressMessages(stats::confint.default(f_sub))["pain_catPain", ]
    cat(sprintf("  [%s] OR = %.2f (95%% CI %.2f, %.2f), p = %.3f, n = %d\n",
                a, exp(cf["Estimate"]), exp(ci[1]), exp(ci[2]),
                cf["Pr(>|z|)"], nrow(sub)))
  }
  list(fit = fit, fit_i = fit_i, lrt = lrt)
}

res_ge33 <- run_logit("mss_ge33", "UPDRS-III >= 33 (at least moderate)")
res_ge59 <- run_logit("mss_ge59", "UPDRS-III >= 59 (severe)")

# Keep a summary table (both cuts, both arms)
cut_tbl <- purrr::map_dfr(c("mss_ge33", "mss_ge59"), function(cv) {
  purrr::map_dfr(c("Never-DBS", "DBS", "All"), function(a) {
    sub <- if (a == "All") baseline else baseline %>% dplyr::filter(arm == a)
    if (length(unique(sub[[cv]])) < 2 ||
        length(unique(sub$pain_cat)) < 2) {
      return(tibble::tibble(cut = cv, stratum = a, n = nrow(sub),
                            OR = NA_real_, lo = NA_real_,
                            hi = NA_real_, p = NA_real_))
    }
    f <- stats::as.formula(paste(cv, "~ pain_cat"))
    fit <- stats::glm(f, data = sub, family = stats::binomial())
    cf <- stats::coef(summary(fit))["pain_catPain", ]
    ci <- suppressMessages(stats::confint.default(fit))["pain_catPain", ]
    tibble::tibble(cut = cv, stratum = a, n = nrow(sub),
                   OR = exp(cf["Estimate"]),
                   lo = exp(ci[1]), hi = exp(ci[2]),
                   p  = cf["Pr(>|z|)"])
  })
})
print(cut_tbl)
save_table(cut_tbl, "pain_motor_matched_logit_table")
# Keep `lrt` object for the downstream figure annotation
lrt <- res_ge33$lrt

# ==========================================================
# 2. Delta-Delta in matched cohort
# ==========================================================
pre_win  <- c(-24, 0)
post_win <- c(6,  18)

in_pre <- rel %>%
  dplyr::filter(months >= pre_win[1],  months <= pre_win[2],
                !is.na(NP1PAIN), !is.na(updrs3_score))
in_post <- rel %>%
  dplyr::filter(months >= post_win[1], months <= post_win[2],
                !is.na(NP1PAIN), !is.na(updrs3_score))

pre <- in_pre %>%
  dplyr::group_by(PATNO, will_receive_dbs) %>%
  dplyr::summarise(pre_pain = mean(NP1PAIN),
                   pre_u3   = mean(updrs3_score),
                   .groups = "drop")
post <- in_post %>%
  dplyr::group_by(PATNO) %>%
  dplyr::summarise(post_pain = mean(NP1PAIN),
                   post_u3   = mean(updrs3_score),
                   .groups = "drop")
dd <- dplyr::inner_join(pre, post, by = "PATNO") %>%
  dplyr::mutate(d_pain = post_pain - pre_pain,
                d_u3   = post_u3   - pre_u3,
                arm    = factor(dplyr::if_else(will_receive_dbs,
                                               "DBS", "Never-DBS"),
                                levels = c("Never-DBS", "DBS")))

cat("\nDelta-delta n:", nrow(dd),
    "  DBS:", sum(dd$will_receive_dbs),
    "  Never-DBS:", sum(!dd$will_receive_dbs), "\n")

spearman_by_arm <- dd %>%
  dplyr::group_by(arm) %>%
  dplyr::summarise(
    n   = dplyr::n(),
    rho = stats::cor(d_pain, d_u3, method = "spearman",
                     use = "complete.obs"),
    p   = suppressWarnings(stats::cor.test(d_pain, d_u3,
                                           method = "spearman")$p.value),
    .groups = "drop"
  )
cat("\n------ (2) Matched: Delta pain vs Delta UPDRS-III Spearman, by arm ------\n")
print(spearman_by_arm)

za <- spearman_by_arm$rho[spearman_by_arm$arm == "DBS"]
zb <- spearman_by_arm$rho[spearman_by_arm$arm == "Never-DBS"]
na <- spearman_by_arm$n[spearman_by_arm$arm == "DBS"]
nb <- spearman_by_arm$n[spearman_by_arm$arm == "Never-DBS"]
z_diff <- (0.5 * log((1 + za) / (1 - za)) -
           0.5 * log((1 + zb) / (1 - zb))) /
           sqrt(1 / (na - 3) + 1 / (nb - 3))
p_diff <- 2 * (1 - stats::pnorm(abs(z_diff)))
cat(sprintf("\nFisher-z: DBS rho=%.3f (n=%d) vs Never-DBS rho=%.3f (n=%d); z=%.3f, p=%.3f\n",
            za, na, zb, nb, z_diff, p_diff))

save_table(spearman_by_arm, "pain_motor_matched_delta_delta_spearman")

# ==========================================================
# 3. Window-by-window Spearman, matched cohort
# ==========================================================
rel_dedup <- rel %>%
  dplyr::filter(!is.na(NP1PAIN), !is.na(updrs3_score)) %>%
  dedup_earliest_per_bin() %>%
  dplyr::select(PATNO, will_receive_dbs, months, NP1PAIN, updrs3_score)

bins <- seq(-18, 30, by = 6)
window_rows <- purrr::map_dfr(bins, function(b) {
  sub <- rel_dedup %>%
    dplyr::filter(months == b) %>%
    dplyr::mutate(arm = dplyr::if_else(will_receive_dbs,
                                        "DBS", "Never-DBS"))
  purrr::map_dfr(c("DBS", "Never-DBS"), function(a) {
    s <- sub %>% dplyr::filter(arm == a)
    if (nrow(s) < 10) {
      return(tibble::tibble(bin = b, arm = a, n = nrow(s),
                            rho = NA_real_, p = NA_real_))
    }
    ct <- suppressWarnings(stats::cor.test(s$NP1PAIN, s$updrs3_score,
                                            method = "spearman"))
    tibble::tibble(bin = b, arm = a, n = nrow(s),
                   rho = unname(ct$estimate), p = ct$p.value)
  })
})

cat("\n------ (3) Matched: Window-by-window Spearman ------\n")
print(window_rows, n = 50)
save_table(window_rows, "pain_motor_matched_window_spearman")

# ==========================================================
# Figure (matched cohort)
# ==========================================================
panel_A_data <- baseline %>%
  dplyr::count(arm, pain_cat, mss_cat) %>%
  dplyr::group_by(arm, pain_cat) %>%
  dplyr::mutate(prop = n / sum(n)) %>%
  dplyr::ungroup()

p_A <- ggplot(panel_A_data,
              aes(x = pain_cat, y = prop, fill = mss_cat)) +
  geom_col(width = 0.72, colour = "white") +
  geom_text(aes(label = scales::percent(prop, accuracy = 1)),
            position = position_stack(vjust = 0.5),
            size = 3, colour = "grey20") +
  facet_wrap(~ arm) +
  scale_fill_manual(values = c(Mild     = "#EAF2FA",
                               Moderate = "#9FC5E8",
                               Severe   = "#1E62A1"),
                    name = "Motor severity tier") +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1),
                     expand = expansion(mult = c(0, 0.02))) +
  labs(title = "A  Baseline motor-severity by pain status, matched cohort",
       x = NULL, y = "Proportion of patients") +
  theme_classic(base_size = 11) +
  theme(plot.title      = element_text(face = "bold"),
        strip.text      = element_text(face = "bold"),
        legend.position = "right",
        axis.text.x     = element_text(size = 10))

p_B <- ggplot(window_rows %>% dplyr::filter(!is.na(rho)),
              aes(x = bin, y = rho, colour = arm)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey55") +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey35") +
  geom_line(linewidth = 0.9) +
  geom_point(aes(size = n)) +
  scale_size_area(max_size = 5.5, name = "n") +
  scale_colour_manual(values = c("DBS" = "#CC6677",
                                 "Never-DBS" = "#332288"),
                      name = NULL) +
  scale_x_continuous("Months from anchor", breaks = bins) +
  scale_y_continuous("Spearman \u03C1 (NP1PAIN vs UPDRS-III)") +
  labs(title = "B  Cross-sectional pain-motor coupling over time, matched cohort") +
  theme_classic(base_size = 11) +
  theme(plot.title      = element_text(face = "bold"),
        legend.position = "right")

fig <- p_A / p_B + plot_layout(heights = c(1, 1))
ggsave(file.path(OUT_FIG, "Figure26b_pain_motor_coupling_matched.png"),
       fig, width = 11, height = 9, dpi = 300)
cat("\n[OK] Figure26b_pain_motor_coupling_matched.png saved\n")

save_table(
  tibble::tibble(
    term          = "pain_cat:arm",
    lrt_p         = lrt$`Pr(Chi)`[2],
    deviance_diff = lrt$`LR stat.`[2]
  ),
  "pain_motor_matched_interaction_lrt"
)
