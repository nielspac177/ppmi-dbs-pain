#!/usr/bin/env Rscript
# 26_pain_motor_coupling.R
# ------------------------------------------------------------
# Pain x Motor-severity coupling, replicating and extending the
# Pacheco-Barrios 2025 (Parkinson's Dis. PMID 40003677) finding in
# the PPMI cohort:
#
#   Original finding (cross-sectional, n=50, ordinal logit):
#     Pain -> 3.52x higher odds of low->medium MSS
#                     5.44x higher odds of medium->severe MSS.
#
# Here we:
#   1. Replicate the ordinal-logit association at PPMI baseline
#      (pre-anchor [-24, 0] mo).
#   2. Add arm (DBS vs Never-DBS) and pain-category x arm
#      interaction.
#   3. Extend longitudinally: within-patient delta-delta Spearman
#      correlation between Delta NP1PAIN and Delta UPDRS-III from
#      pre to post, per arm, with Fisher-z comparison.
#   4. Window-by-window cross-sectional Spearman in 6-month bins
#      by arm, to see if pain-motor coupling drifts after DBS.
# ------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(purrr)
  library(tibble); library(MASS); library(broom); library(patchwork)
})
source("helpers/pain_helpers.R")

rel <- load_full_ppmi_rel_patient_anchor()
cat("Full patient-anchor rows:", nrow(rel),
    "  Patients:", dplyr::n_distinct(rel$PATNO), "\n")

# ==========================================================
# Categorise pain and UPDRS-III to match the Jena paper
# ==========================================================
# Pain: NP1PAIN 0 vs >=1 (pain-free vs chronic).
# The 2025 paper distinguishes pain-free vs pain;
# NP1PAIN=0 maps to pain-free, >=1 to chronic-pain category.
#
# UPDRS-III -> MSS tier via conventional thresholds:
#   Mild     UPDRS-III <= 32
#   Moderate 33-58
#   Severe   >= 59
# (Martinez-Martin 2015 reference thresholds for H&Y era).
# ----------------------------------------------------------

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
# 1. Baseline (pre-anchor) cross-section for ordinal logit
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

# ---------- (i) Ordinal logit on 3-tier MSS ----------
baseline <- baseline %>%
  dplyr::mutate(
    mss_ge33 = as.integer(updrs3_score >= 33),
    mss_ge59 = as.integer(updrs3_score >= 59)
  )

cat("\n========== FULL COHORT (supplementary / sensitivity) ==========\n")
cat("(i) ORDINAL LOGIT: MSS-tier (Mild/Moderate/Severe) ~ pain_cat\n")

fit_ord_main <- MASS::polr(mss_cat ~ pain_cat, data = baseline,
                           Hess = TRUE, method = "logistic")
z  <- summary(fit_ord_main)$coefficients
pv <- 2 * (1 - stats::pnorm(abs(z[, "t value"])))
cat("\n -- Main: MSS-tier ~ pain_cat (unadjusted) --\n")
print(cbind(z, p = pv))
print(broom::tidy(fit_ord_main, conf.int = TRUE, exponentiate = TRUE))

fit_ord_me  <- MASS::polr(mss_cat ~ pain_cat + arm, data = baseline,
                          Hess = TRUE)
fit_ord_int <- MASS::polr(mss_cat ~ pain_cat * arm, data = baseline,
                          Hess = TRUE)
cat("\n -- Interaction: MSS-tier ~ pain * arm --\n")
zi <- summary(fit_ord_int)$coefficients
pvi <- 2 * (1 - stats::pnorm(abs(zi[, "t value"])))
print(cbind(zi, p = pvi))
lrt_ord <- anova(fit_ord_me, fit_ord_int)
cat(sprintf(" LRT pain:arm (vs main-effects): p = %.3f\n",
            lrt_ord$`Pr(Chi)`[2]))

