#!/usr/bin/env Rscript
# build_original_figures_hires.R
# ---------------------------------------------------------------
# Re-render the four Word-doc-embedded figures (Fig 3 pain
# distribution, Fig 4A/B DEC/FLAT/INC spaghetti, Fig 5 mean
# trajectory) at 300 DPI from the underlying PPMI data.
#
# Outputs (suffix _hires.png):
#   Fig3_pain_distribution_hires.png
#   Fig4A_spaghetti_DBS_dec_flat_inc_hires.png
#   Fig4B_spaghetti_NeverDBS_dec_flat_inc_hires.png
#   Fig5_mean_trajectory_hires.png
# ---------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(scales); library(forcats)
})
source("helpers/pain_helpers.R")

OUT_HIRES <- file.path(OUT_FIG, "hires")
dir.create(OUT_HIRES, showWarnings = FALSE, recursive = TRUE)

# NOTE: Use the SHARED (median-DBS-date) anchor for controls so visits
# spread across bins rather than collapsing all control first-visits
# onto month 0. This matches the distribution seen in the original Word
# Fig 3/4/5, where n at each bin is ~80-140 (not ~1400 at month 0).
rel <- load_full_ppmi_rel()
cat("Rows:", nrow(rel), "  Patients:", dplyr::n_distinct(rel$PATNO), "\n")

# Common x-axis breaks (original uses 6-month centres from -54..60).
MO_BREAKS <- seq(-54, 60, by = 6)

# Round-to-nearest-6 binning with a 2-month half-window. A visit counts
# toward bin m only if time_months is within [m-2, m+2]. This avoids
# every baseline visit collapsing onto month 0 (which happens with the
# floor-based `months` column in pain_helpers.R).
rel <- rel %>%
  dplyr::mutate(
    month_bin = round(time_months / 6) * 6
  ) %>%
  dplyr::filter(abs(time_months - month_bin) <= 2,
                month_bin %in% MO_BREAKS)

# ---------- Figure 3: Pain-level distribution over time ----------
# Dedupe to one observation per patient per 6-month bin so n= reflects
# unique patients, not raw visits.
rel_bin1 <- rel %>%
  dplyr::filter(!is.na(NP1PAIN)) %>%
  dplyr::arrange(PATNO, month_bin, abs(time_months - month_bin)) %>%
  dplyr::group_by(PATNO, month_bin) %>%
  dplyr::slice_head(n = 1) %>%
  dplyr::ungroup()

fig3 <- rel_bin1 %>%
  dplyr::mutate(level = factor(NP1PAIN,
                               levels = 0:4,
                               labels = names(PAIN_LEVEL_COLORS))) %>%
  dplyr::group_by(month_bin, level, .drop = FALSE) %>%
  dplyr::summarise(n = dplyr::n(), .groups = "drop_last") %>%
  dplyr::mutate(total = sum(n), prop = n / total) %>%
  dplyr::ungroup() %>%
  dplyr::filter(total >= 20)

n_labs <- fig3 %>% dplyr::distinct(month_bin, total)

p3 <- ggplot(fig3, aes(month_bin, prop, fill = level)) +
  geom_col(width = 5, colour = "white", linewidth = 0.15) +
  geom_text(data = dplyr::filter(fig3, prop >= 0.05),
            aes(label = scales::percent(prop, accuracy = 1)),
            position = position_stack(vjust = 0.5),
            size = 2.8, colour = "grey20") +
  geom_text(data = n_labs,
            aes(x = month_bin, y = 1.02, label = paste0("n=", total)),
            inherit.aes = FALSE, size = 2.6, colour = "grey25", vjust = 0) +
  scale_fill_manual(values = PAIN_LEVEL_COLORS, name = "Pain level") +
  scale_x_continuous(breaks = MO_BREAKS, expand = expansion(add = c(2, 2))) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1),
                     expand = expansion(mult = c(0, 0.08)),
                     limits = c(0, 1.06)) +
  labs(title = "Distribution of Pain Levels Over Time",
       x = "Months", y = "Proportion") +
  theme_classic(base_size = 11, base_family = "Helvetica") +
  theme(plot.title = element_text(face = "bold", hjust = 0.5, size = 13),
        axis.text.x = element_text(size = 9),
        legend.position = "right")

