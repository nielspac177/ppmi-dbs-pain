#!/usr/bin/env Rscript
# 26c_pain_as_outcome.R
# ------------------------------------------------------------
# Same pain <-> motor coupling question as 26 / 26b, but with
# PAIN AS THE OUTCOME (the natural framing for a pain paper).
#
# Parameterizations (all baseline, pre-anchor [-24, 0] mo):
#   (i)   Ordinal logit: NP1PAIN-3-tier  ~ motor cut(ge33)
#   (ii)  Binary logit : P(NP1PAIN >= 1) ~ motor cut(ge33)
#   (iii) Binary logit : P(NP1PAIN >= 2) ~ motor cut(ge33)
#
# Run on:
#   - Matched cohort (primary; symmetric midpoint anchor for ctrls)
#   - Full patient-anchor cohort (sensitivity)
#
# NOTE on thresholds: NP1PAIN is the MDS-UPDRS Part I item 9
# (0-4 ordinal). We define clinically meaningful tiers as:
#   None      = 0
#   Mild      = 1
#   Moderate+ = >= 2 (matches the paper-wide >=2 threshold used
#                      in the KM and alluvial analyses).
# ------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(purrr)
  library(tibble); library(MASS); library(broom)
})
source("helpers/pain_helpers.R")

# ==========================================================
# Shared helpers
# ==========================================================
tier_pain3 <- function(p) factor(
  dplyr::case_when(
    is.na(p) ~ NA_character_,
    p == 0   ~ "None",
    p == 1   ~ "Mild",
    TRUE     ~ "Moderate+"
  ),
  levels = c("None", "Mild", "Moderate+"),
  ordered = TRUE
)

build_baseline <- function(rel) {
  rel %>%
    dplyr::filter(months >= -24, months <= 0,
                  !is.na(NP1PAIN), !is.na(updrs3_score)) %>%
    dplyr::arrange(PATNO, dplyr::desc(months)) %>%
    dplyr::group_by(PATNO, will_receive_dbs) %>%
    dplyr::slice_head(n = 1) %>%
    dplyr::ungroup() %>%
    dplyr::transmute(
      PATNO, will_receive_dbs,
      age = age_at_visit, sex = SEX, LEDD,
      updrs3_score, NP1PAIN,
      pain3    = tier_pain3(NP1PAIN),
      pain_ge1 = as.integer(NP1PAIN >= 1),
      pain_ge2 = as.integer(NP1PAIN >= 2),
      motor_ge33 = as.integer(updrs3_score >= 33),
      arm = factor(dplyr::if_else(will_receive_dbs, "DBS", "Never-DBS"),
                   levels = c("Never-DBS", "DBS"))
    ) %>%
    tidyr::drop_na(pain3, motor_ge33)
}

# ------------------------------------------------------------
# Block 1: ordinal logit on pain3 ~ motor_ge33
# ------------------------------------------------------------
run_ord <- function(d, label) {
  cat(sprintf("\n-- ORDINAL: pain3 ~ motor_ge33 (%s) --\n", label))
  fit <- MASS::polr(pain3 ~ factor(motor_ge33), data = d,
                    Hess = TRUE, method = "logistic")
  z  <- summary(fit)$coefficients
  pv <- 2 * (1 - stats::pnorm(abs(z[, "t value"])))
  print(cbind(z, p = pv))
  cf <- z["factor(motor_ge33)1", ]
  ci <- suppressMessages(stats::confint.default(fit))["factor(motor_ge33)1", ]
  cat(sprintf(" OR motor>=33 -> higher pain tier: %.2f (95%% CI %.2f, %.2f), p = %.3f\n",
              exp(cf["Value"]), exp(ci[1]), exp(ci[2]),
              2 * (1 - stats::pnorm(abs(cf["t value"])))))

  # Interaction
  fit_me  <- MASS::polr(pain3 ~ factor(motor_ge33) + arm, data = d,
                        Hess = TRUE)
  fit_int <- MASS::polr(pain3 ~ factor(motor_ge33) * arm, data = d,
                        Hess = TRUE)
  lrt <- anova(fit_me, fit_int)
  cat(sprintf(" LRT motor:arm (vs main effects): p = %.3f\n",
              lrt$`Pr(Chi)`[2]))

  # Stratum-specific
  for (a in c("Never-DBS", "DBS")) {
    sub <- d %>% dplyr::filter(arm == a)
    if (length(unique(sub$pain3)) < 2 ||
        length(unique(sub$motor_ge33)) < 2) next
    f <- MASS::polr(pain3 ~ factor(motor_ge33), data = sub, Hess = TRUE)
    cf <- summary(f)$coefficients["factor(motor_ge33)1", ]
    ci <- suppressMessages(stats::confint.default(f))["factor(motor_ge33)1", ]
    pv <- 2 * (1 - stats::pnorm(abs(cf["t value"])))
    cat(sprintf("  [%s] OR = %.2f (95%% CI %.2f, %.2f), p = %.3f, n = %d\n",
                a, exp(cf["Value"]), exp(ci[1]), exp(ci[2]),
                pv, nrow(sub)))
  }
}

