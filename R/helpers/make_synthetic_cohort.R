#!/usr/bin/env Rscript
# make_synthetic_cohort.R
# ----------------------------------------------------------------
# Generate a synthetic PPMI-shaped cohort (n = 1,484; 105 DBS,
# 1,379 Never-DBS) preserving variable names and rough marginals
# so the pipeline can be exercised without PPMI access.
#
# Reproducibility: seeded; deterministic given seed 20260519.
# FAKE DATA — DO NOT USE FOR INFERENCE.
# ----------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readr); library(writexl)
  library(here); library(lubridate)
})

here::i_am("R/helpers/make_synthetic_cohort.R")
SET_SEED <- 20260519
set.seed(SET_SEED)

OUT <- here::here("data-synth")
dir.create(OUT, showWarnings = FALSE, recursive = TRUE)

N_DBS <- 105
N_NEV <- 1379
N <- N_DBS + N_NEV

# Patient table -------------------------------------------------
patients <- tibble::tibble(
  PATNO = sample(3000:9999, N, replace = FALSE),
  will_receive_dbs = rep(c(TRUE, FALSE), times = c(N_DBS, N_NEV)),
  SEX  = sample(c("M", "F"), N, replace = TRUE, prob = c(0.65, 0.35)),
  age_at_visit = round(rnorm(N, 62, 9)),  # rough enrollment age
  duration = pmax(0.1, rnorm(N, 1.5, 1.5)),  # years from diagnosis
  fampd = sample(c(0, 1), N, replace = TRUE, prob = c(0.85, 0.15))
)
patients$dbs_date <- ifelse(
  patients$will_receive_dbs,
  as.character(as.Date("2018-01-01") + sample(0:1800, N, replace = TRUE)),
  NA_character_
)

# Multi-visit long table ---------------------------------------
# Each patient has 4 to 18 visits at irregular intervals.
make_visits <- function(p) {
  n_visits <- sample(4:18, 1)
  first    <- as.Date("2010-01-01") + sample(0:3000, 1)
  intervals <- pmax(60, round(rnorm(n_visits, 180, 90)))  # ~6 mo gaps
  dates <- first + cumsum(c(0, intervals))[seq_len(n_visits)]

  has_dbs <- p$will_receive_dbs
  pain_baseline <- rpois(1, ifelse(has_dbs, 1.0, 0.7))
  motor_base    <- ifelse(has_dbs, rnorm(1, 28, 8), rnorm(1, 18, 8))
  ledd_base     <- ifelse(has_dbs, rnorm(1, 950, 350), rnorm(1, 350, 250))

  # Per visit: noisy drift; DBS injects a one-time motor-improvement step at dbs_date
  pain_walk  <- pmax(0, pmin(4, round(pain_baseline + cumsum(rnorm(n_visits, 0.02, 0.4)))))
  motor_walk <- motor_base + cumsum(rnorm(n_visits, 0.15, 2))
  if (has_dbs) {
    dbs_d <- as.Date(p$dbs_date)
    idx_post <- which(dates >= dbs_d)
    motor_walk[idx_post] <- motor_walk[idx_post] - rnorm(length(idx_post), 5, 2)
  }
  ledd_walk <- pmax(0, ledd_base + cumsum(rnorm(n_visits, 5, 30)))
  if (has_dbs) {
    dbs_d <- as.Date(p$dbs_date)
    idx_post <- which(dates >= dbs_d)
    ledd_walk[idx_post] <- ledd_walk[idx_post] - rnorm(length(idx_post), 200, 100)
  }

  tibble::tibble(
    PATNO = p$PATNO,
    will_receive_dbs = has_dbs,
    dbs_date = if (has_dbs) as.Date(p$dbs_date) else as.Date(NA),
    INFODT_orig = dates,
    NP1PAIN  = pain_walk,
    NP1SLPN  = pmax(0, pmin(4, round(pain_walk + rnorm(n_visits, 0, 0.5)))),
    NP1SLPD  = pmax(0, pmin(4, round(pain_walk + rnorm(n_visits, 0, 0.5)))),
    NP1FATG  = pmax(0, pmin(4, round(pain_walk + rnorm(n_visits, 0.3, 0.5)))),
    NP1URIN  = pmax(0, pmin(4, round(rnorm(n_visits, 1, 0.6)))),
    NP1DPRS  = pmax(0, pmin(4, round(rnorm(n_visits, 0.7, 0.6)))),
    NP1ANXS  = pmax(0, pmin(4, round(rnorm(n_visits, 0.7, 0.6)))),
    NP1HALL  = pmax(0, pmin(4, round(rnorm(n_visits, 0.05, 0.2)))),
    NP1COG   = pmax(0, pmin(4, round(rnorm(n_visits, 0.4, 0.5)))),
    NP1APAT  = pmax(0, pmin(4, round(rnorm(n_visits, 0.4, 0.5)))),
    NP1DDS   = pmax(0, pmin(4, round(rnorm(n_visits, 0.2, 0.3)))),
    updrs3_score = pmax(0, motor_walk),
    LEDD = ledd_walk,
    BMI = round(rnorm(1, 27, 4), 1),
    SEX = p$SEX,
    age_at_visit = p$age_at_visit + as.numeric(difftime(dates, first, units = "days")) / 365.25,
    duration = p$duration,
    NHY = pmin(5, pmax(1, round(rnorm(n_visits, ifelse(has_dbs, 2.5, 2.0), 0.7)))),
    gds = pmax(0, round(rnorm(n_visits, 4, 2))),
    stai = pmax(0, round(rnorm(n_visits, 35, 8))),
    ess  = pmax(0, round(rnorm(n_visits, 7, 4))),
    rem  = pmax(0, round(rnorm(n_visits, 4, 2))),
    scopa = pmax(0, round(rnorm(n_visits, 9, 4)))
  )
}

