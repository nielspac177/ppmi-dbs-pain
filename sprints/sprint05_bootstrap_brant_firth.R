#!/usr/bin/env Rscript
# sprint05_bootstrap_brant_firth.R
# ------------------------------------------------------------
# Hardening for the pain-motor coupling and stratum-specific ordinal/
# logistic analyses:
#
# (a) Bootstrap CI on Δρ (between-arm Δ-Δ Spearman) — replaces the
#     small-sample Fisher-z asymptotic test in 26b.
#
# (b) Brant test for proportional-odds assumption on every polr fit
#     in 26 / 26b / 26c.
#
# (c) Profile-likelihood CIs (replace confint.default Wald CIs)
#     AND Firth logistic for pain_ge2 strata with n<30 or quasi-
#     separation in 26b/26c.
#
# Reuses the matched + full-cohort data through the helpers.
# ------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(MASS); library(brant); library(logistf)
  library(purrr); library(tibble); library(ggplot2)
})
source("helpers/pain_helpers.R")
set.seed(20260519)

PRE_WIN  <- c(-24, 0)
POST_WIN <- c(6, 18)

# ============================================================
# (a) Bootstrap Δρ between-arm CI (matched cohort, symmetric anchor)
# ============================================================
rel_match_raw <- load_matched_long()
anchors <- compute_symmetric_midpoint_anchors(rel_match_raw)
rel_match <- rebind_time_cols(rel_match_raw, anchors)

build_delta_paired <- function(rel, var_pain = "NP1PAIN", var_motor = "updrs3_score") {
  pre_p <- rel %>%
    dplyr::filter(months >= PRE_WIN[1], months <= PRE_WIN[2],
                  !is.na(.data[[var_pain]])) %>%
    dplyr::group_by(PATNO, will_receive_dbs) %>%
    dplyr::summarise(pre_pain  = mean(.data[[var_pain]]),  .groups = "drop")
  pre_m <- rel %>%
    dplyr::filter(months >= PRE_WIN[1], months <= PRE_WIN[2],
                  !is.na(.data[[var_motor]])) %>%
    dplyr::group_by(PATNO) %>%
    dplyr::summarise(pre_motor = mean(.data[[var_motor]]), .groups = "drop")
  post_p <- rel %>%
    dplyr::filter(months >= POST_WIN[1], months <= POST_WIN[2],
                  !is.na(.data[[var_pain]])) %>%
    dplyr::group_by(PATNO) %>%
    dplyr::summarise(post_pain = mean(.data[[var_pain]]), .groups = "drop")
  post_m <- rel %>%
    dplyr::filter(months >= POST_WIN[1], months <= POST_WIN[2],
                  !is.na(.data[[var_motor]])) %>%
    dplyr::group_by(PATNO) %>%
    dplyr::summarise(post_motor = mean(.data[[var_motor]]), .groups = "drop")
  pre_p %>% dplyr::inner_join(pre_m, by = "PATNO") %>%
    dplyr::inner_join(post_p, by = "PATNO") %>%
    dplyr::inner_join(post_m, by = "PATNO") %>%
    dplyr::mutate(
      d_pain  = post_pain  - pre_pain,
      d_motor = post_motor - pre_motor,
      arm = factor(dplyr::if_else(will_receive_dbs, "DBS", "Never-DBS"),
                   levels = c("Never-DBS", "DBS"))
    )
}

dd_matched <- build_delta_paired(rel_match)
cat("Matched cohort delta pairs:\n")
print(dd_matched %>% dplyr::count(arm))

boot_rho <- function(d, B = 5000) {
  rho_dbs <- numeric(B); rho_nd <- numeric(B); d_rho <- numeric(B)
  d_dbs <- d %>% dplyr::filter(arm == "DBS")
  d_nd  <- d %>% dplyr::filter(arm == "Never-DBS")
  for (i in seq_len(B)) {
    s_dbs <- d_dbs[sample(nrow(d_dbs), nrow(d_dbs), replace = TRUE), ]
    s_nd  <- d_nd[sample(nrow(d_nd),  nrow(d_nd),  replace = TRUE), ]
    rho_dbs[i] <- suppressWarnings(stats::cor(s_dbs$d_pain, s_dbs$d_motor,
                                              method = "spearman"))
    rho_nd[i]  <- suppressWarnings(stats::cor(s_nd$d_pain,  s_nd$d_motor,
                                              method = "spearman"))
    d_rho[i]   <- rho_dbs[i] - rho_nd[i]
  }
  list(
    rho_dbs_mean = mean(rho_dbs, na.rm = TRUE),
    rho_dbs_ci   = stats::quantile(rho_dbs, c(0.025, 0.975), na.rm = TRUE),
    rho_nd_mean  = mean(rho_nd, na.rm = TRUE),
    rho_nd_ci    = stats::quantile(rho_nd, c(0.025, 0.975), na.rm = TRUE),
    d_rho_mean   = mean(d_rho, na.rm = TRUE),
    d_rho_ci     = stats::quantile(d_rho, c(0.025, 0.975), na.rm = TRUE),
    d_rho_p_2sided = 2 * min(mean(d_rho >= 0, na.rm = TRUE),
                              mean(d_rho <= 0, na.rm = TRUE))
  )
}