# ------------------------------------------------------------
# Block 2: binary logistic at two pain cuts
# ------------------------------------------------------------
run_bin <- function(d, cut_var, label) {
  cat(sprintf("\n-- LOGISTIC: P(%s) ~ motor_ge33 --\n", label))
  f <- stats::as.formula(paste(cut_var, "~ factor(motor_ge33)"))
  fit <- stats::glm(f, data = d, family = stats::binomial())
  cf <- stats::coef(summary(fit))["factor(motor_ge33)1", ]
  ci <- suppressMessages(stats::confint.default(fit))["factor(motor_ge33)1", ]
  cat(sprintf(" OR = %.2f (95%% CI %.2f, %.2f), p = %.3f\n",
              exp(cf["Estimate"]), exp(ci[1]), exp(ci[2]),
              cf["Pr(>|z|)"]))

  f_me  <- stats::as.formula(paste(cut_var, "~ factor(motor_ge33) + arm"))
  f_int <- stats::as.formula(paste(cut_var, "~ factor(motor_ge33) * arm"))
  fit_me <- stats::glm(f_me,  data = d, family = stats::binomial())
  fit_i  <- stats::glm(f_int, data = d, family = stats::binomial())
  lrt <- stats::anova(fit_me, fit_i, test = "LRT")
  cat(sprintf(" LRT motor:arm: p = %.3f\n", lrt$`Pr(>Chi)`[2]))

  for (a in c("Never-DBS", "DBS")) {
    sub <- d %>% dplyr::filter(arm == a)
    if (length(unique(sub[[cut_var]])) < 2 ||
        length(unique(sub$motor_ge33)) < 2) next
    fs <- stats::glm(f, data = sub, family = stats::binomial())
    cf <- stats::coef(summary(fs))["factor(motor_ge33)1", ]
    ci <- suppressMessages(stats::confint.default(fs))["factor(motor_ge33)1", ]
    cat(sprintf("  [%s] OR = %.2f (95%% CI %.2f, %.2f), p = %.3f, n = %d\n",
                a, exp(cf["Estimate"]), exp(ci[1]), exp(ci[2]),
                cf["Pr(>|z|)"], nrow(sub)))
  }
  # Return a tidy row per stratum for a summary table
  purrr::map_dfr(c("Never-DBS", "DBS", "All"), function(a) {
    sub <- if (a == "All") d else d %>% dplyr::filter(arm == a)
    if (length(unique(sub[[cut_var]])) < 2 ||
        length(unique(sub$motor_ge33)) < 2) {
      return(tibble::tibble(cut = cut_var, stratum = a, n = nrow(sub),
                            OR = NA_real_, lo = NA_real_,
                            hi = NA_real_, p = NA_real_))
    }
    fs <- stats::glm(f, data = sub, family = stats::binomial())
    cf <- stats::coef(summary(fs))["factor(motor_ge33)1", ]
    ci <- suppressMessages(stats::confint.default(fs))["factor(motor_ge33)1", ]
    tibble::tibble(cut = cut_var, stratum = a, n = nrow(sub),
                   OR = exp(cf["Estimate"]),
                   lo = exp(ci[1]), hi = exp(ci[2]),
                   p  = cf["Pr(>|z|)"])
  })
}