cat("Generating synthetic long table…\n")
long_rows <- patients %>% dplyr::rowwise() %>%
  dplyr::do(make_visits(.)) %>%
  dplyr::ungroup()
cat("  Synthetic long rows:", nrow(long_rows), "\n")

# Time fields (anchor will be recomputed by load_full_ppmi_rel_*).
# We don't store an `anchor_date` column here to avoid name collisions
# when the load_*() helpers join their own anchor table back in.
long_rows <- long_rows %>%
  dplyr::group_by(PATNO, will_receive_dbs) %>%
  dplyr::mutate(
    # CRITICAL: for DBS patients, anchor MUST be the dbs_date so
    # pre-surgery visits get time_days < 0 (Pre-DBS) and post-surgery
    # visits get time_days >= 0 (Post-DBS). The old logic used the first
    # visit for both arms, which produced zero Pre-DBS rows.
    .anchor = dplyr::if_else(
      any(will_receive_dbs) & any(!is.na(dbs_date)),
      as.Date(min(dbs_date, na.rm = TRUE)),
      as.Date(min(INFODT_orig, na.rm = TRUE))
    )
  ) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(
    time_days   = as.numeric(difftime(INFODT_orig, .anchor, units = "days")),
    time_pos    = abs(time_days),
    time_months = time_days / (365.25 / 12),
    time_pos_months = time_pos / (365.25 / 12),
    time_bin = floor(time_days / 180),
    months   = time_bin * 6,
    weight_sw_trim90 = 1.0,
    traj = dplyr::case_when(
      will_receive_dbs & time_days < 0  ~ "Pre-DBS",
      will_receive_dbs & time_days >= 0 ~ "Post-DBS",
      TRUE                              ~ "Never-DBS"
    )
  ) %>% dplyr::select(-.anchor)

# Save outputs --------------------------------------------------
cat("Writing data-synth/ppmi_synth_matched_long.csv …\n")
readr::write_csv(long_rows, file.path(OUT, "ppmi_synth_matched_long.csv"))
cat("Writing data-synth/ppmi_synth_basic1.xlsx …\n")
writexl::write_xlsx(long_rows, file.path(OUT, "ppmi_synth_basic1.xlsx"))

# Provenance README in data-synth/
readr::write_file(paste0(
  "# data-synth/ — synthetic PPMI fixture\n\n",
  "**FAKE DATA. DO NOT USE FOR INFERENCE.**\n\n",
  "Generated by `R/helpers/make_synthetic_cohort.R` with seed ",
  SET_SEED, ".\n",
  "Preserves variable names and rough marginal distributions of the\n",
  "real PPMI Curated Cut (Nov 2024) but does NOT reproduce joint\n",
  "distributions, temporal correlations, or treatment effects.\n\n",
  "n = ", nrow(long_rows), " visits across ", N, " patients (",
  N_DBS, " DBS / ", N_NEV, " Never-DBS).\n"
), file.path(OUT, "README.md"))

cat("[OK] synthetic cohort generated.\n")