ggsave(file.path(OUT_HIRES, "Fig3_pain_distribution_hires.png"),
       p3, width = 10, height = 6, dpi = 300)
cat("[OK] Fig3\n")

# ---------- Figure 4: DEC/FLAT/INC spaghetti ----------
# Original caption: "patients starting at 2, 3, or 4" -> first score >= 2.
sp_all <- rel %>%
  dplyr::filter(!is.na(NP1PAIN), month_bin >= -54, month_bin <= 36) %>%
  dplyr::arrange(PATNO, time_months)

first_last <- sp_all %>%
  dplyr::group_by(PATNO, will_receive_dbs) %>%
  dplyr::summarise(
    # first score = first visit where pain crossed >= 2; last = overall last
    first_score = {
      idx <- which(NP1PAIN >= 2)
      if (length(idx) == 0) NA_real_ else NP1PAIN[idx[which.min(time_months[idx])]]
    },
    first_time  = {
      idx <- which(NP1PAIN >= 2)
      if (length(idx) == 0) NA_real_ else time_months[idx[which.min(time_months[idx])]]
    },
    last_score  = NP1PAIN[which.max(time_months)],
    last_time   = max(time_months),
    .groups = "drop"
  ) %>%
  dplyr::filter(!is.na(first_score), last_time > first_time) %>%
  dplyr::mutate(
    category = dplyr::case_when(
      last_score <  first_score ~ "Decreasing",
      last_score == first_score ~ "Flat",
      last_score >  first_score ~ "Increasing"
    ),
    category = factor(category, levels = c("Decreasing", "Flat", "Increasing"))
  )

sp <- sp_all %>% dplyr::inner_join(first_last, by = c("PATNO", "will_receive_dbs"))

CAT_COLS <- c(Decreasing = "#4FA08C", Flat = "#9A9A9A", Increasing = "#E08640")

make_fig4 <- function(arm_flag, arm_title) {
  d <- sp %>% dplyr::filter(will_receive_dbs == arm_flag,
                            first_score %in% 2:4)
  # percentages for facet labels
  pats <- d %>% dplyr::distinct(PATNO, category)
  pct <- pats %>% dplyr::count(category, .drop = FALSE) %>%
    dplyr::mutate(pct = round(100 * n / sum(n))) %>%
    dplyr::mutate(lab = sprintf("%s (%d%%)", category, pct))
  lab_map <- setNames(pct$lab, as.character(pct$category))

  d <- d %>% dplyr::mutate(cat_lab = factor(lab_map[as.character(category)],
                                            levels = lab_map))

  ggplot(d, aes(month_bin, NP1PAIN, colour = category, group = PATNO)) +
    annotate("rect", xmin = -6, xmax = 0, ymin = -Inf, ymax = Inf,
             fill = "grey80", alpha = 0.35) +
    geom_vline(xintercept = 0, linetype = "dashed", colour = "grey50") +
    geom_line(linewidth = 0.45, alpha = 0.8) +
    geom_point(size = 1.1, alpha = 0.9) +
    scale_colour_manual(values = CAT_COLS, name = NULL) +
    scale_x_continuous(breaks = seq(-54, 36, by = 6),
                       limits = c(-55, 37), expand = c(0, 0)) +
    scale_y_continuous(breaks = 0:4, limits = c(-0.2, 4.2)) +
    facet_grid(first_score ~ cat_lab) +
    labs(title = arm_title, x = "Months", y = "UPDRS-I Pain score") +
    theme_bw(base_size = 11, base_family = "Helvetica") +
    theme(
      plot.title = element_text(face = "bold", hjust = 0.5, size = 13),
      strip.background.x = element_rect(fill = "white", colour = "grey30"),
      strip.background.y = element_blank(),
      strip.text.x = element_text(face = "bold", size = 10),
      strip.text.y = element_blank(),
      axis.text.x = element_text(size = 7),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(colour = "grey93", linewidth = 0.25),
      legend.position = "right"
    )
}

