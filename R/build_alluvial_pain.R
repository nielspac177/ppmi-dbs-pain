#!/usr/bin/env Rscript
# build_alluvial_pain.R
# ------------------------------------------------------------
# Alluvial plot of NP1PAIN ordinal score (0 None -> 4 Very severe)
# across 6-month bins, split by arm.
#
# Full cohort, patient-specific anchor:
#   DBS      -> anchor at first dbs_date   (-m pre-DBS, +m post-DBS)
#   Never-DBS -> anchor at patient's own first visit
#
# Saves four figures:
#   Figure_Alluvial_NP1PAIN_abs_6mo.png    (counts,    6-mo bins)
#   Figure_Alluvial_NP1PAIN_pct_6mo.png    (proportion, 6-mo bins)
#   Figure_Alluvial_NP1PAIN_abs_12mo.png   (counts,    yearly)
#   Figure_Alluvial_NP1PAIN_pct_12mo.png   (proportion, yearly)
# ------------------------------------------------------------

suppressPackageStartupMessages({
  source("helpers/pain_helpers.R")
  library(ggalluvial); library(patchwork); library(scales)
})

# Anchors:
#   DBS       -> first dbs_date (surgery, a real clinical event)
#   Never-DBS -> midpoint of each patient's own follow-up window
#                (first visit ↔ last visit). Not a clinical event — a
#                geometric device so every control has symmetric negative
#                and positive bins. Controls with shorter follow-up only
#                reach the inner bins.
full <- load_full_cohort()

dbs_anchors <- full %>%
  dplyr::filter(will_receive_dbs, !is.na(dbs_date)) %>%
  dplyr::group_by(PATNO) %>%
  dplyr::summarise(anchor_date = min(dbs_date, na.rm = TRUE), .groups = "drop")

ctl_anchors <- full %>%
  dplyr::filter(!will_receive_dbs, !is.na(INFODT_orig)) %>%
  dplyr::group_by(PATNO) %>%
  dplyr::summarise(
    first_visit = min(INFODT_orig, na.rm = TRUE),
    last_visit  = max(INFODT_orig, na.rm = TRUE),
    anchor_date = first_visit + as.numeric(difftime(last_visit, first_visit, units = "days")) / 2,
    .groups = "drop"
  ) %>%
  dplyr::select(PATNO, anchor_date)

anchors <- dplyr::bind_rows(dbs_anchors, ctl_anchors)

rel <- full %>%
  dplyr::left_join(anchors, by = "PATNO") %>%
  dplyr::filter(!is.na(anchor_date)) %>%
  dplyr::mutate(
    time_days   = as.numeric(difftime(INFODT_orig, anchor_date, units = "days")),
    time_months = time_days / DAYS_PER_MONTH,
    time_bin    = floor(time_days / 180),
    months      = time_bin * 6
  ) %>%
  dplyr::filter(is.finite(time_bin))

rel_dedup <- rel %>%
  dplyr::filter(!is.na(NP1PAIN), is.finite(time_bin)) %>%
  dedup_earliest_per_bin() %>%
  dplyr::select(PATNO, will_receive_dbs, months, NP1PAIN)

PAIN_LABS <- c("0 None","1 Mild","2 Moderate","3 Severe","4 Very severe")

# ------------------------------------------------------------
# Patient x bin grid with LOCF + NOCB for continuity.
# ------------------------------------------------------------
build_grid <- function(bin_range) {
  step <- min(diff(bin_range)); half <- step / 2
  per_bin <- purrr::map_dfr(bin_range, function(b) {
    rel_dedup %>%
      dplyr::filter(months >= b - half, months < b + half) %>%
      dplyr::arrange(PATNO, months) %>%
      dplyr::group_by(PATNO) %>%
      dplyr::slice(1) %>%
      dplyr::ungroup() %>%
      dplyr::transmute(PATNO, will_receive_dbs, bin = b, NP1PAIN)
  })
  keep <- per_bin %>% dplyr::distinct(PATNO) %>% dplyr::pull(PATNO)
  arms <- per_bin %>% dplyr::distinct(PATNO, will_receive_dbs)
  tidyr::expand_grid(PATNO = keep, bin = bin_range) %>%
    dplyr::left_join(arms, by = "PATNO") %>%
    dplyr::left_join(per_bin %>% dplyr::select(PATNO, bin, NP1PAIN),
                     by = c("PATNO", "bin")) %>%
    dplyr::arrange(PATNO, bin) %>%
    dplyr::group_by(PATNO) %>%
    dplyr::mutate(NP1PAIN = {
      v <- NP1PAIN
      last <- NA_real_
      for (i in seq_along(v))      if (!is.na(v[i])) last <- v[i] else v[i] <- last
      nxt <- NA_real_
      for (i in rev(seq_along(v))) if (!is.na(v[i])) nxt  <- v[i] else v[i] <- nxt
      v
    }) %>%
    dplyr::ungroup() %>%
    dplyr::filter(!is.na(NP1PAIN)) %>%
    dplyr::mutate(
      pain_cat = factor(PAIN_LABS[NP1PAIN + 1], levels = PAIN_LABS),
      arm      = factor(dplyr::if_else(will_receive_dbs, "DBS", "Never-DBS"),
                        levels = c("DBS","Never-DBS")),
      bin_lab  = factor(
        paste0(dplyr::if_else(bin >= 0, "+", ""), bin, "m"),
        levels = paste0(dplyr::if_else(bin_range >= 0, "+", ""), bin_range, "m")
      )
    )
}

