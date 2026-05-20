#!/usr/bin/env Rscript
# make_radar_figs.R
# Standard cluster-characterisation radar plots (fmsb), using z-scored medians.

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(fmsb); library(readr)
})
source("helpers/pain_helpers.R")

LAB <- c(
  age_at_visit = "Age", duration_yrs = "Disease duration",
  BMI = "BMI", updrs3_score = "Motor (UPDRS-III)", NHY = "H&Y stage",
  LEDD = "LEDD", scopa = "Autonomic", gds = "Depression (GDS)",
  stai = "Anxiety (STAI)", ess = "Daytime sleepiness",
  rem = "RBD score",
  pre_mean = "Pre-anchor pain mean", pre_max = "Pre-anchor pain max",
  pre_sd = "Pre-anchor pain SD", pre_slope = "Pre-anchor pain slope",
  mean_putamen = "Putamen SBR", mean_caudate = "Caudate SBR",
  asyn = "CSF α-syn", NFL_CSF = "CSF NfL", abeta = "CSF Aβ42",
  ageonset = "Age at onset"
)

# -----------------------------------------------------------
# Radar 1 — baseline k-means (K=2) clusters from notebook 22
# -----------------------------------------------------------
enriched <- readRDS(file.path(OUT_OBJ, "patient_anchor_features_clustered.rds"))
feat_cols <- c("age_at_visit","duration_yrs","BMI","updrs3_score","NHY","LEDD",
               "scopa","gds","stai","ess","rem",
               "pre_mean","pre_sd","pre_slope",
               "mean_putamen","asyn","abeta","NFL_CSF")
feat_cols <- intersect(feat_cols, names(enriched))

# Z-score each feature on the whole cohort, then take median per cluster
zcols <- enriched %>% dplyr::select(dplyr::all_of(feat_cols)) %>%
  dplyr::mutate(dplyr::across(dplyr::everything(),
                              ~ (as.numeric(.x) - mean(as.numeric(.x), na.rm=TRUE)) /
                                  stats::sd(as.numeric(.x), na.rm=TRUE)))
zdf <- dplyr::bind_cols(
  enriched %>% dplyr::select(cluster_base),
  zcols
)
med_by_cluster <- zdf %>% dplyr::group_by(cluster_base) %>%
  dplyr::summarise(dplyr::across(dplyr::everything(), ~ stats::median(.x, na.rm=TRUE)),
                   .groups = "drop")
print(med_by_cluster)

# Scale for radar: rows must include max and min first
rng <- 2.5  # z-score range to display
fmsb_df <- rbind(
  rep( rng, length(feat_cols)),
  rep(-rng, length(feat_cols)),
  as.matrix(med_by_cluster %>% dplyr::select(-cluster_base))
)
rownames(fmsb_df) <- c("max","min", paste0("Cluster ", med_by_cluster$cluster_base))
colnames(fmsb_df) <- ifelse(colnames(fmsb_df) %in% names(LAB),
                            LAB[colnames(fmsb_df)], colnames(fmsb_df))

# Choose colours (Cluster 1 = low burden in notebook 22, Cluster 2 = high burden)
n_df <- enriched %>% dplyr::count(cluster_base)
lab1 <- sprintf("Cluster 1 — Low burden (n=%d)", n_df$n[n_df$cluster_base==1])
lab2 <- sprintf("Cluster 2 — High burden (n=%d)", n_df$n[n_df$cluster_base==2])
cols <- c("#117733", "#CC6677")

png(file.path(OUT_FIG, "Figure19_baseline_cluster_radar.png"),
    width = 2200, height = 2000, res = 300)
par(mar = c(2, 2, 3, 2))
fmsb::radarchart(
  as.data.frame(fmsb_df),
  axistype = 1,
  pcol  = cols,
  pfcol = paste0(cols, "33"),
  plwd  = 2.4, plty = 1,
  cglcol = "grey70", cglty = 1, cglwd = 0.8,
  axislabcol = "grey40",
  vlcex = 0.95,
  caxislabels = c("−2.5","−1.25","0","+1.25","+2.5"),
  title = "Baseline k-means clusters — z-scored profile"
)
legend("topright", legend = c(lab1, lab2), col = cols, lwd = 3, bty = "n", cex = 0.85)
invisible(dev.off())
tiff(file.path(OUT_FIG, "Figure19_baseline_cluster_radar.tiff"),
     width = 2200, height = 2000, res = 300, compression = "lzw")
par(mar = c(2, 2, 3, 2))
fmsb::radarchart(
  as.data.frame(fmsb_df),
  axistype = 1,
  pcol  = cols,
  pfcol = paste0(cols, "33"),
  plwd  = 2.4, plty = 1,
  cglcol = "grey70", cglty = 1, cglwd = 0.8,
  axislabcol = "grey40",
  vlcex = 0.95,
  caxislabels = c("−2.5","−1.25","0","+1.25","+2.5"),
  title = "Baseline k-means clusters — z-scored profile"
)
legend("topright", legend = c(lab1, lab2), col = cols, lwd = 3, bty = "n", cex = 0.85)
invisible(dev.off())
cat("[OK] Figure19_baseline_cluster_radar\n")

# -----------------------------------------------------------
# Radar 2 — longitudinal trajectory clusters characterised by same baseline features
# (need to project cluster membership onto the enriched baseline)
# -----------------------------------------------------------
traj_dat <- readRDS(file.path(OUT_OBJ, "trajectory_cluster_membership.rds")) %>%
  dplyr::select(PATNO, traj_cluster)
