#!/usr/bin/env Rscript
# 25_genetics_arm_pain.R
# ------------------------------------------------------------
# Genetics/biomarker x DBS interaction analyses on Delta pain
# (post_win [6,18] - pre_win [-24,0] from patient-anchor frame).
#
# Four analyses:
#   1. PD-PRS  (allele-count sum over 55 NeuroChip GWAS SNPs;
#               z-scored; tertile groups)     x DBS  -> Delta pain
#   2. APOE-e4 carrier (0/1)                  x DBS  -> Delta pain
#   3. CSF alpha-syn SAA positivity           x DBS  -> Delta pain
#   4. GBA+ carrier subgroup                  x DBS  -> Delta pain
#
# Inputs
#   - outputs/objects/patient_anchor_features_enriched.rds
#   - /Volumes/Niels_3/MJF data/ppmi_database.db  (genetic_variants,
#     genetic_status)
#
# Outputs (figure + tables)
#   - outputs/figures/Figure25_genetics_forest.png
#   - outputs/tables/genetics_prs_by_arm.csv
#   - outputs/tables/genetics_apoe_by_arm.csv
#   - outputs/tables/genetics_saa_by_arm.csv
#   - outputs/tables/genetics_gba_by_arm.csv
#   - outputs/tables/genetics_interaction_summary.csv
# ------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(purrr)
  library(tibble); library(DBI); library(RSQLite); library(broom)
})
source("helpers/pain_helpers.R")

DB_PATH <- "/Volumes/Niels_3/MJF data/ppmi_database.db"

dat <- readRDS(file.path(OUT_OBJ, "patient_anchor_features_enriched.rds"))
cat("Enriched feature frame:", nrow(dat), "patients  (",
    sum(dat$will_receive_dbs), "DBS /",
    sum(!dat$will_receive_dbs), "Never-DBS )\n")

# ============================================================
# Helper: run a simple 2x2 (or 2x3) arm x genotype analysis
# ============================================================
run_arm_x_geno <- function(df, geno_col, outcome = "delta",
                           min_n = 3) {
  df <- df %>% dplyr::filter(!is.na(.data[[geno_col]]),
                             !is.na(.data[[outcome]]))
  if (!nrow(df)) return(NULL)

  # Per-group summary (n, mean, SE)
  summ <- df %>%
    dplyr::mutate(arm = dplyr::if_else(will_receive_dbs,
                                       "DBS", "Never-DBS")) %>%
    dplyr::group_by(geno = .data[[geno_col]], arm) %>%
    dplyr::summarise(
      n          = dplyr::n(),
      mean_delta = mean(.data[[outcome]], na.rm = TRUE),
      se         = stats::sd(.data[[outcome]], na.rm = TRUE) /
                   sqrt(pmax(dplyr::n(), 1)),
      .groups    = "drop"
    )

  # Welch t-test DBS vs Never-DBS within each genotype level
  t_rows <- purrr::map_dfr(unique(summ$geno), function(g) {
    sub <- df %>% dplyr::filter(.data[[geno_col]] == g)
    n_dbs <- sum(sub$will_receive_dbs)
    n_ctl <- sum(!sub$will_receive_dbs)
    if (n_dbs < min_n || n_ctl < min_n) {
      return(tibble::tibble(geno = g, n_dbs = n_dbs, n_ctl = n_ctl,
                            t_est = NA_real_, t_p = NA_real_))
    }
    tt <- stats::t.test(
      sub[[outcome]][sub$will_receive_dbs],
      sub[[outcome]][!sub$will_receive_dbs]
    )
    tibble::tibble(geno = g, n_dbs = n_dbs, n_ctl = n_ctl,
                   t_est = unname(diff(tt$estimate)),
                   t_p   = tt$p.value)
  })

  # Interaction P (arm * geno)
  tmp <- df %>%
    dplyr::mutate(arm_i = as.integer(will_receive_dbs),
                  geno  = .data[[geno_col]])
  fit <- tryCatch(
    stats::lm(stats::as.formula(paste(outcome, "~ arm_i * geno")),
              data = tmp),
    error = function(e) NULL
  )
  p_int <- NA_real_
  if (!is.null(fit)) {
    aov <- stats::anova(fit)
    row_name <- grep(":", rownames(aov), value = TRUE)[1]
    if (!is.na(row_name)) p_int <- aov[row_name, "Pr(>F)"]
  }

  list(summary = summ, t_tests = t_rows, p_interaction = p_int)
}