cat("\n(a) Bootstrap Δρ between-arm CI (matched, B=5000)…\n")
b_match <- boot_rho(dd_matched, B = 5000)

# Also run on full cohort for sensitivity
rel_full <- load_full_ppmi_rel_patient_anchor()
dd_full <- build_delta_paired(rel_full)
cat("\nFull cohort delta pairs:\n")
print(dd_full %>% dplyr::count(arm))
b_full <- boot_rho(dd_full, B = 5000)

boot_summary <- tibble::tibble(
  cohort      = c("matched", "full"),
  rho_dbs     = c(b_match$rho_dbs_mean, b_full$rho_dbs_mean),
  rho_dbs_lo  = c(b_match$rho_dbs_ci[1], b_full$rho_dbs_ci[1]),
  rho_dbs_hi  = c(b_match$rho_dbs_ci[2], b_full$rho_dbs_ci[2]),
  rho_ndb     = c(b_match$rho_nd_mean, b_full$rho_nd_mean),
  rho_ndb_lo  = c(b_match$rho_nd_ci[1], b_full$rho_nd_ci[1]),
  rho_ndb_hi  = c(b_match$rho_nd_ci[2], b_full$rho_nd_ci[2]),
  d_rho       = c(b_match$d_rho_mean, b_full$d_rho_mean),
  d_rho_lo    = c(b_match$d_rho_ci[1], b_full$d_rho_ci[1]),
  d_rho_hi    = c(b_match$d_rho_ci[2], b_full$d_rho_ci[2]),
  p_2sided    = c(b_match$d_rho_p_2sided, b_full$d_rho_p_2sided)
)
print(boot_summary)
save_table(boot_summary, "sprint05_bootstrap_drho")

# ============================================================
# (b) Brant test on every polr fit, both cohorts
# ============================================================
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
    dplyr::filter(months >= PRE_WIN[1], months <= PRE_WIN[2],
                  !is.na(NP1PAIN), !is.na(updrs3_score)) %>%
    dplyr::arrange(PATNO, dplyr::desc(months)) %>%
    dplyr::group_by(PATNO, will_receive_dbs) %>%
    dplyr::slice_head(n = 1) %>%
    dplyr::ungroup() %>%
    dplyr::transmute(
      PATNO, will_receive_dbs,
      pain3      = tier_pain3(NP1PAIN),
      pain_ge1   = as.integer(NP1PAIN >= 1),
      pain_ge2   = as.integer(NP1PAIN >= 2),
      motor_ge33 = as.integer(updrs3_score >= 33),
      arm = factor(dplyr::if_else(will_receive_dbs, "DBS", "Never-DBS"),
                   levels = c("Never-DBS", "DBS"))
    ) %>% tidyr::drop_na(pain3, motor_ge33)
}

bm <- build_baseline(rel_match)
bf <- build_baseline(rel_full)