cat(" Stratum-specific ordinal OR:\n")
for (a in c("Never-DBS", "DBS")) {
  sub <- baseline %>% dplyr::filter(arm == a)
  if (length(unique(sub$mss_cat)) < 2) next
  f  <- MASS::polr(mss_cat ~ pain_cat, data = sub, Hess = TRUE)
  cf <- summary(f)$coefficients["pain_catPain", ]
  ci <- suppressMessages(stats::confint.default(f))["pain_catPain", ]
  pv <- 2 * (1 - stats::pnorm(abs(cf["t value"])))
  cat(sprintf("  [%s] OR = %.2f (95%% CI %.2f, %.2f), p = %.3f, n = %d\n",
              a, exp(cf["Value"]), exp(ci[1]), exp(ci[2]),
              pv, nrow(sub)))
}

cat("\n(ii) BINARY LOGISTIC at pre-specified UPDRS-III cuts\n")

run_logit <- function(cut_var, label) {
  cat(sprintf("\n -- P(%s) ~ pain_cat (unadjusted) --\n", label))
  f_main <- stats::as.formula(paste(cut_var, "~ pain_cat"))
  fit    <- stats::glm(f_main, data = baseline, family = stats::binomial())
  print(summary(fit)$coefficients)
  cf <- stats::coef(summary(fit))["pain_catPain", ]
  ci <- suppressMessages(stats::confint.default(fit))["pain_catPain", ]
  cat(sprintf(" OR = %.2f (95%% CI %.2f, %.2f), p = %.3f\n",
              exp(cf["Estimate"]), exp(ci[1]), exp(ci[2]),
              cf["Pr(>|z|)"]))
  f_me  <- stats::as.formula(paste(cut_var, "~ pain_cat + arm"))
  f_int <- stats::as.formula(paste(cut_var, "~ pain_cat * arm"))
  fit_me <- stats::glm(f_me,  data = baseline, family = stats::binomial())
  fit_i  <- stats::glm(f_int, data = baseline, family = stats::binomial())
  lrt <- stats::anova(fit_me, fit_i, test = "LRT")
  cat(sprintf(" LRT pain:arm (vs main-effects): p = %.3f\n",
              lrt$`Pr(>Chi)`[2]))
  for (a in c("Never-DBS", "DBS")) {
    sub <- baseline %>% dplyr::filter(arm == a)
    if (length(unique(sub[[cut_var]])) < 2) next
    f_sub <- stats::glm(f_main, data = sub, family = stats::binomial())
    cf <- stats::coef(summary(f_sub))["pain_catPain", ]
    ci <- suppressMessages(stats::confint.default(f_sub))["pain_catPain", ]
    cat(sprintf("  [%s] OR = %.2f (95%% CI %.2f, %.2f), p = %.3f, n = %d\n",
                a, exp(cf["Estimate"]), exp(ci[1]), exp(ci[2]),
                cf["Pr(>|z|)"], nrow(sub)))
  }
}
run_logit("mss_ge33", "UPDRS-III >= 33 (at least moderate)")
run_logit("mss_ge59", "UPDRS-III >= 59 (severe)")

# Persist stratum-specific table
cut_tbl <- purrr::map_dfr(c("mss_ge33", "mss_ge59"), function(cv) {
  purrr::map_dfr(c("Never-DBS", "DBS", "All"), function(a) {
    sub <- if (a == "All") baseline else baseline %>% dplyr::filter(arm == a)
    if (length(unique(sub[[cv]])) < 2) {
      return(tibble::tibble(cut = cv, stratum = a, n = nrow(sub),
                            OR = NA_real_, lo = NA_real_,
                            hi = NA_real_, p = NA_real_))
    }
    f  <- stats::as.formula(paste(cv, "~ pain_cat"))
    fit <- stats::glm(f, data = sub, family = stats::binomial())
    cf <- stats::coef(summary(fit))["pain_catPain", ]
    ci <- suppressMessages(stats::confint.default(fit))["pain_catPain", ]
    tibble::tibble(cut = cv, stratum = a, n = nrow(sub),
                   OR = exp(cf["Estimate"]),
                   lo = exp(ci[1]), hi = exp(ci[2]),
                   p  = cf["Pr(>|z|)"])
  })
})
save_table(cut_tbl, "pain_motor_full_logit_table")
lrt <- lrt_ord   # kept for figure annotation

