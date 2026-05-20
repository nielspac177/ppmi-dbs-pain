#!/usr/bin/env Rscript
# build_delta_matched_6_12mo.R
# ------------------------------------------------------------
# Two-panel Δ Pain figure in the MATCHED cohort at the 6- and
# 12-month landmarks (each ± 6 months). Baseline window fixed
# at [-6, 0]. Bars with 95% CIs, Δ and n per group, Welch t-test
# P per stratum, DBS x baseline-pain interaction P in subtitle.
# ------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(purrr)
  library(tibble); library(patchwork); library(readr)
})
source("helpers/pain_helpers.R")

rel <- load_matched_long()
cat("Matched rows:", nrow(rel), "  Patients:", dplyr::n_distinct(rel$PATNO), "\n")

PRE <- c(-6, 0)
LANDMARKS <- list(
  "6-month landmark"  = c(0,  12),
  "12-month landmark" = c(6,  18)
)

strat <- function(pm) dplyr::case_when(
  pm >= 2 ~ "High (\u2265 2)",
  pm >= 1 ~ "Moderate (1\u2013<2)",
  TRUE    ~ "Low (<1)"
)

compute_delta <- function(post_win) {
  pre <- rel %>% dplyr::filter(months >= PRE[1],  months <= PRE[2],
                               !is.na(NP1PAIN)) %>%
    dplyr::group_by(PATNO, will_receive_dbs) %>%
    dplyr::summarise(pre_mean = mean(NP1PAIN), .groups = "drop")
  post <- rel %>% dplyr::filter(months >= post_win[1], months <= post_win[2],
                                !is.na(NP1PAIN)) %>%
    dplyr::group_by(PATNO) %>%
    dplyr::summarise(post_mean = mean(NP1PAIN), .groups = "drop")
  dplyr::inner_join(pre, post, by = "PATNO") %>%
    dplyr::mutate(
      delta = post_mean - pre_mean,
      pain_stratum = factor(strat(pre_mean),
                            levels = c("Low (<1)",
                                       "Moderate (1\u2013<2)",
                                       "High (\u2265 2)")),
      arm = factor(dplyr::if_else(will_receive_dbs, "DBS", "Never-DBS"),
                   levels = c("DBS", "Never-DBS"))
    )
}

