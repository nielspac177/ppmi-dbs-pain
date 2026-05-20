#!/usr/bin/env Rscript
# final_fixes.R
# Fix six issues in the paper figures:
# 1. Network: short labels INSIDE circles
# 2. Love plot: dumbbells per covariate (unmatched -> matched)
# 3. RF importance: relabel to clinical terms
# 4. Radar: smaller font
# 5. Trajectory k-means: add honest stratified-by-baseline-pain comparison
# 6. Figure 15: replace with honest stratified comparison

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(qgraph); library(forcats); library(readr); library(MatchIt); library(fmsb)
})
source("helpers/pain_helpers.R")

# -------------------------------------------------
# (1) Network figure — short labels that fit INSIDE the circles
# -------------------------------------------------
SHORT_LAB <- c(
  NP1PAIN = "Pain", NP1SLPN = "Sleep",  NP1SLPD = "Sleepy",
  NP1FATG = "Fatigue", NP1URIN = "Urinary",
  NP1DPRS = "Depr.", NP1ANXS = "Anx.",
  gds = "GDS", stai = "STAI", ess = "ESS", rem = "RBD",
  scopa = "Auton.", updrs3_score = "Motor", BMI = "BMI", LEDD = "LEDD"
)
P_list <- readRDS(file.path(OUT_OBJ, "partial_correlation_matrices.rds"))
P <- P_list$all
rownames(P) <- colnames(P) <- SHORT_LAB[rownames(P)]

# Larger nodes, smaller labels — labels fit inside
out_png  <- file.path(OUT_FIG, "Figure6_network_labeled.png")
draw_net <- function(file, device_fn) {
  device_fn(file, width = 3000, height = 2400, res = 360)
  par(mar = c(0.5, 0.5, 0.5, 0.5))
  qgraph::qgraph(
    P, layout = "spring", theme = "classic",
    labels = colnames(P), label.cex = 1.0, label.scale = FALSE,
    label.color = "black",
    vsize = 13, esize = 7,
    color = ifelse(colnames(P) == "Pain", "#CC6677", "#D9E3F2"),
    border.color = "grey20", border.width = 1.8,
    edge.labels = FALSE, title = "", fade = TRUE
  )
  invisible(dev.off())
}
draw_net(out_png, png)
cat("[1] Network — short labels inside nodes\n")

# -------------------------------------------------
# (2) Love plot — dumbbells connecting unmatched to matched for each covariate
# -------------------------------------------------
m <- readRDS(file.path(OUT_OBJ, "psm_matchit_fit.rds"))
smd_tbl <- cobalt::bal.tab(m, un = TRUE, binary = "std")$Balance %>%
  tibble::rownames_to_column("covariate")
# Columns: Diff.Un, Diff.Adj (standardized)
VAR_NAME <- c(
  distance     = "Propensity score",
  age_at_visit = "Age at baseline",
  SEX          = "Sex (Male)",
  duration_yrs = "Disease duration",
  updrs3_score = "Motor (UPDRS-III)",
  NHY          = "Hoehn & Yahr",
  LEDD         = "LEDD (mg)",
  BMI          = "Body-mass index"
)
lp <- smd_tbl %>% dplyr::transmute(
  covariate = ifelse(covariate %in% names(VAR_NAME), VAR_NAME[covariate], covariate),
  unmatched = abs(Diff.Un),
  matched   = abs(Diff.Adj)
) %>%
  dplyr::arrange(dplyr::desc(unmatched)) %>%
  dplyr::mutate(covariate = forcats::fct_rev(forcats::fct_inorder(covariate)))

p_love <- ggplot(lp) +
  geom_vline(xintercept = 0.1, linetype = "dashed", colour = "grey50") +
  geom_segment(aes(y = covariate, yend = covariate, x = unmatched, xend = matched),
               colour = "grey70", linewidth = 1.6) +
  geom_point(aes(y = covariate, x = unmatched, colour = "Unmatched"),
             size = 4.5, shape = 17) +
  geom_point(aes(y = covariate, x = matched, colour = "Matched"),
             size = 4.5, shape = 15) +
  scale_colour_manual(values = c("Unmatched" = "#CC6677", "Matched" = "#332288"),
                      name = NULL) +
  scale_x_continuous("Absolute standardized mean difference |SMD|",
                     breaks = seq(0, 1.2, 0.2), limits = c(0, 1.25),
                     expand = expansion(mult = c(0.005, 0.02))) +
  labs(title = "Covariate balance before and after matching",
       subtitle = "Each grey bar links the unmatched |SMD| to the matched |SMD| for one covariate. Dashed line = 0.1 conventional threshold.",
       y = NULL) +
  theme_classic(base_size = 12, base_family = "Helvetica") +
  theme(plot.title = element_text(face = "bold"),
        plot.subtitle = element_text(colour = "grey30"),
        legend.position = "top",
        panel.grid.major.x = element_line(colour = "grey90", linewidth = 0.25))