p4a <- make_fig4(TRUE,  "Pain trajectories with DBS")
p4b <- make_fig4(FALSE, "Pain trajectories of Patients that never receive DBS")

ggsave(file.path(OUT_HIRES, "Fig4A_spaghetti_DBS_dec_flat_inc_hires.png"),
       p4a, width = 10, height = 6, dpi = 300)
ggsave(file.path(OUT_HIRES, "Fig4B_spaghetti_NeverDBS_dec_flat_inc_hires.png"),
       p4b, width = 10, height = 6, dpi = 300)
cat("[OK] Fig4A / Fig4B\n")

# ---------- Figure 5: Mean trajectory ± 95% CI by arm ----------
# Dedupe to one observation per patient per bin (same logic as Fig 3).
fig5 <- rel_bin1 %>%
  dplyr::mutate(Group = dplyr::if_else(will_receive_dbs, "DBS", "Never DBS")) %>%
  dplyr::group_by(Group, month_bin) %>%
  dplyr::summarise(
    mean = mean(NP1PAIN),
    se   = stats::sd(NP1PAIN) / sqrt(dplyr::n()),
    n    = dplyr::n(),
    .groups = "drop"
  ) %>%
  dplyr::filter(n >= 5) %>%
  dplyr::mutate(lo = mean - 1.96 * se, hi = mean + 1.96 * se,
                Group = factor(Group, levels = c("Never DBS", "DBS")))

GROUP_COLS <- c("Never DBS" = "#6F68B3", "DBS" = "#D87A2E")

p5 <- ggplot(fig5, aes(month_bin, mean, colour = Group, group = Group)) +
  annotate("rect", xmin = -6, xmax = 0, ymin = -Inf, ymax = Inf,
           fill = "grey80", alpha = 0.35) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey50") +
  geom_errorbar(aes(ymin = lo, ymax = hi),
                width = 1.8, linewidth = 0.5, alpha = 0.8) +
  geom_line(linewidth = 0.7) +
  geom_point(size = 2.2) +
  scale_colour_manual(values = GROUP_COLS, name = "Group") +
  scale_x_continuous(breaks = MO_BREAKS, expand = expansion(add = c(2, 2))) +
  scale_y_continuous(limits = c(0, 3.1), breaks = 0:3) +
  labs(title = "UPDRS-I Pain Score \u2013 Mean \u00b1 95% CI",
       x = "Months", y = "Pain score") +
  theme_classic(base_size = 11, base_family = "Helvetica") +
  theme(plot.title = element_text(face = "bold", hjust = 0.5, size = 13),
        axis.text.x = element_text(size = 9),
        legend.position = "right")

ggsave(file.path(OUT_HIRES, "Fig5_mean_trajectory_hires.png"),
       p5, width = 10, height = 6, dpi = 300)
cat("[OK] Fig5\n")

# ---- Sanity print: compare counts vs originals ------------------
cat("\n--- Sanity check counts ---\n")
cat("First-score>=2 patients: ", nrow(first_last),
    "  DBS:", sum(first_last$will_receive_dbs),
    "  Never-DBS:", sum(!first_last$will_receive_dbs), "\n")
cat("\nDBS category split:\n")
print(first_last %>% dplyr::filter(will_receive_dbs) %>%
        dplyr::count(category) %>%
        dplyr::mutate(pct = round(100 * n / sum(n))))
cat("\nNever-DBS category split:\n")
print(first_last %>% dplyr::filter(!will_receive_dbs) %>%
        dplyr::count(category) %>%
        dplyr::mutate(pct = round(100 * n / sum(n))))

cat("\n[DONE] hires figures in", OUT_HIRES, "\n")