tmp <- enriched %>% dplyr::inner_join(traj_dat, by = "PATNO")
cat("Patients with trajectory cluster AND baseline features:", nrow(tmp), "\n")

# Determine low vs high centroid (same logic as earlier) — use pre_mean
avg <- tmp %>% dplyr::group_by(traj_cluster) %>%
  dplyr::summarise(m = mean(pre_mean, na.rm = TRUE))
low_cl <- avg$traj_cluster[which.min(avg$m)]
tmp <- tmp %>% dplyr::mutate(traj_grp = dplyr::if_else(traj_cluster == low_cl, "Low-pain trajectory", "High/rising-pain trajectory"))

zcols_t <- tmp %>% dplyr::select(dplyr::all_of(feat_cols)) %>%
  dplyr::mutate(dplyr::across(dplyr::everything(),
                              ~ (as.numeric(.x) - mean(as.numeric(.x), na.rm=TRUE)) /
                                  stats::sd(as.numeric(.x), na.rm=TRUE)))
med_t <- dplyr::bind_cols(tmp %>% dplyr::select(traj_grp), zcols_t) %>%
  dplyr::group_by(traj_grp) %>%
  dplyr::summarise(dplyr::across(dplyr::everything(), ~ stats::median(.x, na.rm=TRUE)), .groups="drop")
print(med_t)

fmsb_t <- rbind(
  rep( rng, length(feat_cols)),
  rep(-rng, length(feat_cols)),
  as.matrix(med_t %>% dplyr::select(-traj_grp))
)
rownames(fmsb_t) <- c("max","min", med_t$traj_grp)
colnames(fmsb_t) <- ifelse(colnames(fmsb_t) %in% names(LAB), LAB[colnames(fmsb_t)], colnames(fmsb_t))
sizes_t <- tmp %>% dplyr::count(traj_grp)
lab_a <- sprintf("%s (n=%d)", sizes_t$traj_grp[1], sizes_t$n[1])
lab_b <- sprintf("%s (n=%d)", sizes_t$traj_grp[2], sizes_t$n[2])

png(file.path(OUT_FIG, "Figure20_traj_cluster_radar.png"),
    width = 2200, height = 2000, res = 300)
par(mar = c(2, 2, 3, 2))
fmsb::radarchart(
  as.data.frame(fmsb_t),
  axistype = 1,
  pcol  = cols, pfcol = paste0(cols, "33"),
  plwd  = 2.4, plty = 1,
  cglcol = "grey70", cglty = 1, cglwd = 0.8,
  axislabcol = "grey40", vlcex = 0.95,
  caxislabels = c("−2.5","−1.25","0","+1.25","+2.5"),
  title = "Longitudinal trajectory clusters — z-scored baseline profile"
)
legend("topright", legend = c(lab_a, lab_b), col = cols, lwd = 3, bty = "n", cex = 0.85)
invisible(dev.off())
tiff(file.path(OUT_FIG, "Figure20_traj_cluster_radar.tiff"),
     width = 2200, height = 2000, res = 300, compression = "lzw")
par(mar = c(2, 2, 3, 2))
fmsb::radarchart(
  as.data.frame(fmsb_t),
  axistype = 1,
  pcol  = cols, pfcol = paste0(cols, "33"),
  plwd  = 2.4, plty = 1,
  cglcol = "grey70", cglty = 1, cglwd = 0.8,
  axislabcol = "grey40", vlcex = 0.95,
  caxislabels = c("−2.5","−1.25","0","+1.25","+2.5"),
  title = "Longitudinal trajectory clusters — z-scored baseline profile"
)
legend("topright", legend = c(lab_a, lab_b), col = cols, lwd = 3, bty = "n", cex = 0.85)
invisible(dev.off())
cat("[OK] Figure20_traj_cluster_radar\n")

# -----------------------------------------------------------
# Also produce a heatmap as an alternative (some journals prefer)
# -----------------------------------------------------------
suppressPackageStartupMessages({ library(ggplot2) })
hm_df <- med_by_cluster %>% tidyr::pivot_longer(-cluster_base, names_to = "var", values_to = "z") %>%
  dplyr::mutate(var_lab = ifelse(var %in% names(LAB), LAB[var], var),
                cluster = paste0("Cluster ", cluster_base))
p_hm <- ggplot(hm_df, aes(cluster, var_lab, fill = z)) +
  geom_tile(colour = "white", linewidth = 0.3) +
  geom_text(aes(label = sprintf("%+.2f", z)), size = 3.2) +
  scale_fill_gradient2(low = "#117733", mid = "white", high = "#CC6677",
                       midpoint = 0, limits = c(-1.5, 1.5), oob = scales::squish,
                       name = "Z-score vs\nwhole cohort") +
  labs(title = "Baseline k-means cluster z-score profile (heatmap)",
       subtitle = "Red = above cohort mean, Green = below cohort mean",
       x = NULL, y = NULL) +
  theme_classic(base_size = 11) +
  theme(plot.title = element_text(face="bold"), axis.ticks = element_blank())
ggsave(file.path(OUT_FIG, "Figure19b_baseline_cluster_heatmap.png"),
       p_hm, width = 6.5, height = 6.5, dpi = 300)
cat("[OK] Figure19b heatmap\n")
