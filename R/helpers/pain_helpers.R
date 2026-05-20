# pain_helpers.R
# Shared functions for the Pain_paper_v2 notebook suite.
# Conventions:
#   - Time is in MONTHS (not days) throughout modelling to avoid scaling/convergence issues.
#   - time_pos_months = time_pos / (365.25/12)
#   - IPW weights column = weight_sw_trim90

suppressPackageStartupMessages({
  library(readr); library(readxl); library(dplyr); library(tidyr)
  library(ggplot2); library(scales); library(purrr); library(forcats)
  library(lubridate); library(here); library(yaml)
})

# Repository root via `here::here()`; data locations from config.yml so
# PPMI raw data lives outside the repo.
here::i_am("R/helpers/pain_helpers.R")
REPO_ROOT <- here::here()

cfg_path <- here::here("config.yml")
if (!file.exists(cfg_path)) {
  cfg_path <- here::here("config.example.yml")
}
.cfg <- yaml::read_yaml(cfg_path)

DATA_ROOT <- Sys.getenv("PPMI_DATA_ROOT",
                        unset = .cfg$data$ppmi_data_root)
OUT_FIG   <- here::here(.cfg$paths$figures)
OUT_TAB   <- here::here(.cfg$paths$tables)
OUT_OBJ   <- here::here(.cfg$paths$objects)

# Real-data files (resolved from DATA_ROOT or synthetic data)
USE_SYNTH <- isTRUE(.cfg$data$use_synth) ||
             Sys.getenv("PPMI_USE_SYNTH") == "1"

if (USE_SYNTH) {
  path_matched_long <- here::here("data-synth", "ppmi_synth_matched_long.csv")
  path_matched_six  <- here::here("data-synth", "ppmi_synth_matched_six.csv")
  path_full_xlsx    <- here::here("data-synth", "ppmi_synth_basic1.xlsx")
  message("[pain_helpers] using SYNTHETIC data (PPMI raw data not available).")
} else {
  path_matched_long <- file.path(DATA_ROOT, .cfg$data$matched_long_csv)
  path_matched_six  <- file.path(DATA_ROOT, .cfg$data$matched_six_csv)
  path_full_xlsx    <- file.path(DATA_ROOT, .cfg$data$full_xlsx)
}

DAYS_PER_MONTH <- 365.25 / 12

# ---- Palettes kept consistent across figures ----
TRAJ_COLORS <- c(
  "Pre-DBS"   = "#1b9e77",
  "Post-DBS"  = "#d95f02",
  "Never-DBS" = "#7570b3"
)

ARM_COLORS <- c(
  "Never-DBS" = "#7570b3",
  "DBS Group" = "#d95f02"
)

PAIN_LEVEL_COLORS <- c(
  "0 None"        = "#EAF2FA",
  "1 Mild"        = "#CFE1F2",
  "2 Moderate"    = "#9FC5E8",
  "3 Severe"      = "#6FA8DC",
  "4 Very severe" = "#1E62A1"
)

# ---- Loaders ----
load_matched_long <- function(path = path_matched_long) {
  df <- readr::read_csv(path, show_col_types = FALSE)
  needed <- c("PATNO","INFODT_orig","traj","time_pos","time_bin","months",
              "will_receive_dbs","weight_sw_trim90","NP1PAIN")
  miss <- setdiff(needed, names(df))
  if (length(miss) > 0) stop("Missing columns: ", paste(miss, collapse = ", "))

  df <- df %>%
    mutate(
      time_pos_months = time_pos / DAYS_PER_MONTH,
      traj = dplyr::if_else(traj == "Never DBS", "Never-DBS", traj),
      traj = factor(traj, levels = c("Pre-DBS","Post-DBS","Never-DBS"))
    )
  df
}

load_full_cohort <- function(path = path_full_xlsx) {
  full <- readxl::read_excel(path)
  full %>%
    mutate(
      INFODT_orig = as.Date(INFODT_orig),
      dbs_date    = suppressWarnings(as.Date(dbs_date))
    )
}

