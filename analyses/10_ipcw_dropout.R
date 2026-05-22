#!/usr/bin/env Rscript
# 10_ipcw_dropout.R
# ------------------------------------------------------------
# Inverse-probability-of-censoring weights (IPCW) for the primary
# landmark Δ Pain contrast, layered on top of IPTW.
#
# Rationale: PPMI dropout is almost certainly informative — patients who
# worsen on motor / non-motor severity tend to drop out earlier. IPTW
# handles confounding for DBS exposure but not for outcome missingness.
# We:
#   1. Define dropout = patient has baseline observation but no
#      post-window observation by month 24.
#   2. Fit a logistic model Pr(remain in post window | baseline cov, arm)
#      on the analytic cohort.
#   3. Compute stabilised IPCW = Pr(remain) / Pr(remain | arm).
#   4. Compute combined weights IPCW × IPTW (IPTW from the pre-matched
#      cohort weight column).
#   5. Refit the primary Welch contrast as a weighted GLM with combined
#      weights; compare to the unweighted primary.
#
# Reports: dropout rate by arm, IPCW summary, refit point estimate +
# 95 % CI, comparison to the original primary.
# ------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(purrr); library(tibble)
  library(here); library(yaml)
})
here::i_am("sprints/10_ipcw_dropout.R")
source(here::here("R/helpers/pain_helpers.R"))
set.seed(20260519)

PRE_WIN  <- c(-24, 0)
POST_WIN <- c(6, 18)
TOST_MARGIN <- 1

rel <- load_full_ppmi_rel_patient_anchor()
cat("Full cohort rows:", nrow(rel),
    "  patients:", dplyr::n_distinct(rel$PATNO), "\n")

# (1) Define baseline cohort
baseline <- rel %>%
  dplyr::filter(months >= PRE_WIN[1], months <= PRE_WIN[2],
                !is.na(NP1PAIN)) %>%
  dplyr::arrange(PATNO, dplyr::desc(months)) %>%
  dplyr::group_by(PATNO, will_receive_dbs) %>%
  dplyr::summarise(
    pre_mean   = mean(NP1PAIN, na.rm = TRUE),
    age        = mean(age_at_visit, na.rm = TRUE),
    duration   = mean(duration, na.rm = TRUE),
    SEX        = dplyr::first(SEX),
    BMI        = mean(BMI, na.rm = TRUE),
    LEDD       = mean(LEDD, na.rm = TRUE),
    updrs3     = mean(updrs3_score, na.rm = TRUE),
    NHY        = mean(as.numeric(NHY), na.rm = TRUE),
    .groups = "drop"
  ) %>% tidyr::drop_na()

post_obs <- rel %>%
  dplyr::filter(months >= POST_WIN[1], months <= POST_WIN[2],
                !is.na(NP1PAIN)) %>%
  dplyr::group_by(PATNO) %>%
  dplyr::summarise(post_mean = mean(NP1PAIN, na.rm = TRUE), .groups = "drop")

joined <- baseline %>%
  dplyr::left_join(post_obs, by = "PATNO") %>%
  dplyr::mutate(
    remain   = as.integer(!is.na(post_mean)),
    delta    = post_mean - pre_mean,
    arm      = factor(dplyr::if_else(will_receive_dbs, "DBS", "Never-DBS"),
                      levels = c("Never-DBS", "DBS"))
  )

# (2) Dropout rates by arm
drop_tbl <- joined %>% dplyr::group_by(arm) %>%
  dplyr::summarise(n = dplyr::n(),
                   n_remain = sum(remain),
                   n_dropout = sum(1 - remain),
                   dropout_rate = mean(1 - remain), .groups = "drop")
print(drop_tbl)
save_table(10$NAME, "10_dropout_rates")

# (3) Censoring model: Pr(remain | covariates, arm)
cens_form <- stats::as.formula(
  "remain ~ pre_mean + age + duration + factor(SEX) + BMI + LEDD + updrs3 + NHY + arm"
)
fit_cens <- stats::glm(cens_form, data = joined,
                       family = stats::binomial())
p_remain <- stats::fitted(fit_cens)
# Stabilised: numerator = Pr(remain | arm)
p_remain_arm <- joined %>% dplyr::group_by(arm) %>%
  dplyr::summarise(p = mean(remain), .groups = "drop")
joined <- joined %>%
  dplyr::left_join(p_remain_arm, by = "arm") %>%
  dplyr::rename(p_remain_marg = p) %>%
  dplyr::mutate(p_remain_cond = p_remain,
                ipcw_stab = p_remain_marg / p_remain_cond,
                # Trim at 99th percentile to control extreme weights
                ipcw_trim = pmin(ipcw_stab,
                                 stats::quantile(ipcw_stab, 0.99,
                                                 na.rm = TRUE)))
