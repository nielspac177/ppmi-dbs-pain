#!/usr/bin/env Rscript
# sprint01_negative_controls.R
# ------------------------------------------------------------
# Negative-control outcomes for the primary landmark Δ contrast.
#
# Rationale: the primary TOST framework concludes non-inferiority on Δ
# NP1PAIN. We rerun the SAME pipeline on three MDS-UPDRS Part I items
# with no a priori reason to respond to STN-DBS on a 12-month horizon:
#   NP1HALL (hallucinations)  — DBS should not affect on a 0–4 scale
#   NP1URIN (urinary)         — autonomic, not stimulation-modulable short-term
#   NP1COG  (cognition)       — known to remain stable / slowly decline
# A POSITIVE control (NP1PAIN itself) is included as the analytic anchor.
#
# If all negative controls also conclude non-inferiority at ±1 point,
# the pipeline is not mechanically declaring everything null — it
# preserves discrimination between a true null and a null-by-design.
# A "DBS effect" on any negative control would flag residual confounding.
#
# Outputs:
#   - outputs/tables/sprint01_negative_controls.csv (Δ + 95% CI + TOST)
#   - outputs/figures/sprint01_negative_controls.{png,pdf}
# ------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(purrr); library(tibble)
})
source("helpers/pain_helpers.R")
set.seed(20260519)

# Primary windows (paper Methods)
PRE_WIN  <- c(-24, 0)
POST_WIN <- c(6, 18)
TOST_MARGIN <- 1   # ±1 MDS-UPDRS Part I point — same as primary

# Outcomes: positive control (NP1PAIN), then three negative controls
OUTCOMES <- list(
  NP1PAIN = "Pain (primary, positive control)",
  NP1HALL = "Hallucinations (negative control)",
  NP1URIN = "Urinary (negative control)",
  NP1COG  = "Cognition (negative control)"
)

rel <- load_full_ppmi_rel_patient_anchor()
cat("Full cohort rows:", nrow(rel),
    "  patients:", dplyr::n_distinct(rel$PATNO),
    "  DBS:", dplyr::n_distinct(rel$PATNO[rel$will_receive_dbs]),
    "  Never-DBS:", dplyr::n_distinct(rel$PATNO[!rel$will_receive_dbs]), "\n\n")

compute_delta <- function(rel, var, pre_win, post_win) {
  pre <- rel %>%
    dplyr::filter(months >= pre_win[1], months <= pre_win[2],
                  !is.na(.data[[var]])) %>%
    dplyr::group_by(PATNO, will_receive_dbs) %>%
    dplyr::summarise(pre_mean = mean(.data[[var]]), .groups = "drop")
  post <- rel %>%
    dplyr::filter(months >= post_win[1], months <= post_win[2],
                  !is.na(.data[[var]])) %>%
    dplyr::group_by(PATNO) %>%
    dplyr::summarise(post_mean = mean(.data[[var]]), .groups = "drop")
  dplyr::inner_join(pre, post, by = "PATNO") %>%
    dplyr::mutate(
      delta = post_mean - pre_mean,
      arm = factor(dplyr::if_else(will_receive_dbs, "DBS", "Never-DBS"),
                   levels = c("Never-DBS", "DBS"))
    )
}

# Welch t + TOST at ±margin
contrast_with_tost <- function(d, margin = TOST_MARGIN) {
  # Direct subtraction: DBS − Never-DBS
  tt <- stats::t.test(d$delta[d$arm == "DBS"],
                      d$delta[d$arm == "Never-DBS"])
  m_dbs   <- unname(tt$estimate[1])
  m_ctrl  <- unname(tt$estimate[2])
  diff    <- m_dbs - m_ctrl
  ci      <- unname(tt$conf.int)
  # TOST: H0_l: diff <= -margin (so test diff > -margin); H0_u: diff >= +margin
  tt_l <- stats::t.test(d$delta[d$arm == "DBS"] + margin,
                        d$delta[d$arm == "Never-DBS"],
                        alternative = "greater", var.equal = FALSE)
  tt_u <- stats::t.test(d$delta[d$arm == "DBS"] - margin,
                        d$delta[d$arm == "Never-DBS"],
                        alternative = "less", var.equal = FALSE)
  tibble::tibble(
    n_dbs    = sum(d$arm == "DBS"),
    n_ctrl   = sum(d$arm == "Never-DBS"),
    mean_dbs = m_dbs,
    mean_ctrl = m_ctrl,
    diff     = diff,
    ci_lo    = ci[1],
    ci_hi    = ci[2],
    welch_p  = tt$p.value,
    tost_p_lower = tt_l$p.value,
    tost_p_upper = tt_u$p.value,
    tost_p_max   = max(tt_l$p.value, tt_u$p.value),
    tost_conclude_NI = (tt_l$p.value < 0.05) & (tt_u$p.value < 0.05),
    margin   = margin
  )
}