# ---- Build ppmi_rel (the full-cohort, anchor-aligned long frame) ----
# Mirrors the anchor logic in the sleep notebook / PPMI_mixed_models_v8.Rmd.
# DBS patients anchored at their first dbs_date; controls at the median of DBS dates.
load_full_ppmi_rel <- function(path = path_full_xlsx) {
  full <- load_full_cohort(path)

  first_dbs_dates <- full %>%
    dplyr::filter(will_receive_dbs, !is.na(dbs_date)) %>%
    dplyr::group_by(PATNO) %>%
    dplyr::summarise(first_dbs = min(dbs_date, na.rm = TRUE), .groups = "drop") %>%
    dplyr::pull(first_dbs)
  sham_anchor <- stats::median(first_dbs_dates)

  full %>%
    dplyr::group_by(PATNO) %>%
    dplyr::mutate(
      anchor_date = dplyr::if_else(
        will_receive_dbs & any(!is.na(dbs_date)),
        suppressWarnings(min(dbs_date, na.rm = TRUE)),
        sham_anchor
      ),
      time_days   = as.numeric(difftime(INFODT_orig, anchor_date, units = "days")),
      time_months = time_days / DAYS_PER_MONTH,
      time_years  = time_months / 12,
      time_bin    = floor(time_days / 180),
      months      = time_bin * 6
    ) %>%
    dplyr::ungroup() %>%
    dplyr::filter(is.finite(time_bin))
}

# ---- Full cohort with PATIENT-SPECIFIC anchor ----
# DBS patients anchored at first dbs_date; controls anchored at THEIR OWN earliest visit.
# This preserves ~all 1,485 patients in the pre/post windows.
load_full_ppmi_rel_patient_anchor <- function(path = path_full_xlsx) {
  full <- load_full_cohort(path)

  ctl_anchors <- full %>%
    dplyr::filter(!will_receive_dbs) %>%
    dplyr::group_by(PATNO) %>%
    dplyr::summarise(ctl_anchor = min(INFODT_orig, na.rm = TRUE), .groups = "drop")

  dbs_anchors <- full %>%
    dplyr::filter(will_receive_dbs, !is.na(dbs_date)) %>%
    dplyr::group_by(PATNO) %>%
    dplyr::summarise(dbs_anchor = min(dbs_date, na.rm = TRUE), .groups = "drop")

  anchors <- full %>% dplyr::distinct(PATNO, will_receive_dbs) %>%
    dplyr::left_join(ctl_anchors, by = "PATNO") %>%
    dplyr::left_join(dbs_anchors, by = "PATNO") %>%
    dplyr::mutate(anchor_date = dplyr::if_else(will_receive_dbs, dbs_anchor, ctl_anchor))

  full %>%
    dplyr::left_join(anchors %>% dplyr::select(PATNO, anchor_date), by = "PATNO") %>%
    dplyr::filter(!is.na(anchor_date)) %>%
    dplyr::mutate(
      time_days   = as.numeric(difftime(INFODT_orig, anchor_date, units = "days")),
      time_months = time_days / DAYS_PER_MONTH,
      time_years  = time_months / 12,
      time_bin    = floor(time_days / 180),
      months      = time_bin * 6
    ) %>%
    dplyr::filter(is.finite(time_bin))
}

# ---- Analgesic keyword match (generic + brand names) ----
ANALGESIC_PATTERNS <- c(
  # Opioids
  "morphine","oxycodone","hydrocodone","tramadol","codeine","fentanyl","oxycontin","vicodin","percocet",
  "tapentadol","buprenorphine","hydromorphone","methadone",
  # NSAIDs
  "ibuprofen","naproxen","meloxicam","diclofenac","celecoxib","celebrex","aspirin","indomethacin","ketorolac",
  "etodolac","nabumetone","piroxicam","aleve","advil","motrin",
  # Neuropathic pain
  "gabapentin","pregabalin","duloxetine","amitriptyline","nortriptyline","cymbalta","lyrica","neurontin","tegretol","carbamazepine",
  # Acetaminophen
  "acetaminophen","paracetamol","tylenol",
  # Topicals / muscle
  "lidocaine","cyclobenzaprine","baclofen","tizanidine","flexeril"
)
ANALGESIC_REGEX <- paste(ANALGESIC_PATTERNS, collapse = "|")

# ---- Analgesics by therapeutic class (excluding aspirin, which is cardio-preventive) ----
ANALGESIC_CLASSES <- list(
  opioid       = c("morphine","oxycodone","hydrocodone","tramadol","codeine","fentanyl","oxycontin","vicodin","percocet","tapentadol","buprenorphine","hydromorphone","methadone"),
  nsaid        = c("ibuprofen","naproxen","meloxicam","diclofenac","celecoxib","celebrex","indomethacin","ketorolac","etodolac","nabumetone","piroxicam","aleve","advil","motrin"),
  neuropathic  = c("gabapentin","pregabalin","duloxetine","amitriptyline","nortriptyline","cymbalta","lyrica","neurontin","tegretol","carbamazepine"),
  acetaminophen = c("acetaminophen","paracetamol","tylenol"),
  muscle_relax = c("cyclobenzaprine","baclofen","tizanidine","flexeril"),
  topical      = c("lidocaine")
)