# ==========================================================
# 2. Delta-Delta (within-patient): does change in pain track
#    change in motor over the pre -> post window, per arm?
# ==========================================================
pre_win  <- c(-24, 0)
post_win <- c(6,  18)

compute_delta_delta <- function() {
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
                     n_pre    = dplyr::n(),
                     .groups = "drop")
  post <- in_post %>%
    dplyr::group_by(PATNO) %>%
    dplyr::summarise(post_pain = mean(NP1PAIN),
                     post_u3   = mean(updrs3_score),
                     .groups = "drop")
  dplyr::inner_join(pre, post, by = "PATNO") %>%
    dplyr::mutate(d_pain = post_pain - pre_pain,
                  d_u3   = post_u3   - pre_u3,
                  arm    = factor(dplyr::if_else(will_receive_dbs,
                                                 "DBS", "Never-DBS"),
                                  levels = c("Never-DBS", "DBS")))
}

dd <- compute_delta_delta()
cat("\nDelta-delta n:", nrow(dd),
    "  DBS:", sum(dd$will_receive_dbs),
    "  Never-DBS:", sum(!dd$will_receive_dbs), "\n")

spearman_by_arm <- dd %>%
  dplyr::group_by(arm) %>%
  dplyr::summarise(
    n     = dplyr::n(),
    rho   = stats::cor(d_pain, d_u3, method = "spearman",
                       use = "complete.obs"),
    p     = suppressWarnings(stats::cor.test(d_pain, d_u3,
                                             method = "spearman")$p.value),
    .groups = "drop"
  )
cat("\n------ (2) Within-patient Delta pain vs Delta UPDRS-III Spearman, by arm ------\n")
print(spearman_by_arm)

# Fisher-z comparison of two rhos
fisher_z <- function(r, n) 0.5 * log((1 + r) / (1 - r)) *
                          sqrt((n - 3))
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

save_table(spearman_by_arm, "pain_motor_delta_delta_spearman")

# ==========================================================
# 3. Window-by-window Spearman (longitudinal coupling)
# ==========================================================
bins <- seq(-18, 30, by = 6)
# Dedup to one row per patient per bin (earliest visit in bin).
rel_dedup <- rel %>%
  dplyr::filter(!is.na(NP1PAIN), !is.na(updrs3_score)) %>%
  dedup_earliest_per_bin() %>%
  dplyr::select(PATNO, will_receive_dbs, months, NP1PAIN, updrs3_score)

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

cat("\n------ (3) Window-by-window Spearman (NP1PAIN vs UPDRS-III) ------\n")
print(window_rows, n = 50)
save_table(window_rows, "pain_motor_window_spearman")

# ==========================================================
# Figure: two-panel
#   (A) Baseline stacked bar MSS tier proportion x pain tier x arm
#   (B) Window Spearman rho over time, by arm
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
  labs(title = "A  Baseline motor-severity by pain status, by arm",
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
  scale_y_continuous("Spearman rho (NP1PAIN vs UPDRS-III)") +
  labs(title = "B  Cross-sectional pain-motor coupling over time, by arm") +
  theme_classic(base_size = 11) +
  theme(plot.title      = element_text(face = "bold"),
        legend.position = "right")

fig <- p_A / p_B + plot_layout(heights = c(1, 1))
ggsave(file.path(OUT_FIG, "Figure26_pain_motor_coupling.png"),
       fig, width = 11, height = 9, dpi = 300)
cat("\n[OK] Figure26_pain_motor_coupling.png saved\n")

# Persist the interaction LRT table for paper use
save_table(
  tibble::tibble(
    term = "pain_cat:arm",
    lrt_p = lrt$`Pr(Chi)`[2],
    deviance_diff = lrt$`LR stat.`[2]
  ),
  "pain_motor_interaction_lrt"
)
