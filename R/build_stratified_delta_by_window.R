#!/usr/bin/env Rscript
# build_stratified_delta_by_window.R
# ------------------------------------------------------------
# Stratified Delta-Pain by baseline-pain level, for multiple
# post-DBS windows. Answers "where does the DBS benefit show up"
# by computing Delta = post_mean - pre_mean for post windows:
#   [0, 6], [6, 12], [6, 18]  (current Fig 8), [12, 24], [24, 48]
# Pre window fixed at [-24, 0] (to keep baseline comparable).
# ------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(patchwork); library(purrr)
})
source("helpers/pain_helpers.R")

rel <- load_full_ppmi_rel_patient_anchor()
cat("Rows:", nrow(rel), "  Patients:", dplyr::n_distinct(rel$PATNO), "\n")

# Strata labels
strat <- function(pm) dplyr::case_when(
  pm >= 2 ~ "High (\u2265 2)",
  pm >= 1 ~ "Moderate (1\u2013<2)",
  TRUE    ~ "Low (<1)"
)

# Fixed pre window
PRE <- c(-24, 0)

# Post windows to test (months)
WINDOWS <- list(
  "Very short-term\n[0-6 mo]"  = c(0, 6),
  "Short-term\n[6-12 mo]"      = c(6, 12),
  "Short-term\n[6-18 mo]"      = c(6, 18),
  "Medium\n[12-24 mo]"         = c(12, 24),
  "Long-term\n[24-48 mo]"      = c(24, 48)
)

compute_delta <- function(pre_win, post_win) {
  pre <- rel %>% dplyr::filter(months >= pre_win[1],  months <= pre_win[2],
                               !is.na(NP1PAIN)) %>%
    dplyr::group_by(PATNO, will_receive_dbs) %>%
    dplyr::summarise(pre_mean = mean(NP1PAIN), n_pre = dplyr::n(), .groups = "drop")
  post <- rel %>% dplyr::filter(months >= post_win[1], months <= post_win[2],
                                !is.na(NP1PAIN)) %>%
    dplyr::group_by(PATNO) %>%
    dplyr::summarise(post_mean = mean(NP1PAIN), n_post = dplyr::n(), .groups = "drop")
  dplyr::inner_join(pre, post, by = "PATNO") %>%
    dplyr::mutate(delta = post_mean - pre_mean,
                  pain_stratum = factor(strat(pre_mean),
                                        levels = c("Low (<1)","Moderate (1\u2013<2)","High (\u2265 2)")),
                  arm = dplyr::if_else(will_receive_dbs, "DBS", "Never-DBS"))
}

build_panel <- function(win_name, post_win) {
  df <- compute_delta(PRE, post_win)
  n_dbs <- sum(df$will_receive_dbs)
  summ <- df %>% dplyr::group_by(pain_stratum, arm) %>%
    dplyr::summarise(n = dplyr::n(),
                     mean_delta = mean(delta, na.rm = TRUE),
                     se = stats::sd(delta, na.rm = TRUE) / sqrt(dplyr::n()),
                     .groups = "drop") %>%
    dplyr::mutate(lo = mean_delta - 1.96 * se,
                  hi = mean_delta + 1.96 * se)

  # Welch test per stratum
  p_tbl <- purrr::map_dfr(levels(df$pain_stratum), function(s) {
    sub <- df %>% dplyr::filter(pain_stratum == s)
    if (sum(sub$will_receive_dbs) < 5 || sum(!sub$will_receive_dbs) < 5)
      return(tibble::tibble(pain_stratum = s, p_lab = ""))
    tt <- stats::t.test(delta ~ will_receive_dbs, data = sub)
    tibble::tibble(pain_stratum = s,
                   p_lab = sprintf("p=%.2f", tt$p.value))
  }) %>%
    dplyr::mutate(pain_stratum = factor(pain_stratum, levels = levels(df$pain_stratum)))

  yrange <- range(c(summ$lo, summ$hi), na.rm = TRUE)
  yhead  <- yrange[2] + 0.25 * diff(yrange)
  summ <- summ %>% dplyr::mutate(lab = sprintf("\u0394 %+.2f\nn=%d", mean_delta, n))

  ggplot(summ, aes(pain_stratum, mean_delta, fill = arm)) +
    geom_hline(yintercept = 0, linetype = "dashed", colour = "grey55") +
    geom_col(position = position_dodge(0.9), width = 0.6,
             colour = "white", linewidth = 0.3) +
    geom_errorbar(aes(ymin = lo, ymax = hi),
                  position = position_dodge(0.9), width = 0.12,
                  linewidth = 0.5, colour = "grey20") +
    geom_text(aes(label = lab,
                  y = ifelse(mean_delta >= 0, hi + 0.04, lo - 0.04)),
              position = position_dodge(0.9),
              vjust = ifelse(summ$mean_delta >= 0, 0, 1),
              lineheight = 0.9, size = 2.5, colour = "grey15") +
    geom_text(data = p_tbl,
              aes(x = pain_stratum, y = yhead, label = p_lab),
              inherit.aes = FALSE, size = 2.7,
              colour = "grey35", fontface = "italic") +
    scale_fill_manual(values = c(`DBS` = "#CC6677", `Never-DBS` = "#332288"),
                      name = NULL, guide = guide_legend(nrow = 1)) +
    scale_y_continuous("\u0394 Pain (post \u2212 pre)",
                       expand = expansion(mult = c(0.15, 0.25))) +
    labs(title = win_name, x = NULL) +
    theme_classic(base_size = 10, base_family = "Helvetica") +
    theme(plot.title     = element_text(face = "bold", size = 10,
                                        hjust = 0.5, lineheight = 1),
          legend.position = "none",
          axis.text.x    = element_text(size = 8),
          axis.title.y   = element_text(size = 9),
          panel.grid.major.y = element_line(colour = "grey92",
                                            linewidth = 0.25))
}