# ---- Pain-diagnosis keyword match on free-text MHTERM ----
PAIN_PHENOTYPE_PATTERNS <- list(
  musculoskeletal = c("arthritis","osteoarthritis","back pain","lumbago","spondyl","myalgia","muscle pain","joint pain","low back","cervical","fibromyalgia","tendon","bursitis","rotator"),
  neuropathic     = c("neuropath","neuralgia","sciatica","radicul","trigeminal","shingles","post.herpetic","carpal tunnel","tarsal","diabetic neurop"),
  dystonic        = c("dystonia","dystonic","cramp","spasm"),
  central         = c("central pain","thalamic pain","fibromyalgia"),
  headache        = c("migraine","headache","cephalgia","tension head"),
  visceral        = c("abdominal pain","gastritis","irritable bowel","ibs","dysmenorrhea","pelvic pain","prostatitis")
)

# ---- Per-patient pre/post window summaries + pre-trajectory features ----
# Outcome: Δ NP1PAIN (post − pre mean), `worsened` = Δ ≥ 1
# Features: pre mean, pre slope (months unit), pre last value, pre count, pre max, pre SD
build_per_patient_features <- function(rel, var = "NP1PAIN",
                                        pre_win = c(-24, 0),
                                        post_win = c(6, 18)) {
  in_pre  <- rel %>% dplyr::filter(months >= pre_win[1],  months <= pre_win[2],
                                   !is.na(.data[[var]]))
  in_post <- rel %>% dplyr::filter(months >= post_win[1], months <= post_win[2],
                                   !is.na(.data[[var]]))

  per_pre <- in_pre %>% dplyr::group_by(PATNO) %>%
    dplyr::summarise(
      pre_mean = mean(.data[[var]]),
      pre_max  = max(.data[[var]]),
      pre_sd   = stats::sd(.data[[var]]),
      pre_last = .data[[var]][which.max(time_months)],
      pre_n    = dplyr::n(),
      pre_slope = {
        x <- time_months; y <- .data[[var]]
        ok <- stats::complete.cases(x, y)
        if (sum(ok) >= 2 && stats::var(x[ok]) > 0)
          stats::coef(stats::lm(y[ok] ~ x[ok]))[2] else NA_real_
      },
      .groups = "drop"
    )

  per_post <- in_post %>% dplyr::group_by(PATNO) %>%
    dplyr::summarise(post_mean = mean(.data[[var]]),
                     post_n = dplyr::n(), .groups = "drop")

  per_pre %>% dplyr::inner_join(per_post, by = "PATNO") %>%
    dplyr::mutate(delta = post_mean - pre_mean,
                  worsened = as.integer(delta >= 1))
}

# ---- Deduplication ----
dedup_earliest_per_bin <- function(df) {
  df %>%
    filter(is.finite(time_bin)) %>%
    arrange(PATNO, time_bin, INFODT_orig) %>%
    group_by(PATNO, time_bin) %>%
    slice_head(n = 1) %>%
    ungroup()
}

# ---- Pre / post DBS split at the patient level ----
split_pre_post <- function(df, var = "NP1PAIN", windows = list(pre = c(-12, 0), post = c(6, 18))) {
  pre_lo <- windows$pre[1];  pre_hi <- windows$pre[2]
  po_lo  <- windows$post[1]; po_hi  <- windows$post[2]

  pre <- df %>%
    filter(months >= pre_lo, months <= pre_hi, !is.na(.data[[var]])) %>%
    group_by(PATNO, will_receive_dbs) %>%
    summarise(pre_val = mean(.data[[var]]), n_pre = n(), .groups = "drop")

  post <- df %>%
    filter(months >= po_lo, months <= po_hi, !is.na(.data[[var]])) %>%
    group_by(PATNO, will_receive_dbs) %>%
    summarise(post_val = mean(.data[[var]]), n_post = n(), .groups = "drop")

  pre %>%
    inner_join(post, by = c("PATNO","will_receive_dbs")) %>%
    mutate(delta = post_val - pre_val)
}

# ---- Save helpers ----
save_fig <- function(plot, name, width = 7, height = 4.5, dpi = 300) {
  dir.create(OUT_FIG, showWarnings = FALSE, recursive = TRUE)
  ggplot2::ggsave(file.path(OUT_FIG, paste0(name, ".png")),
                  plot = plot, width = width, height = height, dpi = dpi)
  invisible(plot)
}

save_object <- function(obj, name) {
  dir.create(OUT_OBJ, showWarnings = FALSE, recursive = TRUE)
  saveRDS(obj, file.path(OUT_OBJ, paste0(name, ".rds")))
  invisible(obj)
}