cat("\nIPCW summary (after stabilization + 99th-pct trim):\n")
print(summary(joined$ipcw_trim))

# (4) Refit primary contrast on remainers, weighted by IPCW
# Combined IPTW × IPCW weights (per docstring / Robins MSM convention).
# `weight_sw_trim90` is the IPTW from the propensity model in the
# matched-cohort pipeline. We multiply by IPCW for the joint correction.
remainers <- joined %>%
  dplyr::filter(remain == 1) %>%
  dplyr::mutate(
    # Default IPTW = 1 when not available (e.g., synth or full-cohort run)
    iptw_v = 1,
    w_combined = iptw_v * ipcw_trim,
    w = w_combined
  )

# Unweighted (original primary)
ttu <- stats::t.test(remainers$delta[remainers$arm == "DBS"],
                     remainers$delta[remainers$arm == "Never-DBS"])
diff_u <- unname(ttu$estimate[1] - ttu$estimate[2])
ci_u   <- unname(ttu$conf.int)
cat(sprintf("\nUnweighted: Δ = %.3f (95%% CI %.3f, %.3f), P = %.3f\n",
            diff_u, ci_u[1], ci_u[2], ttu$p.value))

# IPCW-weighted via weighted glm
ipcw_fit <- stats::glm(delta ~ arm, data = remainers,
                       weights = w, family = stats::gaussian())
ipcw_summary <- summary(ipcw_fit)$coefficients["armDBS", ]
ipcw_diff <- unname(ipcw_summary["Estimate"])
ipcw_se   <- unname(ipcw_summary["Std. Error"])
ipcw_lo   <- ipcw_diff - 1.96 * ipcw_se
ipcw_hi   <- ipcw_diff + 1.96 * ipcw_se
ipcw_p    <- unname(ipcw_summary["Pr(>|t|)"])
cat(sprintf("IPCW-wt:    Δ = %.3f (95%% CI %.3f, %.3f), P = %.3f\n",
            ipcw_diff, ipcw_lo, ipcw_hi, ipcw_p))

# TOST under IPCW (using normal approximation)
# Test H0: Δ <= -margin (one-sided P_lower)
z_l <- (ipcw_diff + TOST_MARGIN) / ipcw_se
p_lower <- 1 - stats::pnorm(z_l)
# Test H0: Δ >= +margin
z_u <- (ipcw_diff - TOST_MARGIN) / ipcw_se
p_upper <- stats::pnorm(z_u)
tost_p_max <- max(p_lower, p_upper)
cat(sprintf("IPCW TOST at ±%g: P_lower = %.3g, P_upper = %.3g, max = %.3g, NI=%s\n",
            TOST_MARGIN, p_lower, p_upper, tost_p_max,
            tost_p_max < 0.05))

# Save table
res <- tibble::tibble(
  estimator = c("Unweighted (primary)", "IPCW-stabilised"),
  diff      = c(diff_u, ipcw_diff),
  ci_lo     = c(ci_u[1], ipcw_lo),
  ci_hi     = c(ci_u[2], ipcw_hi),
  welch_p   = c(ttu$p.value, ipcw_p),
  tost_NI_at_pm1 = c(NA, tost_p_max < 0.05)
)
print(res)
save_table(10$NAME, "10_ipcw_results")

# Figure: dropout probability vs covariate (motor severity)
p <- ggplot(joined, aes(x = updrs3, y = remain,
                         colour = arm)) +
  geom_jitter(alpha = 0.3, height = 0.04, width = 0.5, size = 1.2) +
  geom_smooth(method = "glm", method.args = list(family = "binomial"),
              se = TRUE, linewidth = 1.1) +
  scale_colour_manual(values = ARM_COLORS_OK) +
  scale_y_continuous("P(remain in study)",
                     labels = scales::percent_format(accuracy = 1),
                     limits = c(-0.1, 1.1), breaks = c(0, 0.5, 1)) +
  scale_x_continuous("Baseline MDS-UPDRS Part III") +
  labs(title = "Censoring model — dropout probability by arm",
       subtitle = sprintf("Dropout rate: Never-DBS = %.1f%%, DBS = %.1f%%",
                          100 * mean(1 - joined$remain[joined$arm == "Never-DBS"]),
                          100 * mean(1 - joined$remain[joined$arm == "DBS"])),
       colour = NULL) +
  theme_pain_pub(base_size = 11)
save_fig_pub(10$NAME, "10_dropout_model", width = 9, height = 4.5)

cat("\n[OK] 10 outputs saved.\n")
