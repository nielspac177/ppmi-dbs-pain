#!/usr/bin/env Rscript
# 03_evalue_mnar.R
# ------------------------------------------------------------
# (a) Formatted E-value supplementary table.
# (b) MNAR tipping-point sensitivity for the primary landmark Δ Pain.
#
# (a) Surface the existing E-values (evalue_slope_contrast.csv,
#     evalue_worsener_rr.csv) into a single nicely formatted Supp Table.
#
# (b) Tipping-point MNAR. PPMI dropout is informative: patients who
#     get sicker may drop out more. The IPW weights handle confounding
#     for DBS exposure, not for outcome missingness.
#     We identify the dropouts (have baseline but missing post-window),
#     impute a Δ Pain SHIFTED by k = {0, +0.25, +0.5, +0.75, +1.0} pain
#     points in the arm with more dropouts (Never-DBS by default),
#     and rerun the primary Welch contrast + TOST at ±1. The TOST
#     conclusion stays NI until some k_flip — that k_flip quantifies
#     "how informative would dropout have to be to overturn the
#     non-inferiority conclusion?"
# ------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(purrr); library(tibble); library(readr)
})
source("helpers/pain_helpers.R")
set.seed(20260519)

PRE_WIN <- c(-24, 0)
POST_WIN <- c(6, 18)
TOST_MARGIN <- 1

# =========================================================
# Part (a) — formatted E-value table
# =========================================================
ev_slope <- readr::read_csv("outputs/tables/evalue_slope_contrast.csv",
                            show_col_types = FALSE)
ev_worse <- readr::read_csv("outputs/tables/evalue_worsener_rr.csv",
                            show_col_types = FALSE)

ev_tbl <- tibble::tibble(
  contrast    = c("LMM Δ slope (Post-DBS vs Never-DBS)",
                  "Worsener risk (NP1PAIN ≥ 2 in [+6, +18] mo)"),
  estimate    = c(ev_slope$point[1], ev_worse$point[1]),
  estimate_lo = c(ev_slope$lower[1], ev_worse$lower[1]),
  estimate_hi = c(ev_slope$upper[1], ev_worse$upper[1]),
  evalue      = c(ev_slope$point[2], ev_worse$point[2]),
  evalue_lower_ci = c(ev_slope$upper[2], ev_worse$upper[2]),
  interpretation = c(
    paste0("An unmeasured confounder would need to be associated with ",
           "both DBS receipt and Δ Pain slope by an OR/RR of ",
           sprintf("%.2f", ev_slope$point[2]),
           " (lower CI ",
           sprintf("%.2f", ev_slope$upper[2]),
           ") to explain the (null) point estimate."),
    paste0("An unmeasured confounder would need to be associated with ",
           "both DBS receipt and 12-month worsening (NP1PAIN ≥ 2) by an RR of ",
           sprintf("%.2f", ev_worse$point[2]),
           " (lower CI ",
           sprintf("%.2f", ev_worse$upper[2]),
           ") to fully explain the observed association.")
  )
)
print(ev_tbl)
save_table(03$NAME, "03_evalue_table_E1")

# =========================================================
# Part (b) — MNAR tipping-point sensitivity
# =========================================================
rel <- load_full_ppmi_rel_patient_anchor()

# Step 1. Identify analysable cohort by baseline-window observation.
baseline_set <- rel %>%
  dplyr::filter(months >= PRE_WIN[1], months <= PRE_WIN[2],
                !is.na(NP1PAIN)) %>%
  dplyr::group_by(PATNO, will_receive_dbs) %>%
  dplyr::summarise(pre_mean = mean(NP1PAIN), .groups = "drop")

post_obs <- rel %>%
  dplyr::filter(months >= POST_WIN[1], months <= POST_WIN[2],
                !is.na(NP1PAIN)) %>%
  dplyr::group_by(PATNO) %>%
  dplyr::summarise(post_mean = mean(NP1PAIN), .groups = "drop")

joined <- baseline_set %>% dplyr::left_join(post_obs, by = "PATNO") %>%
  dplyr::mutate(
    arm = factor(dplyr::if_else(will_receive_dbs, "DBS", "Never-DBS"),
                 levels = c("Never-DBS", "DBS")),
    has_post = !is.na(post_mean),
    delta_obs = post_mean - pre_mean
  )

# Dropout rates per arm
drop_tbl <- joined %>%
  dplyr::group_by(arm) %>%
  dplyr::summarise(n = dplyr::n(),
                   n_observed = sum(has_post),
                   n_dropout  = sum(!has_post),
                   dropout_rate = mean(!has_post),
                   .groups = "drop")