# Run per outcome (overall + stratum-stratified)
all_res <- purrr::imap_dfr(OUTCOMES, function(label, var) {
  d <- compute_delta(rel, var, PRE_WIN, POST_WIN)
  cat(sprintf("\n== %s (%s) ==\n   n=%d (DBS=%d, Never-DBS=%d)\n",
              var, label, nrow(d), sum(d$arm == "DBS"),
              sum(d$arm == "Never-DBS")))
  r_all <- contrast_with_tost(d) %>%
    dplyr::mutate(outcome = var, label = label, stratum = "All", .before = 1)
  # Stratify by baseline severity (Low <1 / Mod 1-<2 / High >=2)
  d <- d %>% dplyr::mutate(
    baseline_stratum = factor(dplyr::case_when(
      pre_mean >= 2 ~ "High (>=2)",
      pre_mean >= 1 ~ "Moderate (1 to <2)",
      TRUE          ~ "Low (<1)"),
      levels = c("Low (<1)", "Moderate (1 to <2)", "High (>=2)"))
  )
  r_strat <- purrr::map_dfr(levels(d$baseline_stratum), function(s) {
    sub <- d %>% dplyr::filter(baseline_stratum == s)
    if (sum(sub$arm == "DBS") < 5 || sum(sub$arm == "Never-DBS") < 5) {
      return(tibble::tibble(outcome = var, label = label, stratum = s,
                            n_dbs = sum(sub$arm == "DBS"),
                            n_ctrl = sum(sub$arm == "Never-DBS")))
    }
    contrast_with_tost(sub) %>%
      dplyr::mutate(outcome = var, label = label, stratum = s, .before = 1)
  })
  dplyr::bind_rows(r_all, r_strat)
})

# Reorder columns / clean up
all_res <- all_res %>%
  dplyr::select(outcome, label, stratum, n_dbs, n_ctrl, mean_dbs, mean_ctrl,
                diff, welch_p, tost_p_lower, tost_p_upper, tost_p_max,
                tost_conclude_NI, margin)
print(all_res, n = 50)
save_table(all_res, "sprint01_negative_controls")

# ---- Plot: forest of Δ (DBS - Never-DBS) per outcome, "All" stratum ----
plot_df <- all_res %>%
  dplyr::filter(stratum == "All") %>%
  dplyr::mutate(
    outcome_lab = factor(label, levels = rev(unname(unlist(OUTCOMES)))),
    is_primary  = outcome == "NP1PAIN"
  )

# Recompute CI on the diff itself
plot_df <- plot_df %>%
  dplyr::rowwise() %>%
  dplyr::mutate(
    se = abs(diff) / max(stats::qt(0.975, n_dbs + n_ctrl - 2), 1e-9)
  ) %>% dplyr::ungroup()

# Re-do CI properly from Welch
fix_ci <- function(rel, var, margin = TOST_MARGIN) {
  d <- compute_delta(rel, var, PRE_WIN, POST_WIN)
  # Direct subtraction: DBS − Never-DBS
  tt <- stats::t.test(d$delta[d$arm == "DBS"],
                      d$delta[d$arm == "Never-DBS"])
  est <- unname(tt$estimate[1] - tt$estimate[2])
  ci  <- unname(tt$conf.int)
  tibble::tibble(outcome = var, diff = est, ci_lo = ci[1], ci_hi = ci[2],
                 welch_p = tt$p.value)
}
ci_tbl <- purrr::map_dfr(names(OUTCOMES), fix_ci, rel = rel)
plot_df <- plot_df %>% dplyr::select(-diff) %>%
  dplyr::left_join(ci_tbl, by = "outcome")

p <- ggplot(plot_df, aes(x = diff, y = outcome_lab, colour = is_primary)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey55") +
  geom_vline(xintercept = c(-TOST_MARGIN, TOST_MARGIN),
             linetype = "dotted", colour = unname(OKABE_ITO["vermillion"])) +
  geom_errorbarh(aes(xmin = ci_lo, xmax = ci_hi), height = 0.15,
                 linewidth = 0.8) +
  geom_point(size = 3.5) +
  geom_text(aes(label = sprintf("Δ %+.2f (95%% CI %.2f, %.2f) n=%d/%d, TOST P=%.3f",
                                diff, ci_lo, ci_hi, n_dbs, n_ctrl, tost_p_max)),
            hjust = -0.05, vjust = -1.0, size = 3.0, colour = "grey25") +
  scale_colour_manual(values = c("TRUE" = unname(OKABE_ITO["vermillion"]),
                                 "FALSE" = unname(OKABE_ITO["blue"])),
                      guide = "none") +
  scale_x_continuous("Δ (DBS) − Δ (Never-DBS), MDS-UPDRS Part I points",
                     limits = c(-1.5, 1.5),
                     breaks = seq(-1.5, 1.5, 0.5)) +
  labs(
    title = "Negative-control outcomes — primary contrast at 12-month landmark",
    subtitle = sprintf(
      "Same landmark Δ framework as primary pain analysis. Dotted lines: ±%g-point TOST margin.",
      TOST_MARGIN),
    y = NULL
  ) +
  theme_pain_pub(base_size = 11)

save_fig_pub(p, "sprint01_negative_controls", width = 9.5, height = 4.5)
cat("\n[OK] sprint01_negative_controls saved.\n")
