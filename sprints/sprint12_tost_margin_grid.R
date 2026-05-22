#!/usr/bin/env Rscript
# sprint12_tost_margin_grid.R
# ------------------------------------------------------------
# Reviewer comment #3 (peer review 2026-05-21): the ±1-point TOST
# margin on a 0–4 ordinal scale is a full clinical-category shift —
# too wide to be discriminating. Run the primary TOST across a margin
# grid (±0.3, 0.5, 0.75, 1.0) and report whether non-inferiority
# survives the tighter margin.
#
# A pre-specified primary at ±1 remains the headline; this sprint
# provides the sensitivity grid for the supplement.
# ------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(purrr); library(tibble)
  library(here); library(yaml)
})
here::i_am("sprints/sprint12_tost_margin_grid.R")
source(here::here("R/helpers/pain_helpers.R"))
set.seed(20260519)

PRE_WIN  <- c(-24, 0)
POST_WIN <- c(6, 18)
MARGINS  <- c(0.30, 0.50, 0.75, 1.00)

rel <- load_full_ppmi_rel_patient_anchor()
cat("Full cohort rows:", nrow(rel), "patients:", dplyr::n_distinct(rel$PATNO), "\n")

# Per-patient Δ
pre <- rel %>%
  dplyr::filter(months >= PRE_WIN[1], months <= PRE_WIN[2],
                !is.na(NP1PAIN)) %>%
  dplyr::group_by(PATNO, will_receive_dbs) %>%
  dplyr::summarise(pre_mean = mean(NP1PAIN), .groups = "drop")
post <- rel %>%
  dplyr::filter(months >= POST_WIN[1], months <= POST_WIN[2],
                !is.na(NP1PAIN)) %>%
  dplyr::group_by(PATNO) %>%
  dplyr::summarise(post_mean = mean(NP1PAIN), .groups = "drop")

d <- dplyr::inner_join(pre, post, by = "PATNO") %>%
  dplyr::mutate(
    delta = post_mean - pre_mean,
    arm = factor(dplyr::if_else(will_receive_dbs, "DBS", "Never-DBS"),
                 levels = c("Never-DBS", "DBS"))
  )

tt <- stats::t.test(d$delta[d$arm == "DBS"],
                    d$delta[d$arm == "Never-DBS"])
est <- unname(tt$estimate[1] - tt$estimate[2])
ci  <- unname(tt$conf.int)
cat(sprintf("Primary Δ (DBS − Never-DBS) = %.3f (95%% CI %.3f, %.3f)\n",
            est, ci[1], ci[2]))

# Run TOST at each margin
grid <- purrr::map_dfr(MARGINS, function(m) {
  tt_l <- stats::t.test(d$delta[d$arm == "DBS"] + m,
                        d$delta[d$arm == "Never-DBS"],
                        alternative = "greater", var.equal = FALSE)
  tt_u <- stats::t.test(d$delta[d$arm == "DBS"] - m,
                        d$delta[d$arm == "Never-DBS"],
                        alternative = "less", var.equal = FALSE)
  tibble::tibble(
    margin = m,
    diff = est,
    ci_lo = ci[1], ci_hi = ci[2],
    tost_p_lower = tt_l$p.value,
    tost_p_upper = tt_u$p.value,
    tost_p_max = max(tt_l$p.value, tt_u$p.value),
    tost_NI = (tt_l$p.value < 0.05) && (tt_u$p.value < 0.05)
  )
})
print(grid)
save_table(grid, "sprint12_tost_margin_grid")

# Find smallest margin at which NI still holds
flips <- grid %>% dplyr::filter(!tost_NI)
if (nrow(flips) == 0) {
  cat("\nNon-inferiority holds at ALL tested margins (down to ±",
      min(MARGINS), ").\n", sep = "")
} else {
  cat("\nNon-inferiority fails at margins:",
      paste(flips$margin, collapse = ", "),
      "\n  Smallest margin at which NI still holds:",
      min(grid$margin[grid$tost_NI]), "\n")
}

# Plot
p <- ggplot(grid, aes(x = margin, y = tost_p_max)) +
  geom_hline(yintercept = 0.05, linetype = "dashed", colour = "grey55") +
  geom_line(linewidth = 1.0, colour = unname(OKABE_ITO["blue"])) +
  geom_point(aes(colour = tost_NI), size = 3.5) +
  scale_colour_manual(values = c(`TRUE` = unname(OKABE_ITO["green"]),
                                 `FALSE` = unname(OKABE_ITO["vermillion"])),
                      labels = c(`TRUE` = "NI concluded",
                                 `FALSE` = "NI fails"),
                      name = NULL) +
  scale_y_log10("TOST P_max (log scale)") +
  scale_x_continuous("Non-inferiority margin (MDS-UPDRS Part I points)",
                     breaks = MARGINS) +
  labs(title = "TOST margin sensitivity — primary Δ Pain contrast",
       subtitle = sprintf(
         "Observed Δ = %+.3f (95%% CI %.3f, %.3f). Dashed: α = 0.05.",
         est, ci[1], ci[2])) +
  theme_pain_pub(base_size = 11)
save_fig_pub(p, "sprint12_tost_margin_grid", width = 8, height = 4.5)
cat("\n[OK] sprint12 outputs saved.\n")