panels <- purrr::imap(WINDOWS, build_panel)

# Extract legend from one panel and place at top
legend_panel <- build_panel("x", WINDOWS[[1]]) +
  theme(legend.position = "top", legend.key.size = grid::unit(0.9, "lines"))
leg <- cowplot::get_legend(legend_panel)

combined <- patchwork::wrap_plots(panels, nrow = 1) +
  patchwork::plot_annotation(
    title    = "\u0394 Pain by baseline-pain stratum across post-DBS windows",
    subtitle = "Pre-window fixed at [-24, 0] months. Welch t-tests within each stratum, DBS vs. Never-DBS.",
    theme    = theme(plot.title = element_text(face = "bold", size = 13),
                     plot.subtitle = element_text(colour = "grey35"))
  )

# Save legend above combined plot
final <- cowplot::plot_grid(leg, combined, ncol = 1, rel_heights = c(0.04, 1))

ggsave(file.path(OUT_FIG, "Figure8_stratified_delta_by_window.png"),
       final, width = 15, height = 5.8, dpi = 300)
cat("[OK] Figure8_stratified_delta_by_window saved\n")

# Save summary CSV across all windows
all_summ <- purrr::imap_dfr(WINDOWS, function(post_win, win_name) {
  df <- compute_delta(PRE, post_win)
  df %>% dplyr::group_by(pain_stratum, arm) %>%
    dplyr::summarise(n = dplyr::n(),
                     mean_delta = mean(delta, na.rm = TRUE),
                     sd_delta   = stats::sd(delta, na.rm = TRUE),
                     .groups = "drop") %>%
    dplyr::mutate(window = win_name, .before = 1)
})
readr::write_csv(all_summ, file.path(OUT_TAB, "delta_stratified_all_windows.csv"))

all_tests <- purrr::imap_dfr(WINDOWS, function(post_win, win_name) {
  df <- compute_delta(PRE, post_win)
  purrr::map_dfr(levels(df$pain_stratum), function(s) {
    sub <- df %>% dplyr::filter(pain_stratum == s)
    n_dbs <- sum(sub$will_receive_dbs); n_ctl <- sum(!sub$will_receive_dbs)
    if (n_dbs < 5 || n_ctl < 5)
      return(tibble::tibble(window = win_name, pain_stratum = s,
                            n_dbs = n_dbs, n_ctl = n_ctl,
                            delta_dbs = NA, delta_ctl = NA,
                            diff = NA, lower = NA, upper = NA, p = NA))
    tt <- stats::t.test(delta ~ will_receive_dbs, data = sub)
    mean_dbs <- mean(sub$delta[sub$will_receive_dbs], na.rm = TRUE)
    mean_ctl <- mean(sub$delta[!sub$will_receive_dbs], na.rm = TRUE)
    tibble::tibble(window = win_name, pain_stratum = s,
                   n_dbs = n_dbs, n_ctl = n_ctl,
                   delta_dbs = mean_dbs, delta_ctl = mean_ctl,
                   diff = mean_dbs - mean_ctl,
                   lower = tt$conf.int[1], upper = tt$conf.int[2],
                   p = tt$p.value)
  })
})
readr::write_csv(all_tests, file.path(OUT_TAB, "delta_stratified_welch_all_windows.csv"))
cat("[OK] tables saved\n")
print(all_tests, n = 100)