print(drop_tbl)
save_table(03$NAME, "03_dropout_by_arm")

# Step 2. Tipping-point. For each shift k, impute Δ for dropouts.
# Imputation: completers' mean Δ in that arm + k. Apply k to the arm
# with more dropouts (we apply +k to Never-DBS dropouts and -k to DBS
# dropouts as the conservative "DBS-favouring" direction; also report
# the symmetric opposite).
run_tipping <- function(k, favor_dbs = TRUE) {
  imp <- joined %>%
    dplyr::mutate(
      delta_imp = dplyr::case_when(
        has_post ~ delta_obs,
        !has_post & arm == "Never-DBS" ~ {
          mu <- mean(joined$delta_obs[joined$arm == "Never-DBS"], na.rm = TRUE)
          if (favor_dbs) mu + k else mu - k
        },
        !has_post & arm == "DBS" ~ {
          mu <- mean(joined$delta_obs[joined$arm == "DBS"], na.rm = TRUE)
          if (favor_dbs) mu - k else mu + k
        }
      )
    )
  tt <- stats::t.test(imp$delta_imp[imp$arm == "DBS"],
                      imp$delta_imp[imp$arm == "Never-DBS"])
  diff <- unname(tt$estimate[1] - tt$estimate[2])
  ci <- unname(tt$conf.int)
  tt_l <- stats::t.test(imp$delta_imp[imp$arm == "DBS"] + TOST_MARGIN,
                        imp$delta_imp[imp$arm == "Never-DBS"],
                        alternative = "greater", var.equal = FALSE)
  tt_u <- stats::t.test(imp$delta_imp[imp$arm == "DBS"] - TOST_MARGIN,
                        imp$delta_imp[imp$arm == "Never-DBS"],
                        alternative = "less", var.equal = FALSE)
  tibble::tibble(
    k = k, direction = if (favor_dbs) "DBS-favouring" else "Anti-DBS",
    diff = diff, ci_lo = ci[1], ci_hi = ci[2],
    welch_p = tt$p.value,
    tost_p_max = max(tt_l$p.value, tt_u$p.value),
    tost_NI = (tt_l$p.value < 0.05) && (tt_u$p.value < 0.05)
  )
}

k_grid <- seq(0, 1.5, by = 0.25)
mnar_tbl <- dplyr::bind_rows(
  purrr::map_dfr(k_grid, run_tipping, favor_dbs = TRUE),
  purrr::map_dfr(k_grid, run_tipping, favor_dbs = FALSE)
)
print(mnar_tbl)
save_table(03$NAME, "03_mnar_tipping")

# Plot: diff +/- 95% CI as function of k, in both directions
p <- ggplot(mnar_tbl, aes(x = k, y = diff,
                          colour = direction, group = direction)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey55") +
  geom_hline(yintercept = c(-TOST_MARGIN, TOST_MARGIN),
             linetype = "dotted", colour = unname(OKABE_ITO["vermillion"])) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi, fill = direction),
              alpha = 0.18, colour = NA) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.4) +
  scale_colour_manual(values = c("DBS-favouring" = unname(OKABE_ITO["blue"]),
                                 "Anti-DBS"      = unname(OKABE_ITO["vermillion"]))) +
  scale_fill_manual(values = c("DBS-favouring" = unname(OKABE_ITO["blue"]),
                               "Anti-DBS"      = unname(OKABE_ITO["vermillion"])),
                    guide = "none") +
  scale_x_continuous("MNAR shift k (pain points applied to dropouts)",
                     breaks = k_grid) +
  scale_y_continuous("Δ (DBS) − Δ (Never-DBS), MDS-UPDRS I points",
                     limits = c(-1.5, 1.5),
                     breaks = seq(-1.5, 1.5, 0.5)) +
  labs(
    title = "MNAR tipping-point sensitivity (primary landmark Δ Pain)",
    subtitle = sprintf(
      "Direction = which arm's dropouts get shifted. Dotted lines: ±%g-point TOST margin.",
      TOST_MARGIN),
    colour = NULL
  ) +
  theme_pain_pub(base_size = 11)
save_fig_pub(03$NAME, "03_mnar_tipping", width = 9, height = 5)

cat("\n[OK] 03 outputs saved.\n")

# Report the smallest k at which TOST_NI flips to FALSE in each direction
flip_pts <- mnar_tbl %>% dplyr::filter(!tost_NI) %>%
  dplyr::group_by(direction) %>% dplyr::summarise(k_flip = min(k))
cat("Tipping-point k where TOST_NI flips:\n"); print(flip_pts)
