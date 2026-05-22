#!/usr/bin/env Rscript
# 09_ledd_mediation.R
# ------------------------------------------------------------
# Mediation analysis: does Δ LEDD mediate the pain-motor decoupling
# observed in DBS vs Never-DBS?
#
# Hypothesised mechanism: DBS reduces LEDD; reduced LEDD changes
# both motor function and pain perception (since dopaminergic drugs
# modulate both). If Δ LEDD is the mediator, the decoupling has a
# pharmacological explanation; if not, it's a stimulation-specific
# (network-level) effect.
#
# Two contrasts:
#   (i)  arm  → Δ LEDD  → Δ Pain  (with Δ UPDRS-III as covariate)
#   (ii) arm  → Δ LEDD  → Δ |coupling|  (proxy: |Δ Pain − Δ UPDRS-III|)
#
# Outputs:
#   - 09_mediation_results.csv (ACME, ADE, total effect, %)
# ------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(purrr); library(tibble)
  library(mediation)
})
source("helpers/pain_helpers.R")
set.seed(20260519)

PRE_WIN  <- c(-24, 0)
POST_WIN <- c(6, 18)

# Build a single per-patient Δ frame containing Δ Pain, Δ UPDRS-III, Δ LEDD
build_triple_delta <- function(rel) {
  helper <- function(var) {
    pre <- rel %>%
      dplyr::filter(months >= PRE_WIN[1], months <= PRE_WIN[2],
                    !is.na(.data[[var]])) %>%
      dplyr::group_by(PATNO) %>%
      dplyr::summarise(pre = mean(.data[[var]]), .groups = "drop")
    post <- rel %>%
      dplyr::filter(months >= POST_WIN[1], months <= POST_WIN[2],
                    !is.na(.data[[var]])) %>%
      dplyr::group_by(PATNO) %>%
      dplyr::summarise(post = mean(.data[[var]]), .groups = "drop")
    pre %>% dplyr::inner_join(post, by = "PATNO") %>%
      dplyr::mutate(delta = post - pre) %>%
      dplyr::select(PATNO, !!paste0("delta_", var) := delta)
  }

  arm_df <- rel %>% dplyr::distinct(PATNO, will_receive_dbs)

  d_pain  <- helper("NP1PAIN")
  d_motor <- helper("updrs3_score")
  d_ledd  <- helper("LEDD")

  arm_df %>%
    dplyr::inner_join(d_pain,  by = "PATNO") %>%
    dplyr::inner_join(d_motor, by = "PATNO") %>%
    dplyr::inner_join(d_ledd,  by = "PATNO") %>%
    dplyr::mutate(
      arm = factor(dplyr::if_else(will_receive_dbs, "DBS", "Never-DBS"),
                   levels = c("Never-DBS", "DBS")),
      arm_int = as.integer(arm == "DBS"),
      # |coupling residual|: how much pain change is NOT explained by motor change
      pain_resid_abs = abs(delta_NP1PAIN - 0.05 * delta_updrs3_score)
    ) %>%
    tidyr::drop_na()
}

# ---- Matched cohort ----
rel_match <- load_matched_long()
anchors <- compute_symmetric_midpoint_anchors(rel_match)
rel_match <- rebind_time_cols(rel_match, anchors)
dd_match <- build_triple_delta(rel_match)
cat("Matched cohort triple-delta n =", nrow(dd_match), "\n")
print(dd_match %>% dplyr::count(arm))

# ---- Full cohort ----
rel_full <- load_full_ppmi_rel_patient_anchor()
dd_full <- build_triple_delta(rel_full)
cat("\nFull cohort triple-delta n =", nrow(dd_full), "\n")
print(dd_full %>% dplyr::count(arm))

run_mediation <- function(df, label) {
  cat(sprintf("\n=== Mediation analysis: %s (n=%d) ===\n", label, nrow(df)))
  cat("  arm → ΔLEDD → ΔPain (adjusted for ΔUPDRS-III)\n")

  # Mediator model: ΔLEDD ~ arm
  med_model <- stats::lm(delta_LEDD ~ arm_int, data = df)
  # Outcome model: ΔPain ~ arm + ΔLEDD + ΔUPDRS-III
  out_model <- stats::lm(delta_NP1PAIN ~ arm_int + delta_LEDD +
                           delta_updrs3_score, data = df)

  set.seed(20260519)
  med_out <- mediation::mediate(
    med_model, out_model,
    treat = "arm_int", mediator = "delta_LEDD",
    boot = TRUE, sims = 1000
  )

  out <- tibble::tibble(
    cohort        = label,
    outcome       = "delta_pain (adj for delta_motor)",
    ACME          = med_out$d0,
    ACME_lo       = med_out$d0.ci[1],
    ACME_hi       = med_out$d0.ci[2],
    ACME_p        = med_out$d0.p,
    ADE           = med_out$z0,
    ADE_lo        = med_out$z0.ci[1],
    ADE_hi        = med_out$z0.ci[2],
    ADE_p         = med_out$z0.p,
    total_effect  = med_out$tau.coef,
    total_lo      = med_out$tau.ci[1],
    total_hi      = med_out$tau.ci[2],
    total_p       = med_out$tau.p,
    prop_mediated = med_out$n0,
    prop_med_lo   = med_out$n0.ci[1],
    prop_med_hi   = med_out$n0.ci[2]
  )
  print(out)
  out
}

med_match <- run_mediation(dd_match, "matched")
med_full  <- run_mediation(dd_full,  "full")
med_tbl <- dplyr::bind_rows(med_match, med_full)
save_table(09$NAME, "09_mediation_results")

cat("\n[OK] 09 outputs saved.\n")