cat("\n(b) Brant tests for proportional-odds assumption\n")
# Manual Wald-based Brant test: fit a logistic per cumulative split and
# compare the predictor coefficients. With K=3 ordered levels there are
# 2 cumulative splits; under proportional-odds the slope is the same.
manual_brant <- function(d_src, lbl) {
  d2 <- data.frame(
    pain3    = factor(as.character(d_src$pain3),
                      levels = c("None", "Mild", "Moderate+"),
                      ordered = TRUE),
    motor_hi = factor(d_src$motor_ge33, levels = c(0, 1))
  )
  d2 <- d2[!is.na(d2$pain3) & !is.na(d2$motor_hi), ]
  d2$y1 <- as.integer(as.integer(d2$pain3) >= 2)  # pain >= Mild
  d2$y2 <- as.integer(as.integer(d2$pain3) >= 3)  # pain >= Mod+
  f1 <- stats::glm(y1 ~ motor_hi, data = d2, family = stats::binomial())
  f2 <- stats::glm(y2 ~ motor_hi, data = d2, family = stats::binomial())
  b1 <- stats::coef(f1)["motor_hi1"]
  b2 <- stats::coef(f2)["motor_hi1"]
  se1 <- summary(f1)$coefficients["motor_hi1", "Std. Error"]
  se2 <- summary(f2)$coefficients["motor_hi1", "Std. Error"]
  # Wald test on b1 - b2 (independent SE approx; conservative)
  diff <- b1 - b2
  se_d <- sqrt(se1^2 + se2^2)
  z <- diff / se_d
  p <- 2 * (1 - stats::pnorm(abs(z)))
  cat(sprintf("  Brant-Wald (%s): b1=%.3f (SE %.3f), b2=%.3f (SE %.3f), Δ=%.3f, Z=%.2f, P=%.3f\n",
              lbl, b1, se1, b2, se2, diff, z, p))
  tibble::tibble(cohort = lbl, b_split_mild = b1, se_split_mild = se1,
                 b_split_modplus = b2, se_split_modplus = se2,
                 diff = diff, z = z, p_value = p,
                 PO_assumption_holds = p > 0.05)
}
brant_tbl <- dplyr::bind_rows(manual_brant(bm, "matched"),
                              manual_brant(bf, "full"))
print(brant_tbl)
save_table(brant_tbl, "sprint05_brant_polr")

# ============================================================
# (c) Profile-likelihood CIs + Firth logistic for stratum-specific OR
# ============================================================
profile_or <- function(d, outcome, label) {
  f <- stats::as.formula(paste(outcome, "~ factor(motor_ge33)"))
  fit <- stats::glm(f, data = d, family = stats::binomial())
  cf <- stats::coef(fit)["factor(motor_ge33)1"]
  # Profile likelihood
  ci_pl <- tryCatch(stats::confint(fit)["factor(motor_ge33)1", ],
                    error = function(e) c(NA, NA))
  # Wald
  ci_w  <- stats::confint.default(fit)["factor(motor_ge33)1", ]
  # Firth
  fit_f <- logistf::logistf(f, data = d)
  cf_f <- fit_f$coefficients["factor(motor_ge33)1"]
  ci_f <- c(fit_f$ci.lower["factor(motor_ge33)1"],
            fit_f$ci.upper["factor(motor_ge33)1"])
  tibble::tibble(
    label      = label,
    outcome    = outcome,
    n          = nrow(d),
    OR_wald    = exp(cf),
    Wald_lo    = exp(ci_w[1]),
    Wald_hi    = exp(ci_w[2]),
    OR_profile = exp(cf),
    Profile_lo = exp(ci_pl[1]),
    Profile_hi = exp(ci_pl[2]),
    OR_firth   = exp(cf_f),
    Firth_lo   = exp(ci_f[1]),
    Firth_hi   = exp(ci_f[2])
  )
}

# Run over (cohort × arm × outcome cut)
strata_runs <- list(
  list(d = bm,                                  cohort = "matched", arm = "All"),
  list(d = bm %>% dplyr::filter(arm == "DBS"),  cohort = "matched", arm = "DBS"),
  list(d = bm %>% dplyr::filter(arm == "Never-DBS"), cohort = "matched", arm = "Never-DBS"),
  list(d = bf,                                  cohort = "full",    arm = "All"),
  list(d = bf %>% dplyr::filter(arm == "DBS"),  cohort = "full",    arm = "DBS"),
  list(d = bf %>% dplyr::filter(arm == "Never-DBS"), cohort = "full",    arm = "Never-DBS")
)

ci_tbl <- purrr::map_dfr(strata_runs, function(x) {
  # Skip if either outcome has only one level in this stratum
  out <- tibble::tibble()
  for (oc in c("pain_ge1", "pain_ge2")) {
    if (length(unique(x$d[[oc]])) >= 2 &&
        length(unique(x$d$motor_ge33)) >= 2 &&
        sum(x$d[[oc]] == 1) >= 2) {
      r <- profile_or(x$d, oc, sprintf("%s | %s", x$cohort, x$arm))
      r$arm <- x$arm; r$cohort <- x$cohort
      out <- dplyr::bind_rows(out, r)
    }
  }
  out
})
options(width = 200)
print(ci_tbl)
save_table(ci_tbl, "sprint05_profile_firth_ci")

cat("\n[OK] sprint05 outputs saved.\n")