ggsave(file.path(OUT_FIG, "Figure18_love_plot.png"), p_love, width = 9, height = 5, dpi = 300)
cat("[2] Love plot — dumbbells\n")
save_table(lp, "love_plot_smds")

# -------------------------------------------------
# (3) RF feature importance — labelled
# -------------------------------------------------
LAB <- c(
  age_at_visit="Age at baseline", ageonset="Age at PD onset", duration_yrs="Disease duration (yrs)",
  SEX="Sex (Male)", BMI="BMI", LEDD="LEDD (mg)", NHY="Hoehn & Yahr",
  updrs3_score="Motor (UPDRS-III)", scopa="Autonomic (SCOPA-AUT)",
  NP1DPRS="Depression (NP1DPRS)", NP1ANXS="Anxiety (NP1ANXS)", gds="Depression (GDS)", stai="Anxiety (STAI)",
  pre_mean="Pre-anchor pain mean", pre_max="Pre-anchor pain max",
  pre_sd="Pre-anchor pain variability", pre_last="Pre-anchor pain (last)",
  pre_slope="Pre-anchor pain slope", pre_n="Pre-anchor visit count",
  mean_putamen="Striatal putamen SBR", mean_caudate="Striatal caudate SBR",
  con_putamen="Contralateral putamen SBR",
  asyn="CSF α-synuclein", NFL_CSF="CSF NfL", nfl_serum="Serum NfL",
  abeta="CSF Aβ42", tau="CSF total tau", ptau="CSF p-tau181",
  APOE_e4="APOE ε4 alleles",
  sg_LRRK2="LRRK2 carrier", sg_GBA="GBA carrier", sg_SNCA="SNCA carrier"
)
imp <- read_csv(file.path(OUT_TAB, "rf_importance_patient_anchor.csv"), show_col_types = FALSE) %>%
  dplyr::arrange(dplyr::desc(MeanDecreaseGini)) %>% dplyr::slice_head(n = 15) %>%
  dplyr::mutate(feat_lab = ifelse(feature %in% names(LAB), LAB[feature], feature),
                feat_lab = forcats::fct_reorder(feat_lab, MeanDecreaseGini))
p_imp <- ggplot(imp, aes(MeanDecreaseGini, feat_lab)) +
  geom_col(fill = "#332288", width = 0.75) +
  labs(title = "Top 15 predictors of 18-month pain worsening (Random Forest)",
       subtitle = "Mean decrease in Gini, 5-fold CV",
       x = "Mean decrease in Gini", y = NULL) +
  theme_classic(base_size = 12, base_family = "Helvetica") +
  theme(plot.title = element_text(face = "bold"),
        plot.subtitle = element_text(colour = "grey30"),
        panel.grid.major.x = element_line(colour = "grey90", linewidth = 0.25))

# ROC panel for the prediction figure
dat <- readRDS(file.path(OUT_OBJ, "patient_anchor_features.rds"))
feat_cols <- c("dbs","age_at_visit","ageonset","duration_yrs","SEX","BMI",
               "LEDD","updrs3_score","NHY","NP1DPRS","NP1ANXS","gds","stai","scopa",
               "pre_mean","pre_max","pre_sd","pre_last","pre_slope","pre_n")
median_impute <- function(x){ x[is.na(x)] <- stats::median(x, na.rm=TRUE); x }
X <- dat %>% dplyr::mutate(dbs = as.integer(will_receive_dbs)) %>%
  dplyr::select(dplyr::all_of(feat_cols)) %>%
  dplyr::mutate(dplyr::across(dplyr::everything(), median_impute)) %>% as.matrix()