# ------------------------------------------------------------
# One panel. If `weight_var` given, use weighted counts for proportional y.
# ------------------------------------------------------------
plot_panel <- function(df, title, weight_var = NULL) {
  n_pat <- dplyr::n_distinct(df$PATNO)
  proportional <- !is.null(weight_var)

  base <- if (proportional) {
    ggplot(df, aes(x = bin_lab, stratum = pain_cat, alluvium = PATNO,
                   fill = pain_cat, y = .data[[weight_var]]))
  } else {
    ggplot(df, aes(x = bin_lab, stratum = pain_cat, alluvium = PATNO,
                   fill = pain_cat))
  }

  p <- base +
    ggalluvial::geom_flow(alpha = 0.65, width = 0.18, colour = "white",
                          linewidth = 0.1, reverse = TRUE) +
    ggalluvial::geom_stratum(width = 0.18, colour = "grey25",
                             size = 0.35, reverse = TRUE) +
    scale_fill_manual(values = PAIN_LEVEL_COLORS, drop = FALSE,
                      name = "PAIN") +
    labs(title = sprintf("%s (n = %d)", title, n_pat),
         x     = "Months from anchor",
         y     = if (proportional) "Proportion of patients" else "Patients") +
    theme_classic(base_size = 11) +
    theme(plot.title         = element_text(face = "bold", size = 12),
          axis.text.x        = element_text(size = 10),
          panel.grid.major.y = element_line(colour = "grey92", linewidth = 0.25))

  if (proportional) {
    p <- p + scale_y_continuous(labels = scales::percent_format(accuracy = 1),
                                expand = expansion(mult = c(0, 0.02)))
  }
  p
}

assemble <- function(grid, title_suffix, proportional = FALSE) {
  w <- NULL
  if (proportional) {
    grid <- grid %>%
      dplyr::group_by(arm, bin_lab) %>%
      dplyr::mutate(wt = 1 / dplyr::n()) %>%
      dplyr::ungroup()
    w <- "wt"
  }

  p_dbs <- plot_panel(dplyr::filter(grid, arm == "DBS"),
                      "A. DBS cohort (anchor = surgery date)", w)
  p_ctl <- plot_panel(dplyr::filter(grid, arm == "Never-DBS"),
                      "B. Never-DBS cohort (anchor = midpoint of follow-up)", w)

  (p_dbs / p_ctl) + plot_layout(guides = "collect") +
    plot_annotation(
      title   = sprintf("Pain-level trajectories - %s", title_suffix),
      caption = paste(
        "PAIN (MDS-UPDRS I, item 9, 0=None to 4=Very severe).",
        "DBS anchor = surgery date. Never-DBS anchor = midpoint of each patient's own follow-up (not a clinical event; a geometric device so controls have symmetric pre/post bins).",
        "Controls with shorter follow-up only populate the inner bins.",
        "Missing bins filled by LOCF (Last Observation Carried Forward) / NOCB (Next Observation Carried Backward) within patient.",
        sep = "\n"),
      theme   = theme(plot.title   = element_text(face = "bold", size = 14, hjust = 0.5),
                      plot.caption = element_text(colour = "grey35", size = 9, hjust = 0,
                                                  margin = margin(t = 8)))
    ) &
    theme(legend.position = "right")
}

# ------------------------------------------------------------
# 6-month and 12-month bin versions, absolute + proportional.
# ------------------------------------------------------------
cfgs <- list(
  list(bins = seq(-12, 36, by = 6), tag = "6mo", label = "6-month bins")
)

for (cfg in cfgs) {
  grid <- build_grid(cfg$bins)
  cat(sprintf("[%s] DBS=%d  Never-DBS=%d\n", cfg$tag,
              dplyr::n_distinct(grid$PATNO[grid$arm == "DBS"]),
              dplyr::n_distinct(grid$PATNO[grid$arm == "Never-DBS"])))

  fig_abs <- assemble(grid, sprintf("counts (%s)", cfg$label), proportional = FALSE)
  fig_pct <- assemble(grid, sprintf("proportion (%s)", cfg$label), proportional = TRUE)

  out_abs <- file.path(OUT_FIG, sprintf("Figure_Alluvial_NP1PAIN_abs_%s.png", cfg$tag))
  out_pct <- file.path(OUT_FIG, sprintf("Figure_Alluvial_NP1PAIN_pct_%s.png", cfg$tag))
  ggsave(out_abs, fig_abs, width = 10, height = 8, dpi = 300)
  ggsave(out_pct, fig_pct, width = 10, height = 8, dpi = 300)
  cat("[OK] saved", out_abs, "\n[OK] saved", out_pct, "\n")

  counts <- grid %>%
    dplyr::count(arm, bin_lab, pain_cat, .drop = FALSE) %>%
    tidyr::pivot_wider(names_from = pain_cat, values_from = n, values_fill = 0)
  save_table(counts, sprintf("alluvial_pain_counts_%s", cfg$tag))
}

cat("Done.\n")
