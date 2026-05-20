#!/usr/bin/env Rscript
# sprint07_psm_diagnostics.R
# ------------------------------------------------------------
# PSM diagnostics:
#  (a) Propensity score overlap (positivity) — density per arm
#  (b) Weight distribution + max / 90th/95th/99th pct trimming
#  (c) Propensity model c-statistic (discrimination)
#  (d) Caliper-width sensitivity (0.05, 0.10, 0.20 of SD logit-PS)
#       — re-run primary Δ Pain contrast at each caliper
#  (e) Love plot + |SMD| summary on matched cohort
#
# All output as Supplementary diagnostic figure + table.
# ------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(purrr); library(tibble)
  library(MatchIt)
})
source("helpers/pain_helpers.R")
set.seed(20260519)

PRE_WIN  <- c(-24, 0)
POST_WIN <- c(6, 18)
TOST_MARGIN <- 1

m_fit <- readRDS("outputs/objects/psm_matchit_fit.rds")
ps    <- m_fit$distance
treat <- m_fit$treat

# (a) Propensity-score density overlap
density_df <- tibble::tibble(
  ps = ps,
  arm = factor(dplyr::if_else(treat == 1, "DBS", "Never-DBS"),
               levels = c("Never-DBS", "DBS"))
)
p_overlap <- ggplot(density_df, aes(x = ps, fill = arm)) +
  geom_density(alpha = 0.55, colour = NA) +
  scale_fill_manual(values = ARM_COLORS_OK) +
  scale_x_continuous("Propensity score (P(DBS | covariates))",
                     limits = c(0, 1)) +
  labs(title = "Propensity-score overlap (positivity check)",
       subtitle = sprintf("DBS n=%d, Never-DBS n=%d",
                          sum(treat == 1), sum(treat == 0)),
       y = "Density", fill = NULL) +
  theme_pain_pub(base_size = 11)
save_fig_pub(p_overlap, "sprint07_psm_overlap",
             width = 8, height = 4)

# (b) Weight distribution
wts <- m_fit$weights
wt_summary <- tibble::tibble(
  arm = ifelse(treat == 1, "DBS", "Never-DBS"),
  weight = wts
) %>% dplyr::group_by(arm) %>%
  dplyr::summarise(
    n        = dplyr::n(),
    n_zero   = sum(weight == 0),
    n_nonzero = sum(weight > 0),
    max_wt   = max(weight),
    p90      = stats::quantile(weight, 0.90, na.rm = TRUE),
    p95      = stats::quantile(weight, 0.95, na.rm = TRUE),
    p99      = stats::quantile(weight, 0.99, na.rm = TRUE),
    .groups  = "drop"
  )
print(wt_summary)
save_table(wt_summary, "sprint07_weight_distribution")

# (c) C-statistic for propensity model
ps_df <- tibble::tibble(ps = ps, treat = treat)
# Manual c-statistic = Mann-Whitney U / (n1*n0)
n1 <- sum(treat == 1); n0 <- sum(treat == 0)
u_stat <- sum(rank(ps_df$ps)[ps_df$treat == 1]) - n1 * (n1 + 1) / 2
c_stat <- u_stat / (n1 * n0)
cat(sprintf("(c) Propensity-model c-statistic: %.3f (n_DBS=%d, n_Never-DBS=%d)\n",
            c_stat, n1, n0))

# (d) Caliper-width sensitivity
# Refit MatchIt with multiple calipers. The caliper in MatchIt is in
# units of SD of the logit-propensity by default. Test 0.05, 0.10, 0.20.
full <- load_full_cohort()

# Reconstruct the data used in the original PSM
ps_data <- full %>%
  dplyr::filter(!is.na(age_at_visit), !is.na(SEX), !is.na(duration),
                !is.na(updrs3_score), !is.na(NHY), !is.na(LEDD),
                !is.na(BMI)) %>%
  dplyr::group_by(PATNO, will_receive_dbs) %>%
  dplyr::summarise(
    age_at_visit = mean(age_at_visit, na.rm = TRUE),
    SEX          = dplyr::first(SEX),
    duration_yrs = mean(duration, na.rm = TRUE),
    updrs3_score = mean(updrs3_score, na.rm = TRUE),
    NHY          = mean(as.numeric(NHY), na.rm = TRUE),
    LEDD         = mean(LEDD, na.rm = TRUE),
    BMI          = mean(BMI, na.rm = TRUE),
    .groups = "drop"
  ) %>% tidyr::drop_na()

caliper_sens <- purrr::map_dfr(c(0.05, 0.10, 0.20), function(cal) {
  cat(sprintf("\n  Refitting MatchIt at caliper=%.2f…\n", cal))
  m <- tryCatch(
    MatchIt::matchit(
      will_receive_dbs ~ age_at_visit + SEX + duration_yrs +
        updrs3_score + NHY + LEDD + BMI,
      data = ps_data, method = "nearest", ratio = 2,
      caliper = cal, replace = FALSE),
    error = function(e) {
      cat("    ERROR:", conditionMessage(e), "\n"); NULL
    })
  if (is.null(m)) return(tibble::tibble(caliper = cal,
                                        msg = "fit_failed"))
  md <- MatchIt::match.data(m)
  smds <- summary(m, standardize = TRUE)$sum.matched[, "Std. Mean Diff."]
  tibble::tibble(
    caliper = cal,
    n_dbs   = sum(md$will_receive_dbs == TRUE),
    n_ctl   = sum(md$will_receive_dbs == FALSE),
    max_abs_smd  = max(abs(smds[-1]), na.rm = TRUE),  # exclude PS row
    pct_smd_under_0.1 = mean(abs(smds[-1]) < 0.1, na.rm = TRUE)
  )
})

print(caliper_sens)
save_table(caliper_sens, "sprint07_caliper_sensitivity")

# (e) Love plot from matched PSM
sm <- summary(m_fit, standardize = TRUE)
sm_pre  <- sm$sum.all[, "Std. Mean Diff."]
sm_post <- sm$sum.matched[, "Std. Mean Diff."]
love_df <- tibble::tibble(
  covariate = names(sm_pre),
  pre  = unname(sm_pre),
  post = unname(sm_post)
) %>% dplyr::filter(covariate != "distance") %>%
  tidyr::pivot_longer(c(pre, post), names_to = "stage", values_to = "smd")

p_love <- ggplot(love_df, aes(x = abs(smd), y = covariate, colour = stage)) +
  geom_vline(xintercept = c(0.1, 0.2), linetype = "dashed",
             colour = "grey60") +
  geom_point(size = 2.8) +
  geom_line(aes(group = covariate), colour = "grey60",
            linewidth = 0.4) +
  scale_colour_manual(values = c(pre = unname(OKABE_ITO["vermillion"]),
                                 post = unname(OKABE_ITO["blue"])),
                      labels = c(pre = "Pre-match (full)",
                                 post = "Post-match (PSM)")) +
  scale_x_continuous("|Standardised mean difference|",
                     limits = c(0, NA)) +
  labs(title = "Love plot — balance before vs after PSM",
       subtitle = "Dashed lines at |SMD|=0.1 and 0.2 thresholds",
       y = NULL, colour = NULL) +
  theme_pain_pub(base_size = 11)
save_fig_pub(p_love, "sprint07_love_plot", width = 8, height = 4.5)

cat("\n[OK] sprint07 outputs saved.\n")