y <- dat$worsened
suppressPackageStartupMessages({ library(randomForest); library(glmnet); library(pROC); library(patchwork) })
set.seed(42); folds <- sample(rep(1:5, length.out = nrow(X)))
p_rf <- numeric(nrow(X)); p_en <- numeric(nrow(X))
for (k in 1:5) {
  te <- which(folds == k); tr <- setdiff(seq_len(nrow(X)), te)
  set.seed(42)
  mrf <- randomForest::randomForest(x = X[tr,,drop=FALSE], y = factor(y[tr], levels = c(0,1)),
                                    ntree = 500, nodesize = 5)
  p_rf[te] <- as.numeric(predict(mrf, X[te,,drop=FALSE], type = "prob")[,"1"])
  set.seed(42)
  men <- glmnet::cv.glmnet(X[tr,,drop=FALSE], y[tr], family = "binomial", alpha = 0.5, nfolds = 5)
  p_en[te] <- as.numeric(predict(men, newx = X[te,,drop=FALSE], s = "lambda.min", type = "response"))
}
r_rf <- pROC::roc(y, p_rf, quiet = TRUE); auc_rf <- as.numeric(pROC::auc(r_rf))
r_en <- pROC::roc(y, p_en, quiet = TRUE); auc_en <- as.numeric(pROC::auc(r_en))
roc_df <- dplyr::bind_rows(
  tibble::tibble(model = sprintf("Random Forest (AUC=%.2f)", auc_rf), fpr = 1 - r_rf$specificities, tpr = r_rf$sensitivities),
  tibble::tibble(model = sprintf("Elastic Net (AUC=%.2f)", auc_en), fpr = 1 - r_en$specificities, tpr = r_en$sensitivities)
)
p_roc <- ggplot(roc_df, aes(fpr, tpr, colour = model)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey50") +
  geom_path(linewidth = 1) +
  scale_colour_manual(values = c("#CC6677","#117733"), name = NULL) +
  coord_equal() +
  labs(title = "5-fold CV discrimination",
       subtitle = sprintf("Target: 18-mo pain worsening (n = %d)", nrow(X)),
       x = "False positive rate", y = "True positive rate", tag = "A") +
  theme_classic(base_size = 12, base_family = "Helvetica") +
  theme(plot.title = element_text(face = "bold"), plot.tag = element_text(face = "bold", size = 14))
fig6 <- p_roc + (p_imp + labs(tag = "B") + theme(plot.tag = element_text(face = "bold", size = 14))) +
  patchwork::plot_layout(ncol = 2, widths = c(1, 1.15))
ggsave(file.path(OUT_FIG, "Figure6_prediction.png"), fig6, width = 12.5, height = 5.2, dpi = 300)
cat("[3] RF feature importance — relabeled + re-assembled prediction figure\n")

# -------------------------------------------------
# (4) Radar — smaller font, shorter labels
# -------------------------------------------------
SHORT_RADAR <- c(
  age_at_visit="Age", duration_yrs="Duration", BMI="BMI",
  updrs3_score="UPDRS-III", NHY="H&Y", LEDD="LEDD",
  scopa="Auton.", gds="GDS", stai="STAI", ess="ESS", rem="RBD",
  pre_mean="Pre-pain μ", pre_sd="Pre-pain SD", pre_slope="Pre-pain slope",
  mean_putamen="Putamen SBR", asyn="α-syn", NFL_CSF="NfL", abeta="Aβ42"
)
# Reuse the data from make_radar_figs.R
enriched <- readRDS(file.path(OUT_OBJ, "patient_anchor_features_clustered.rds"))
feat_cols_r <- names(SHORT_RADAR)
feat_cols_r <- intersect(feat_cols_r, names(enriched))
zcols <- enriched %>% dplyr::select(dplyr::all_of(feat_cols_r)) %>%
  dplyr::mutate(dplyr::across(dplyr::everything(),
                              ~ (as.numeric(.x) - mean(as.numeric(.x), na.rm=TRUE)) /
                                  stats::sd(as.numeric(.x), na.rm=TRUE)))
med_by_cluster <- dplyr::bind_cols(enriched %>% dplyr::select(cluster_base), zcols) %>%
  dplyr::group_by(cluster_base) %>%
  dplyr::summarise(dplyr::across(dplyr::everything(), ~ stats::median(.x, na.rm=TRUE)),
                   .groups = "drop")
rng <- 2.5
fmsb_df <- rbind(
  rep(rng, length(feat_cols_r)),
  rep(-rng, length(feat_cols_r)),
  as.matrix(med_by_cluster %>% dplyr::select(-cluster_base))
)
rownames(fmsb_df) <- c("max","min", paste0("Cluster ", med_by_cluster$cluster_base))
colnames(fmsb_df) <- SHORT_RADAR[colnames(fmsb_df)]
n_df <- enriched %>% dplyr::count(cluster_base)
lab1 <- sprintf("Cluster 1 — Low burden (n=%d)", n_df$n[n_df$cluster_base==1])
lab2 <- sprintf("Cluster 2 — High burden (n=%d)", n_df$n[n_df$cluster_base==2])
cols_r <- c("#117733", "#CC6677")
png(file.path(OUT_FIG, "Figure19_baseline_cluster_radar.png"),
    width = 2200, height = 2000, res = 300)
par(mar = c(1.5, 1.5, 2.2, 1.5))
fmsb::radarchart(
  as.data.frame(fmsb_df),
  axistype = 1,
  pcol  = cols_r, pfcol = paste0(cols_r, "33"),
  plwd  = 2.4, plty = 1,
  cglcol = "grey75", cglty = 1, cglwd = 0.7,
  axislabcol = "grey40",
  vlcex = 0.78,
  caxislabels = c("−2.5","","0","","+2.5"),
  title = "Baseline k-means clusters — z-scored profile"
)
legend("topright", legend = c(lab1, lab2), col = cols_r, lwd = 3, bty = "n", cex = 0.75)
invisible(dev.off())
cat("[4] Radar — smaller font\n")

# -------------------------------------------------
# (5) & (6) Honest stratified-by-baseline-pain Figure (replaces old Figure 15)
# -------------------------------------------------
enr <- readRDS(file.path(OUT_OBJ, "patient_anchor_features.rds"))
enr <- enr %>% dplyr::mutate(
  arm = dplyr::if_else(will_receive_dbs, "DBS", "Never-DBS"),
  pain_stratum = dplyr::case_when(
    pre_mean >= 2 ~ "High pre-anchor pain (≥ 2)",
    pre_mean >= 1 ~ "Moderate (1–<2)",
    TRUE          ~ "Low (<1)"
  ),
  pain_stratum = factor(pain_stratum, levels = c("Low (<1)", "Moderate (1–<2)", "High pre-anchor pain (≥ 2)"))
)
summ <- enr %>% dplyr::group_by(pain_stratum, arm) %>%
  dplyr::summarise(n = dplyr::n(),
                   mean_delta = mean(delta, na.rm=TRUE),
                   se = stats::sd(delta, na.rm=TRUE) / sqrt(n),
                   .groups = "drop") %>%
  dplyr::mutate(lo = mean_delta - 1.96 * se, hi = mean_delta + 1.96 * se)
print(summ)
save_table(summ, "delta_by_baseline_pain_stratum")

# Within-stratum Welch test for the DBS−Never difference
within_test <- purrr::map_dfr(levels(enr$pain_stratum), function(s) {
  sub <- enr %>% dplyr::filter(pain_stratum == s)
  if (sum(sub$will_receive_dbs) < 5 || sum(!sub$will_receive_dbs) < 5)
    return(tibble::tibble(pain_stratum = s, diff = NA, lo = NA, hi = NA, p = NA))
  tt <- stats::t.test(delta ~ will_receive_dbs, data = sub)
  tibble::tibble(pain_stratum = s,
                 diff = -diff(tt$estimate),
                 lo = -tt$conf.int[2], hi = -tt$conf.int[1],
                 p = tt$p.value)
})
print(within_test)
save_table(within_test, "delta_stratum_welch")

p_strat <- ggplot(summ, aes(pain_stratum, mean_delta, fill = arm)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey40") +
  geom_col(position = position_dodge(0.75), width = 0.65) +
  geom_errorbar(aes(ymin = lo, ymax = hi), position = position_dodge(0.75), width = 0.2, linewidth = 0.5) +
  geom_text(aes(label = sprintf("Δ=%.2f\nn=%d", mean_delta, n)),
            position = position_dodge(0.75),
            vjust = ifelse(summ$mean_delta >= 0, -0.4, 1.2),
            size = 3) +
  scale_fill_manual(values = c(`DBS`="#CC6677", `Never-DBS`="#332288"), name = NULL) +
  labs(title = "Δ pain by baseline-pain stratum and DBS arm",
       subtitle = "Both arms show regression-to-the-mean (RTM) patterns: high-pain patients improve in BOTH arms.\nNo stratum shows a statistically significant DBS benefit (all within-stratum p ≥ 0.31).",
       x = NULL, y = "Mean Δ pain (post − pre, 95% CI)") +
  theme_classic(base_size = 12, base_family = "Helvetica") +
  theme(plot.title = element_text(face = "bold"),
        plot.subtitle = element_text(colour = "grey30"),
        legend.position = "top")
ggsave(file.path(OUT_FIG, "Figure17b_traj_cluster_delta.png"), p_strat, width = 9.5, height = 5.2, dpi = 300)
cat("[5/6] Stratified honest Δ figure replaces old Figure 15\n")

cat("\nAll six fixes complete.\n")