# ============================================================
# 1. Build PD-PRS from NeuroChip GWAS risk SNPs
# ============================================================
con <- DBI::dbConnect(RSQLite::SQLite(), DB_PATH)
gv <- DBI::dbGetQuery(con, paste(
  "SELECT patno, variant_name, gene, genotype FROM genetic_variants",
  "WHERE variant_name LIKE 'chr%'"   # drop pathogenic rare variants
                                     # (L444P, A53T, G2019S, etc.)
))
apoe <- DBI::dbGetQuery(con,
  "SELECT patno, apoe_e4_carrier, apoe_genotype,
          gba_carrier, lrrk2_carrier, snca_carrier
   FROM genetic_status"
)
DBI::dbDisconnect(con)

cat("\nGWAS risk SNP coverage: ", dplyr::n_distinct(gv$variant_name),
    "variants x", dplyr::n_distinct(gv$patno), "patients\n")

# Allele-count PRS: sum of (0/1/2) across variants per patient.
# Standardised to z. Coded as risk *dosage* given the PPMI encoding;
# some SNPs may be coded on the protective allele, so we report this
# as a burden score with direction to be interpreted empirically.
prs <- gv %>%
  dplyr::filter(!is.na(genotype)) %>%
  dplyr::group_by(patno) %>%
  dplyr::summarise(prs_raw     = sum(genotype),
                   prs_n_snps  = dplyr::n(),
                   .groups     = "drop") %>%
  dplyr::mutate(prs_z = as.numeric(scale(prs_raw)),
                prs_tertile = factor(
                  cut(prs_z,
                      breaks = stats::quantile(prs_z,
                                               c(0, 1/3, 2/3, 1),
                                               na.rm = TRUE),
                      labels = c("Low", "Mid", "High"),
                      include.lowest = TRUE),
                  levels = c("Low", "Mid", "High")))

cat("PRS z-scored. Tertile cuts at 1/3 and 2/3 quantiles.\n")

# Merge PRS + APOE into enriched feature frame
dat <- dat %>%
  dplyr::left_join(prs %>% dplyr::select(PATNO = patno,
                                         prs_raw, prs_z, prs_tertile),
                   by = "PATNO") %>%
  dplyr::left_join(apoe %>% dplyr::select(PATNO = patno,
                                          apoe_e4_carrier,
                                          gba_carrier,
                                          lrrk2_carrier,
                                          snca_carrier),
                   by = "PATNO") %>%
  dplyr::mutate(
    apoe_grp   = dplyr::case_when(
      is.na(apoe_e4_carrier) ~ NA_character_,
      apoe_e4_carrier == 0   ~ "APOE-e4 neg",
      apoe_e4_carrier >= 1   ~ "APOE-e4 pos"
    ),
    saa_grp    = dplyr::case_when(
      is.na(CSFSAA) ~ NA_character_,
      CSFSAA == 0   ~ "SAA neg",
      CSFSAA >= 1   ~ "SAA pos"       # 1/2/3 all treated as positive
    ),
    gba_grp    = dplyr::case_when(
      is.na(gba_carrier) ~ NA_character_,
      gba_carrier == 0   ~ "GBA-",
      gba_carrier == 1   ~ "GBA+"
    )
  )

cat("\nCoverage after merge:\n")
print(dat %>% dplyr::summarise(
  prs     = sum(!is.na(prs_z)),
  apoe    = sum(!is.na(apoe_grp)),
  saa     = sum(!is.na(saa_grp)),
  gba     = sum(!is.na(gba_grp))
))

# ============================================================
# Run all four analyses
# ============================================================
res_prs  <- run_arm_x_geno(dat, "prs_tertile")
res_apoe <- run_arm_x_geno(dat, "apoe_grp")
res_saa  <- run_arm_x_geno(dat, "saa_grp")
res_gba  <- run_arm_x_geno(dat, "gba_grp")

cat("\n------ PRS tertile x DBS ------\n")
print(res_prs$summary);  print(res_prs$t_tests)
cat(sprintf("interaction P = %.3f\n", res_prs$p_interaction))

cat("\n------ APOE-e4 x DBS ------\n")
print(res_apoe$summary); print(res_apoe$t_tests)
cat(sprintf("interaction P = %.3f\n", res_apoe$p_interaction))

cat("\n------ CSF alpha-syn SAA x DBS ------\n")
print(res_saa$summary);  print(res_saa$t_tests)
cat(sprintf("interaction P = %.3f\n", res_saa$p_interaction))

cat("\n------ GBA+ x DBS ------\n")
print(res_gba$summary);  print(res_gba$t_tests)
cat(sprintf("interaction P = %.3f\n", res_gba$p_interaction))

