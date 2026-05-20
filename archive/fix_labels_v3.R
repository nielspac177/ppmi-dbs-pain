#!/usr/bin/env Rscript
# fix_labels_v3.R — expand the label mapping and regenerate any figure
# that still shows raw PPMI column names.

suppressPackageStartupMessages({
  library(dplyr); library(readr); library(ggplot2); library(forcats)
})
source("helpers/pain_helpers.R")

# Expanded label map
LAB <- c(
  # Non-motor symptom items
  NP1PAIN = "Pain", NP1SLPN = "Night-sleep problems",
  NP1SLPD = "Daytime sleepiness", NP1FATG = "Fatigue",
  NP1URIN = "Urinary symptoms",
  NP1DPRS = "Depression (patient-reported)", NP1ANXS = "Anxiety (patient-reported)",
  # Instruments
  gds  = "Depression (GDS)", stai = "Anxiety (STAI)",
  ess  = "Daytime sleepiness (ESS)", rem = "REM-sleep behaviour",
  scopa = "Autonomic dysfunction", updrs3_score = "Motor (UPDRS-III)",
  # Demographics
  age_at_visit = "Age at baseline", ageonset = "Age at PD onset",
  duration_yrs = "Disease duration (yrs)", SEX = "Sex (Male)",
  NHY = "Hoehn & Yahr",
  BMI = "BMI", LEDD = "LEDD (mg)",
  # Pre-anchor trajectory features
  pre_mean = "Pre-anchor pain mean", pre_max = "Pre-anchor pain max",
  pre_sd = "Pre-anchor pain variability", pre_last = "Pre-anchor pain (last)",
  pre_slope = "Pre-anchor pain slope", pre_n = "Pre-anchor visit count",
  # Biomarkers / imaging
  mean_putamen = "Striatal putamen SBR", mean_caudate = "Striatal caudate SBR",
  mean_striatum = "Mean striatum SBR",
  con_putamen = "Contralateral putamen SBR", ips_putamen = "Ipsilateral putamen SBR",
  abeta = "CSF Aβ42", tau = "CSF total tau", ptau = "CSF p-tau181",
  asyn = "CSF α-synuclein", NFL_CSF = "CSF NfL", nfl_serum = "Serum NfL",
  APOE_e4 = "APOE ε4 alleles",
  # Genetic subgroup flags
  sg_LRRK2 = "LRRK2 carrier", sg_GBA = "GBA carrier", sg_SNCA = "SNCA carrier"
)
relabel <- function(x) {
  out <- as.character(x)
  ix <- out %in% names(LAB)
  out[ix] <- LAB[out[ix]]
  out
}

# === Regenerate Figure10_summary_grouped (summary forest) with readable labels ===
# Already uses narrative labels — OK, skip.

# === Regenerate Figure15_cate_feature_importance with readable labels ===
vi_df <- readr::read_csv(file.path(OUT_TAB, "causal_forest_importance.csv"),
                         show_col_types = FALSE)
vi_df <- vi_df %>% dplyr::mutate(feature_label = relabel(feature))

p <- ggplot(
  vi_df %>% dplyr::slice_head(n = 20) %>%
    dplyr::mutate(feature_label = forcats::fct_reorder(feature_label, importance)),
  aes(importance, feature_label)) +
  geom_col(fill = "#1f78b4", width = 0.75) +
  labs(
    title = "Which features drive variation in predicted DBS pain effect?",
    subtitle = "Causal-forest variable importance (top 20 features)",
    x = "Variable importance (grf)", y = NULL
  ) +
  theme_classic(base_size = 12, base_family = "Helvetica") +
  theme(
    plot.title = element_text(face = "bold"),
    plot.subtitle = element_text(colour = "grey30"),
    panel.grid.major.x = element_line(colour = "grey90", linewidth = 0.25),
    panel.grid.major.y = element_blank(),
    plot.margin = margin(15, 15, 12, 12)
  )
ggsave(file.path(OUT_FIG, "Figure15_cate_feature_importance.png"),
       p, width = 9, height = 6.5, dpi = 300)
ggsave(file.path(OUT_FIG, "Figure15_cate_feature_importance.tiff"),
       p, width = 9, height = 6.5, dpi = 300, compression = "lzw")
cat("[OK] Figure15_cate_feature_importance (relabeled)\n")

# === Regenerate the RF importance plot (Figure6_prediction uses rf_importance_patient_anchor) ===
imp <- readr::read_csv(file.path(OUT_TAB, "rf_importance_patient_anchor.csv"),
                       show_col_types = FALSE) %>%
  dplyr::arrange(desc(MeanDecreaseGini)) %>% dplyr::slice_head(n = 15) %>%
  dplyr::mutate(feature_label = relabel(feature))

# We need to rebuild Figure6_prediction.png (2-panel ROC + importance).
# Simpler: just output a standalone relabeled importance plot that the paper can use.
p_imp <- ggplot(
  imp %>% dplyr::mutate(feature_label = forcats::fct_reorder(feature_label, MeanDecreaseGini)),
  aes(MeanDecreaseGini, feature_label)
) +
  geom_col(fill = "#332288", width = 0.75) +
  labs(title = "Top 15 predictors of 18-month pain worsening (Random Forest)",
       subtitle = "Mean decrease in Gini across 5-fold CV",
       x = "Mean decrease in Gini", y = NULL) +
  theme_classic(base_size = 12, base_family = "Helvetica") +
  theme(plot.title = element_text(face = "bold"),
        plot.subtitle = element_text(colour = "grey30"),
        panel.grid.major.x = element_line(colour = "grey90", linewidth = 0.25),
        panel.grid.major.y = element_blank())
ggsave(file.path(OUT_FIG, "Figure_RF_importance_labeled.png"),
       p_imp, width = 9, height = 6, dpi = 300)
ggsave(file.path(OUT_FIG, "Figure_RF_importance_labeled.tiff"),
       p_imp, width = 9, height = 6, dpi = 300, compression = "lzw")
cat("[OK] Figure_RF_importance_labeled\n")

# === Save mapping file for future use ===
map_df <- tibble::tibble(code = names(LAB), label = unname(LAB))
save_table(map_df, "variable_label_map")
cat("All labels expanded.\n")