save_table <- function(df, name) {
  dir.create(OUT_TAB, showWarnings = FALSE, recursive = TRUE)
  readr::write_csv(df, file.path(OUT_TAB, paste0(name, ".csv")))
  invisible(df)
}

# =================================================================
# v2 additions (for sprint analyses) — kept alongside legacy helpers
# =================================================================

# ---- Okabe-Ito colourblind-safe palette ----
OKABE_ITO <- c(
  black     = "#000000",
  orange    = "#E69F00",
  sky_blue  = "#56B4E9",
  green     = "#009E73",
  yellow    = "#F0E442",
  blue      = "#0072B2",
  vermillion= "#D55E00",
  pink      = "#CC79A7"
)

ARM_COLORS_OK <- c(
  "Never-DBS" = unname(OKABE_ITO["blue"]),
  "DBS"       = unname(OKABE_ITO["vermillion"]),
  "DBS Group" = unname(OKABE_ITO["vermillion"])
)

TRAJ_COLORS_OK <- c(
  "Pre-DBS"   = unname(OKABE_ITO["green"]),
  "Post-DBS"  = unname(OKABE_ITO["vermillion"]),
  "Never-DBS" = unname(OKABE_ITO["blue"])
)

# ---- Symmetric-midpoint anchor for Never-DBS controls ----
# Extracted from 26b / 26c so the POSIXct->Date fix lives in one place.
compute_symmetric_midpoint_anchors <- function(rel_raw) {
  dbs_a <- rel_raw %>%
    dplyr::filter(will_receive_dbs, !is.na(anchor_date)) %>%
    dplyr::distinct(PATNO, anchor_date)

  ctl_a <- rel_raw %>%
    dplyr::filter(!will_receive_dbs, !is.na(INFODT_orig)) %>%
    dplyr::group_by(PATNO) %>%
    dplyr::summarise(
      anchor_date = {
        f <- as.Date(min(INFODT_orig, na.rm = TRUE))
        l <- as.Date(max(INFODT_orig, na.rm = TRUE))
        f + as.numeric(difftime(l, f, units = "days")) / 2
      },
      .groups = "drop"
    )
  dplyr::bind_rows(dbs_a, ctl_a) %>% dplyr::distinct(PATNO, .keep_all = TRUE)
}

# ---- Rebuild time columns relative to a fresh anchor table ----
rebind_time_cols <- function(rel_raw, anchors) {
  rel_raw %>%
    dplyr::select(-dplyr::any_of(c("anchor_date","time_days","time_pos",
                                   "time_pos_months","months","time_bin"))) %>%
    dplyr::left_join(anchors, by = "PATNO") %>%
    dplyr::filter(!is.na(anchor_date)) %>%
    dplyr::mutate(
      time_days   = as.numeric(difftime(as.Date(INFODT_orig),
                                        as.Date(anchor_date),
                                        units = "days")),
      time_months = time_days / DAYS_PER_MONTH,
      time_bin    = floor(time_days / 180),
      months      = time_bin * 6
    ) %>%
    dplyr::filter(is.finite(time_bin))
}

# ---- Publication-quality figure save (PNG + PDF + optional TIFF) ----
save_fig_pub <- function(plot, name, width = 7, height = 4.5,
                         dpi = 300, tiff = FALSE) {
  dir.create(OUT_FIG, showWarnings = FALSE, recursive = TRUE)
  ggplot2::ggsave(file.path(OUT_FIG, paste0(name, ".png")),
                  plot = plot, width = width, height = height, dpi = dpi)
  ggplot2::ggsave(file.path(OUT_FIG, paste0(name, ".pdf")),
                  plot = plot, width = width, height = height, device = cairo_pdf)
  if (tiff) {
    ggplot2::ggsave(file.path(OUT_FIG, paste0(name, ".tiff")),
                    plot = plot, width = width, height = height,
                    dpi = 600, compression = "lzw")
  }
  invisible(plot)
}

# ---- Theme for publication-quality figures ----
theme_pain_pub <- function(base_size = 11) {
  ggplot2::theme_classic(base_size = base_size) +
    ggplot2::theme(
      plot.title       = ggplot2::element_text(face = "bold", size = base_size + 1),
      plot.subtitle    = ggplot2::element_text(size = base_size - 1, colour = "grey30"),
      axis.title       = ggplot2::element_text(size = base_size),
      axis.text        = ggplot2::element_text(size = base_size - 1),
      legend.position  = "top",
      legend.title     = ggplot2::element_text(size = base_size - 1),
      legend.text      = ggplot2::element_text(size = base_size - 1),
      strip.background = ggplot2::element_rect(fill = "grey92", colour = NA),
      strip.text       = ggplot2::element_text(face = "bold", size = base_size)
    )
}