# ============================================================
# Persist tables
# ============================================================
save_one <- function(res, prefix) {
  if (is.null(res)) return(invisible(NULL))
  save_table(res$summary, paste0("genetics_", prefix, "_summary"))
  save_table(res$t_tests, paste0("genetics_", prefix, "_welch"))
}
save_one(res_prs,  "prs")
save_one(res_apoe, "apoe")
save_one(res_saa,  "saa")
save_one(res_gba,  "gba")

interaction_tbl <- tibble::tibble(
  stratifier   = c("PRS tertile", "APOE-e4", "SAA", "GBA+"),
  p_interaction = c(res_prs$p_interaction, res_apoe$p_interaction,
                   res_saa$p_interaction, res_gba$p_interaction)
)
save_table(interaction_tbl, "genetics_interaction_summary")
print(interaction_tbl)

# ============================================================
# Forest plot of per-stratum (DBS - Never-DBS) Delta pain
# ============================================================
mk_forest_rows <- function(res, stratifier) {
  if (is.null(res)) return(NULL)
  res$summary %>%
    tidyr::pivot_wider(names_from = arm,
                       values_from = c(n, mean_delta, se),
                       names_sep = "_") %>%
    dplyr::mutate(
      stratifier  = stratifier,
      stratum     = as.character(geno),
      diff        = mean_delta_DBS - `mean_delta_Never-DBS`,
      se_diff     = sqrt(se_DBS^2 + `se_Never-DBS`^2),
      lo          = diff - 1.96 * se_diff,
      hi          = diff + 1.96 * se_diff,
      n_label     = sprintf("%d / %d", n_DBS, `n_Never-DBS`)
    ) %>%
    dplyr::select(stratifier, stratum, diff, lo, hi, n_label)
}

forest_df <- dplyr::bind_rows(
  mk_forest_rows(res_prs,  "PRS tertile"),
  mk_forest_rows(res_apoe, "APOE-e4"),
  mk_forest_rows(res_saa,  "SAA"),
  mk_forest_rows(res_gba,  "GBA+")
) %>%
  dplyr::mutate(
    stratifier = factor(stratifier,
                        levels = c("PRS tertile", "APOE-e4",
                                   "SAA", "GBA+")),
    row_lab = paste0(stratifier, ": ", stratum)
  )

forest_df <- forest_df %>%
  dplyr::arrange(stratifier, stratum) %>%
  dplyr::mutate(row_lab = factor(row_lab, levels = rev(row_lab)))

p_int_lab <- tibble::tibble(
  stratifier = c("PRS tertile", "APOE-e4", "SAA", "GBA+"),
  p_int      = c(res_prs$p_interaction, res_apoe$p_interaction,
                 res_saa$p_interaction, res_gba$p_interaction)
)

x_hi_txt  <- max(forest_df$hi, na.rm = TRUE) + 0.10
x_hi_plot <- max(forest_df$hi, na.rm = TRUE) + 0.80

p_forest <- ggplot(forest_df, aes(x = diff, y = row_lab)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey55") +
  geom_errorbar(aes(xmin = lo, xmax = hi), width = 0.20,
                colour = "grey40", orientation = "y") +
  geom_point(size = 2.4, colour = "#CC6677") +
  geom_text(aes(label = paste0("n = ", n_label)),
            x = x_hi_txt, hjust = 0, size = 3, colour = "grey25") +
  coord_cartesian(xlim = c(min(forest_df$lo, na.rm = TRUE) - 0.05,
                           x_hi_plot), clip = "off") +
  labs(title    = "Δ Pain (DBS − Never-DBS) by genetic / biomarker stratum",
       subtitle = sprintf(
         paste("Positive = DBS worsens more; negative = DBS improves more.",
               "Interaction P: PRS = %.3f | APOE = %.3f | SAA = %.3f |",
               "GBA = %.3f"),
         res_prs$p_interaction, res_apoe$p_interaction,
         res_saa$p_interaction, res_gba$p_interaction),
       x = "Δ Pain (DBS − Never-DBS)", y = NULL) +
  theme_classic(base_size = 11, base_family = "Helvetica") +
  theme(plot.title    = element_text(face = "bold"),
        plot.subtitle = element_text(colour = "grey35", size = 9),
        axis.text.y   = element_text(size = 10),
        plot.margin   = margin(5.5, 80, 5.5, 5.5))

ggsave(file.path(OUT_FIG, "Figure25_genetics_forest.png"),
       p_forest, width = 9, height = 5.5, dpi = 300)
cat("\n[OK] Forest plot saved\n")
save_object(forest_df, "genetics_forest_data")