# ==========================================================
# MATCHED COHORT (primary), symmetric midpoint anchor
# ==========================================================
rel_raw <- load_matched_long()

dbs_anchors <- rel_raw %>%
  dplyr::filter(will_receive_dbs, !is.na(anchor_date)) %>%
  dplyr::distinct(PATNO, anchor_date)

ctl_anchors <- rel_raw %>%
  dplyr::filter(!will_receive_dbs, !is.na(INFODT_orig)) %>%
  dplyr::group_by(PATNO) %>%
  dplyr::summarise(
    anchor_date = {
      # INFODT_orig is POSIXct; POSIXct + numeric adds SECONDS, so we
      # cast to Date first to make the midpoint arithmetic behave in days.
      f <- as.Date(min(INFODT_orig, na.rm = TRUE))
      l <- as.Date(max(INFODT_orig, na.rm = TRUE))
      f + as.numeric(difftime(l, f, units = "days")) / 2
    },
    .groups = "drop"
  )

anchors_sym <- dplyr::bind_rows(dbs_anchors, ctl_anchors) %>%
  dplyr::distinct(PATNO, .keep_all = TRUE)

rel_match <- rel_raw %>%
  dplyr::select(-anchor_date, -time_days, -time_pos,
                -time_pos_months, -months, -time_bin) %>%
  dplyr::left_join(anchors_sym, by = "PATNO") %>%
  dplyr::filter(!is.na(anchor_date)) %>%
  dplyr::mutate(
    time_days   = as.numeric(difftime(as.Date(INFODT_orig),
                                      as.Date(anchor_date),
                                      units = "days")),
    time_months = time_days / DAYS_PER_MONTH,
    time_bin    = floor(time_days / 180),
    months      = time_bin * 6
  ) %>%
  dplyr::filter(is.finite(time_bin))

b_match <- build_baseline(rel_match)
cat("==========================================================\n")
cat("MATCHED COHORT (PRIMARY)\n")
cat("==========================================================\n")
cat("n = ", nrow(b_match), "  DBS=", sum(b_match$will_receive_dbs),
    "  Never-DBS=", sum(!b_match$will_receive_dbs), "\n", sep = "")
cat(" Pain3 x arm:\n"); print(table(b_match$pain3, b_match$arm))
cat(" motor_ge33 x arm:\n"); print(table(b_match$motor_ge33, b_match$arm))

run_ord(b_match, "matched")
m_ge1 <- run_bin(b_match, "pain_ge1", "NP1PAIN >= 1 (any pain)")
m_ge2 <- run_bin(b_match, "pain_ge2", "NP1PAIN >= 2 (moderate+)")
save_table(dplyr::bind_rows(m_ge1, m_ge2) %>%
             dplyr::mutate(cohort = "matched", .before = 1),
           "pain_as_outcome_matched_logit")

# ==========================================================
# FULL COHORT (supplementary / sensitivity)
# ==========================================================
rel_full <- load_full_ppmi_rel_patient_anchor()
b_full <- build_baseline(rel_full)
cat("\n==========================================================\n")
cat("FULL COHORT (SUPPLEMENTARY)\n")
cat("==========================================================\n")
cat("n = ", nrow(b_full), "  DBS=", sum(b_full$will_receive_dbs),
    "  Never-DBS=", sum(!b_full$will_receive_dbs), "\n", sep = "")
cat(" Pain3 x arm:\n"); print(table(b_full$pain3, b_full$arm))

run_ord(b_full, "full")
f_ge1 <- run_bin(b_full, "pain_ge1", "NP1PAIN >= 1 (any pain)")
f_ge2 <- run_bin(b_full, "pain_ge2", "NP1PAIN >= 2 (moderate+)")
save_table(dplyr::bind_rows(f_ge1, f_ge2) %>%
             dplyr::mutate(cohort = "full", .before = 1),
           "pain_as_outcome_full_logit")

cat("\nDone. Tables: pain_as_outcome_{matched,full}_logit.csv\n")
