#!/usr/bin/env Rscript
# sprint02_anchor_sensitivity.R
# ------------------------------------------------------------
# Anchor sensitivity sweep for the primary landmark Δ Pain contrast.
#
# Three Never-DBS anchor strategies (DBS arm always uses first surgery):
#   A. Patient anchor       (own earliest visit)  — load_full_ppmi_rel_patient_anchor
#   B. Cohort-median anchor (shared median DBS date) — load_full_ppmi_rel
#   C. Symmetric midpoint   (own midpoint of follow-up) — compute_symmetric_midpoint_anchors
#
# The primary TOST conclusion should be invariant across A/B/C.
# If invariant, the symmetric-midpoint anchor concern (selection on
# follow-up length) is empirically defused.
#
# Reports per-anchor: n, Δ_DBS, Δ_Never-DBS, diff (DBS - NeverDBS),
#                     Welch CI, TOST P_max, NI conclusion.
# ------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(purrr); library(tibble)
})
source("helpers/pain_helpers.R")
set.seed(20260519)

PRE_WIN <- c(-24, 0)
POST_WIN <- c(6, 18)
TOST_MARGIN <- 1

# ---- Anchor builder C: symmetric midpoint (built from patient-anchor frame) ----
build_symmetric_midpoint <- function() {
  rel_pa <- load_full_ppmi_rel_patient_anchor()
  anchors <- compute_symmetric_midpoint_anchors(rel_pa)
  rebind_time_cols(rel_pa, anchors)
}

cohort_list <- list(
  patient_anchor      = load_full_ppmi_rel_patient_anchor(),
  cohort_median       = load_full_ppmi_rel(),
  symmetric_midpoint  = build_symmetric_midpoint()
)

compute_delta_arm <- function(rel, var = "NP1PAIN", pre = PRE_WIN, post = POST_WIN) {
  pre_d <- rel %>%
    dplyr::filter(months >= pre[1], months <= pre[2],
                  !is.na(.data[[var]])) %>%
    dplyr::group_by(PATNO, will_receive_dbs) %>%
    dplyr::summarise(pre_mean = mean(.data[[var]]), .groups = "drop")
  post_d <- rel %>%
    dplyr::filter(months >= post[1], months <= post[2],
                  !is.na(.data[[var]])) %>%
    dplyr::group_by(PATNO) %>%
    dplyr::summarise(post_mean = mean(.data[[var]]), .groups = "drop")
  dplyr::inner_join(pre_d, post_d, by = "PATNO") %>%
    dplyr::mutate(
      delta = post_mean - pre_mean,
      arm = factor(dplyr::if_else(will_receive_dbs, "DBS", "Never-DBS"),
                   levels = c("Never-DBS", "DBS"))
    )
}

run_anchor <- function(rel, name) {
  d <- compute_delta_arm(rel)
  if (sum(d$arm == "DBS") < 5 || sum(d$arm == "Never-DBS") < 5) {
    return(tibble::tibble(anchor = name, n = nrow(d),
                          msg = "insufficient n in one arm"))
  }
  # Direct subtraction: DBS − Never-DBS
  tt <- stats::t.test(d$delta[d$arm == "DBS"],
                      d$delta[d$arm == "Never-DBS"])
  est <- unname(tt$estimate[1] - tt$estimate[2])
  ci  <- unname(tt$conf.int)

  tt_l <- stats::t.test(d$delta[d$arm == "DBS"] + TOST_MARGIN,
                        d$delta[d$arm == "Never-DBS"],
                        alternative = "greater", var.equal = FALSE)
  tt_u <- stats::t.test(d$delta[d$arm == "DBS"] - TOST_MARGIN,
                        d$delta[d$arm == "Never-DBS"],
                        alternative = "less", var.equal = FALSE)

  tibble::tibble(
    anchor   = name,
    n_dbs    = sum(d$arm == "DBS"),
    n_ctrl   = sum(d$arm == "Never-DBS"),
    delta_dbs = mean(d$delta[d$arm == "DBS"],       na.rm = TRUE),
    delta_ctl = mean(d$delta[d$arm == "Never-DBS"], na.rm = TRUE),
    diff      = est,
    ci_lo     = ci[1], ci_hi = ci[2],
    welch_p   = tt$p.value,
    tost_p_lo = tt_l$p.value, tost_p_hi = tt_u$p.value,
    tost_p_max = max(tt_l$p.value, tt_u$p.value),
    tost_NI   = (tt_l$p.value < 0.05) & (tt_u$p.value < 0.05),
    margin    = TOST_MARGIN
  )
}

res <- purrr::imap_dfr(cohort_list, function(rel, nm) run_anchor(rel, nm))
print(res)
save_table(res, "sprint02_anchor_sensitivity")

# ---- Plot: forest of diff (DBS − Never-DBS) per anchor scheme ----
p <- ggplot(res, aes(x = diff, y = anchor)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey55") +
  geom_vline(xintercept = c(-TOST_MARGIN, TOST_MARGIN),
             linetype = "dotted", colour = unname(OKABE_ITO["vermillion"])) +
  geom_errorbarh(aes(xmin = ci_lo, xmax = ci_hi), height = 0.15,
                 linewidth = 0.9, colour = unname(OKABE_ITO["blue"])) +
  geom_point(size = 3.5, colour = unname(OKABE_ITO["blue"])) +
  geom_text(aes(label = sprintf("Δ %+.2f (%.2f, %.2f) | n=%d/%d | TOST P=%.3f",
                                diff, ci_lo, ci_hi, n_dbs, n_ctrl, tost_p_max)),
            hjust = -0.05, vjust = -1.0, size = 3.1, colour = "grey25") +
  scale_x_continuous("Δ Pain (DBS) − Δ Pain (Never-DBS), MDS-UPDRS I points",
                     limits = c(-1.5, 1.5),
                     breaks = seq(-1.5, 1.5, 0.5)) +
  labs(
    title = "Anchor sensitivity sweep — primary landmark Δ Pain",
    subtitle = sprintf(
      "Three Never-DBS anchor schemes. Dotted lines: ±%g-point TOST margin.",
      TOST_MARGIN),
    y = NULL
  ) +
  theme_pain_pub(base_size = 11)
save_fig_pub(p, "sprint02_anchor_sensitivity", width = 9.5, height = 4)
cat("\n[OK] sprint02_anchor_sensitivity saved.\n")