build_panel <- function(post_win, win_name) {
  df <- compute_delta(post_win)

  summ <- df %>%
    dplyr::group_by(pain_stratum, arm, .drop = FALSE) %>%
    dplyr::summarise(
      n          = dplyr::n(),
      mean_delta = mean(delta, na.rm = TRUE),
      se         = stats::sd(delta, na.rm = TRUE) / sqrt(dplyr::n()),
      .groups    = "drop"
    ) %>%
    dplyr::mutate(
      lo = mean_delta - 1.96 * se,
      hi = mean_delta + 1.96 * se,
      lab = ifelse(is.nan(mean_delta),
                   sprintf("n=%d", n),
                   sprintf("\u0394 %+.2f\nn=%d", mean_delta, n))
    )

  p_tbl <- purrr::map_dfr(levels(df$pain_stratum), function(s) {
    sub <- df %>% dplyr::filter(pain_stratum == s)
    n_dbs <- sum(sub$will_receive_dbs); n_ctl <- sum(!sub$will_receive_dbs)
    if (n_dbs < 3 || n_ctl < 3) {
      return(tibble::tibble(pain_stratum = s,
                            p_lab = sprintf("n<3"),
                            n_dbs = n_dbs, n_ctl = n_ctl))
    }
    tt <- stats::t.test(delta ~ will_receive_dbs, data = sub)
    tibble::tibble(pain_stratum = s,
                   p_lab = sprintf("P = %.3f", tt$p.value),
                   n_dbs = n_dbs, n_ctl = n_ctl)
  }) %>%
    dplyr::mutate(pain_stratum = factor(pain_stratum,
                                        levels = levels(df$pain_stratum)))

  int_df <- df %>% dplyr::filter(!is.na(delta)) %>% droplevels()
  p_int <- tryCatch({
    if (dplyr::n_distinct(int_df$arm) >= 2 &&
        dplyr::n_distinct(int_df$pain_stratum) >= 2) {
      stats::anova(stats::lm(delta ~ arm * pain_stratum,
                             data = int_df))["arm:pain_stratum", "Pr(>F)"]
    } else NA_real_
  }, error = function(e) NA_real_)

  yrange <- range(c(summ$lo, summ$hi), na.rm = TRUE)
  yhead  <- yrange[2] + 0.30 * diff(yrange)

  ggplot(summ, aes(pain_stratum, mean_delta, fill = arm)) +
    geom_hline(yintercept = 0, linetype = "dashed", colour = "grey55") +
    geom_col(position = position_dodge(0.8), width = 0.65,
             colour = "white", linewidth = 0.3) +
    geom_errorbar(aes(ymin = lo, ymax = hi),
                  position = position_dodge(0.8), width = 0.18,
                  linewidth = 0.55, colour = "grey20") +
    geom_text(aes(label = lab,
                  y = ifelse(is.na(mean_delta) | mean_delta >= 0,
                             pmax(hi, 0) + 0.03,
                             lo - 0.03)),
              position = position_dodge(0.8),
              vjust = ifelse(is.na(summ$mean_delta) | summ$mean_delta >= 0, 0, 1),
              lineheight = 0.9, size = 3.1, colour = "grey15") +
    geom_text(data = p_tbl,
              aes(x = pain_stratum, y = yhead, label = p_lab),
              inherit.aes = FALSE, size = 3.3,
              colour = "grey30", fontface = "italic") +
    scale_fill_manual(values = c(DBS = "#CC6677",
                                 `Never-DBS` = "#332288"),
                      name = NULL, drop = FALSE) +
    scale_y_continuous("\u0394 Pain (landmark \u2212 baseline)",
                       expand = expansion(mult = c(0.18, 0.28))) +
    labs(
      title    = win_name,
      subtitle = sprintf("DBS \u00d7 baseline-pain interaction P = %.2f",
                         p_int),
      x = NULL
    ) +
    theme_classic(base_size = 11, base_family = "Helvetica") +
    theme(
      plot.title         = element_text(face = "bold", size = 13, hjust = 0.5),
      plot.subtitle      = element_text(colour = "grey35", hjust = 0.5, size = 9),
      axis.text.x        = element_text(size = 10),
      axis.title.y       = element_text(size = 10),
      legend.position    = "none",
      panel.grid.major.y = element_line(colour = "grey92", linewidth = 0.25)
    )
}

panels <- purrr::imap(LANDMARKS, build_panel)

legend_panel <- build_panel(LANDMARKS[[1]], "legend") +
  theme(legend.position = "top",
        legend.text = element_text(size = 11),
        legend.key.size = grid::unit(1, "lines"))
leg <- cowplot::get_legend(legend_panel)

combined <- patchwork::wrap_plots(panels, nrow = 1) +
  patchwork::plot_annotation(
    title    = "\u0394 Pain by baseline-pain stratum \u2014 matched cohort",
    subtitle = sprintf(
      "Baseline: mean Pain in [\u22126, 0] mo. Welch t-test DBS vs. Never-DBS per stratum."
    ),
    theme    = theme(plot.title    = element_text(face = "bold", size = 14, hjust = 0.5),
                     plot.subtitle = element_text(colour = "grey35", hjust = 0.5,
                                                  size = 10))
  )

final <- cowplot::plot_grid(leg, combined, ncol = 1, rel_heights = c(0.05, 1))

out_path <- file.path(OUT_FIG, "Figure_delta_matched_6_12mo.png")
ggsave(out_path, final, width = 12, height = 5.8, dpi = 300)
cat("[OK] saved", out_path, "\n")

summ_all <- purrr::imap_dfr(LANDMARKS, function(post_win, win_name) {
  df <- compute_delta(post_win)
  df %>% dplyr::group_by(pain_stratum, arm) %>%
    dplyr::summarise(n = dplyr::n(),
                     mean_delta = mean(delta, na.rm = TRUE),
                     sd_delta = stats::sd(delta, na.rm = TRUE),
                     .groups = "drop") %>%
    dplyr::mutate(landmark = win_name, .before = 1)
})
readr::write_csv(summ_all, file.path(OUT_TAB, "delta_matched_6_12mo_summary.csv"))
print(summ_all, n = 50)
