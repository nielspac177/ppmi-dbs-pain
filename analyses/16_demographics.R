#!/usr/bin/env Rscript
# 16_demographics.R
# ------------------------------------------------------------
# Reviewer comment #10 — external validity. Report race / ethnicity /
# education / geographic distribution of the DBS arm + Never-DBS for
# comparison.
# ------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(purrr); library(tibble)
  library(here); library(yaml); library(readxl)
})
here::i_am("sprints/16_demographics.R")
source(here::here("R/helpers/pain_helpers.R"))

# Try to pull demographics from PPMI_basic1.xlsx
rel <- load_full_ppmi_rel_patient_anchor()
demos_cols <- intersect(c("PATNO", "will_receive_dbs",
                           "SEX", "race", "RACE", "raceCAT",
                           "education", "EDUC", "EDUCYRS",
                           "ETHNICITY", "ethnicity",
                           "site", "SITE"),
                         names(rel))
cat("Demographic columns available in PPMI cohort:\n")
cat("  ", paste(demos_cols, collapse = ", "), "\n\n")

per_pat <- rel %>% dplyr::distinct(PATNO, will_receive_dbs,
                                    dplyr::across(dplyr::any_of(demos_cols))) %>%
  dplyr::mutate(arm = factor(dplyr::if_else(will_receive_dbs, "DBS", "Never-DBS"),
                              levels = c("Never-DBS", "DBS")))

# Build a Table 1-style demographics summary
summarise_var <- function(df, var) {
  if (!(var %in% names(df))) {
    return(tibble::tibble(variable = var, value = NA, dbs_n = 0,
                          dbs_pct = NA, ctl_n = 0, ctl_pct = NA))
  }
  v <- df[[var]]
  if (is.numeric(v)) {
    by_arm <- df %>% dplyr::group_by(arm) %>%
      dplyr::summarise(mean = mean(!!rlang::sym(var), na.rm = TRUE),
                       sd = sd(!!rlang::sym(var), na.rm = TRUE),
                       n = sum(!is.na(!!rlang::sym(var))),
                       .groups = "drop")
    return(tibble::tibble(
      variable = var, value = "Mean (SD)",
      dbs_n = by_arm$n[by_arm$arm == "DBS"],
      dbs_pct = sprintf("%.2f (%.2f)", by_arm$mean[by_arm$arm == "DBS"],
                        by_arm$sd[by_arm$arm == "DBS"]),
      ctl_n = by_arm$n[by_arm$arm == "Never-DBS"],
      ctl_pct = sprintf("%.2f (%.2f)", by_arm$mean[by_arm$arm == "Never-DBS"],
                        by_arm$sd[by_arm$arm == "Never-DBS"])
    ))
  } else {
    counts <- df %>% dplyr::group_by(arm, value = !!rlang::sym(var)) %>%
      dplyr::summarise(n = dplyr::n(), .groups = "drop") %>%
      dplyr::mutate(value = as.character(value)) %>%
      tidyr::pivot_wider(names_from = arm, values_from = n, values_fill = 0)
    if (!"DBS" %in% names(counts)) counts$DBS <- 0
    if (!"Never-DBS" %in% names(counts)) counts$`Never-DBS` <- 0
    counts %>% dplyr::mutate(
      variable = var,
      dbs_n = DBS,
      dbs_pct = sprintf("%.1f%%", 100 * DBS / sum(DBS)),
      ctl_n = `Never-DBS`,
      ctl_pct = sprintf("%.1f%%", 100 * `Never-DBS` / sum(`Never-DBS`))
    ) %>% dplyr::select(variable, value, dbs_n, dbs_pct, ctl_n, ctl_pct)
  }
}

vars_to_summarise <- intersect(c("SEX", "race", "RACE", "raceCAT",
                                   "EDUCYRS", "EDUC",
                                   "ETHNICITY", "ethnicity",
                                   "site", "SITE"),
                                 names(per_pat))

if (length(vars_to_summarise) == 0) {
  cat("[note] PPMI_basic1.xlsx does not include the standard demographic ",
      "columns (race / ethnicity / education / site). Falling back ",
      "to sex + age summary only.\n", sep = "")
  vars_to_summarise <- c("SEX")
}

tab <- purrr::map_dfr(vars_to_summarise, function(v) summarise_var(per_pat, v))
print(tab, n = 50)
save_table(16$NAME, "16_demographics")

cat("\n[OK] 16 outputs saved.\n")
