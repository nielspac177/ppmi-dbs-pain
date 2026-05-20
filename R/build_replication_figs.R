#!/usr/bin/env Rscript
# build_replication_figs.R
# Replicates the Google-Doc prior-paper figures/tables for the v2 dataset:
#   1) STROBE flow chart
#   2) Pain-level stacked-bar distribution across 6-mo bins (-54 .. +60)
#   3) Mean pain trajectory DBS vs Never-DBS
#   4) Spaghetti trajectories by baseline pain stratum (Decreasing/Flat/Increasing)
#   5) Cross-sectional DBS forest plot (weighted regression)
#   6) Sex x DBS and BMI x DBS interaction panels
#   7) Supplementary wide-window Figure S5 (LMM, 0-60 months)

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(patchwork)
  library(forcats); library(scales); library(lme4); library(lmerTest)
  library(emmeans); library(readr); library(tibble)
})
source("helpers/pain_helpers.R")

# =========================================================
# Data loading
# =========================================================
rel <- load_full_ppmi_rel_patient_anchor()
cat("Full cohort rows:", nrow(rel),
    " Patients:", dplyr::n_distinct(rel$PATNO), "\n")

# Patient-level pivot for descriptives (one row per PATNO)
per_patient <- rel %>%
  dplyr::distinct(PATNO, will_receive_dbs, subgroup)

n_dbs    <- sum(per_patient$will_receive_dbs,  na.rm = TRUE)
n_no_dbs <- sum(!per_patient$will_receive_dbs, na.rm = TRUE)
n_total  <- nrow(per_patient)
n_monogenic <- sum(per_patient$subgroup != "Sporadic PD", na.rm = TRUE)

cat(sprintf("Total = %d  DBS = %d  Never-DBS = %d  Monogenic = %d\n",
            n_total, n_dbs, n_no_dbs, n_monogenic))

# =========================================================
# 1) STROBE flow chart (ggplot boxes + arrows)
# =========================================================
strobe_box <- function(x, y, w, h, label, fill = "#F2F2F2", col = "grey35") {
  tibble(
    x = x, y = y, w = w, h = h, label = label, fill = fill, col = col
  )
}

# Rough placeholder N for "at baseline" and "with confirmed PD"
# (matches the earlier paper's format; if your PPMI release used different
#  intake numbers, edit these three constants)
n_baseline  <- 3164
n_confirmed <- n_total + n_monogenic            # confirmed PD
n_included  <- n_total

strobe_df <- dplyr::bind_rows(
  strobe_box(0, 4.5, 2.0, 0.9, sprintf("%d patients at baseline", n_baseline)),
  strobe_box(0, 3.0, 2.0, 0.9, sprintf("%d patients with\nconfirmed PD",
                                       n_confirmed)),
  strobe_box(0, 1.5, 2.0, 0.9, sprintf("%d patients included", n_included)),
  strobe_box(-1.6, 0.0, 1.6, 0.9, sprintf("%d patients\nwithout DBS", n_no_dbs),
             fill = "#E8ECF5"),
  strobe_box( 0.0, 0.0, 1.6, 0.9, "Inverse probability\nweighting",
             fill = "#EEEEEE"),
  strobe_box( 1.6, 0.0, 1.6, 0.9, sprintf("%d patients\nwith DBS", n_dbs),
             fill = "#F5E3DC"),
  strobe_box(3.6, 4.5, 2.2, 0.9,
             sprintf("Excluded: %d patients\nwithout confirmed PD",
                     n_baseline - n_confirmed),
             fill = "#F9F5E1"),
  strobe_box(3.6, 3.0, 2.2, 0.9,
             sprintf("Excluded: %d patients\nwith monogenic variants",
                     n_monogenic),
             fill = "#F9F5E1")
)

strobe_arrows <- tibble(
  x    = c(0,   0,   0,     0,    0,    2.0,  2.0),
  xend = c(0,   0,  -1.6,  0,    1.6,  3.6,  3.6),
  y    = c(4.0, 2.5, 1.0,  1.0,  1.0,  4.5,  3.0),
  yend = c(3.5, 2.0, 0.45, 0.45, 0.45, 4.5,  3.0)
)

p_strobe <- ggplot() +
  geom_tile(data = strobe_df,
            aes(x, y, width = w, height = h, fill = I(fill)),
            colour = "grey35", linewidth = 0.4) +
  geom_text(data = strobe_df, aes(x, y, label = label),
            size = 3.2, lineheight = 0.95) +
  geom_segment(data = strobe_arrows,
               aes(x = x, xend = xend, y = y, yend = yend),
               arrow = arrow(length = unit(0.12, "inches")),
               colour = "grey35") +
  scale_x_continuous(limits = c(-2.6, 5.0)) +
  scale_y_continuous(limits = c(-0.6, 5.1)) +
  labs(title = "Figure 1. STROBE flow diagram of patient selection",
       subtitle = sprintf(
         "%d included after excluding %d patients with monogenic variants",
         n_included, n_monogenic),
       x = NULL, y = NULL) +
  theme_void(base_size = 11) +
  theme(plot.title    = element_text(face = "bold", size = 12),
        plot.subtitle = element_text(colour = "grey35"),
        plot.margin   = ggplot2::margin(10, 10, 10, 10))

ggsave(file.path(OUT_FIG, "Figure1_STROBE.png"), p_strobe,
       width = 8.5, height = 5.2, dpi = 300)
cat("[1] STROBE saved\n")

# =========================================================
# 2) Pain-level stacked bar across 6-mo bins (-54..+60)
# =========================================================
pain_levels <- c("0 None", "1 Mild", "2 Moderate", "3 Severe", "4 Very severe")
pain_fill <- c("0 None" = "#EAF2FA", "1 Mild" = "#CFE1F2",
               "2 Moderate" = "#9FC5E8", "3 Severe" = "#6FA8DC",
               "4 Very severe" = "#1E62A1")

pain_dist <- rel %>%
  dplyr::mutate(month_bin = floor(time_months / 6) * 6) %>%
  dplyr::filter(month_bin >= -54, month_bin <= 60, !is.na(NP1PAIN)) %>%
  dplyr::mutate(level = dplyr::case_when(
    NP1PAIN == 0 ~ "0 None",
    NP1PAIN == 1 ~ "1 Mild",
    NP1PAIN == 2 ~ "2 Moderate",
    NP1PAIN == 3 ~ "3 Severe",
    NP1PAIN >= 4 ~ "4 Very severe"
  )) %>%
  dplyr::group_by(month_bin, level) %>%
  dplyr::summarise(n = dplyr::n(), .groups = "drop") %>%
  dplyr::group_by(month_bin) %>%
  dplyr::mutate(N = sum(n), prop = n / N) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(level = factor(level, levels = pain_levels))

labels_top <- pain_dist %>%
  dplyr::group_by(month_bin) %>%
  dplyr::summarise(N = unique(N), .groups = "drop")

p_dist <- ggplot(pain_dist, aes(factor(month_bin), prop, fill = level)) +
  geom_col(width = 0.88, colour = "grey60", linewidth = 0.12) +
  geom_text(data = labels_top, inherit.aes = FALSE,
            aes(x = factor(month_bin), y = 1.02, label = sprintf("n=%d", N)),
            size = 2.6, colour = "grey35") +
  scale_fill_manual(values = pain_fill, name = "Pain level") +
  scale_y_continuous("Proportion", labels = scales::percent_format(accuracy = 1),
                     limits = c(0, 1.06),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(title = "Figure 3. Distribution of pain levels across time bins",
       subtitle = "All included patients, 6-month bins from -54 to +60 months relative to anchor",
       x = "Months from anchor") +
  theme_classic(base_size = 11, base_family = "Helvetica") +
  theme(plot.title    = element_text(face = "bold"),
        plot.subtitle = element_text(colour = "grey35"),
        legend.position = "right",
        panel.grid.major.y = element_line(colour = "grey92",
                                          linewidth = 0.2))
ggsave(file.path(OUT_FIG, "Figure3_pain_level_distribution.png"),
       p_dist, width = 12, height = 4.5, dpi = 300)
cat("[2] Pain-level distribution saved\n")

# =========================================================
# 3) Mean pain trajectory over time, DBS vs Never-DBS
# =========================================================
mean_traj <- rel %>%
  dplyr::mutate(month_bin = floor(time_months / 6) * 6) %>%
  dplyr::filter(month_bin >= -54, month_bin <= 60, !is.na(NP1PAIN)) %>%
  dplyr::mutate(arm = dplyr::if_else(will_receive_dbs, "DBS", "Never-DBS")) %>%
  dplyr::group_by(arm, month_bin) %>%
  dplyr::summarise(n = dplyr::n(),
                   m = mean(NP1PAIN, na.rm = TRUE),
                   se = stats::sd(NP1PAIN, na.rm = TRUE) / sqrt(n),
                   .groups = "drop")

p_mean <- ggplot(mean_traj, aes(month_bin, m, colour = arm, fill = arm)) +
  annotate("rect", xmin = -3, xmax = 0, ymin = -Inf, ymax = Inf,
           alpha = 0.07, fill = "grey50") +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey50") +
  geom_errorbar(aes(ymin = m - 1.96 * se, ymax = m + 1.96 * se),
                width = 1.5, linewidth = 0.4) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_colour_manual(values = c("DBS" = "#d95f02", "Never-DBS" = "#7570b3"),
                      name = NULL) +
  scale_fill_manual(values = c("DBS" = "#d95f02", "Never-DBS" = "#7570b3"),
                    guide = "none") +
  scale_x_continuous("Months from anchor",
                     breaks = seq(-54, 60, 12)) +
  scale_y_continuous("Pain score (mean, 95% CI)",
                     limits = c(0, 3)) +
  labs(title = "Figure 4. Average pain trajectories by DBS arm",
       subtitle = "Time 0 = first DBS date (DBS) or first visit (Never-DBS). 6-month bins.") +
  theme_classic(base_size = 11, base_family = "Helvetica") +
  theme(plot.title    = element_text(face = "bold"),
        plot.subtitle = element_text(colour = "grey35"),
        legend.position = "top",
        panel.grid.major = element_line(colour = "grey92",
                                        linewidth = 0.2))
ggsave(file.path(OUT_FIG, "Figure4_mean_trajectory_by_arm.png"),
       p_mean, width = 10, height = 4.4, dpi = 300)
cat("[3] Mean trajectory saved\n")

# =========================================================
# 4) Spaghetti trajectories by baseline pain stratum + direction
# =========================================================
baseline <- rel %>%
  dplyr::filter(time_months >= -18, time_months <= 0, !is.na(NP1PAIN)) %>%
  dplyr::group_by(PATNO) %>%
  dplyr::arrange(time_months) %>%
  dplyr::summarise(baseline_pain = dplyr::first(NP1PAIN),
                   .groups = "drop")

slopes_pt <- rel %>%
  dplyr::filter(!is.na(NP1PAIN)) %>%
  dplyr::group_by(PATNO, will_receive_dbs) %>%
  dplyr::filter(dplyr::n() >= 3) %>%
  dplyr::summarise(
    slope = stats::coef(stats::lm(NP1PAIN ~ time_months))[2],
    .groups = "drop"
  ) %>%
  dplyr::mutate(direction = dplyr::case_when(
    slope >=  0.01 ~ "Increasing",
    slope <= -0.01 ~ "Decreasing",
    TRUE           ~ "Flat"
  ))

spag_dat <- rel %>%
  dplyr::filter(!is.na(NP1PAIN)) %>%
  dplyr::inner_join(baseline, by = "PATNO") %>%
  dplyr::inner_join(slopes_pt %>% dplyr::select(PATNO, direction),
                    by = "PATNO") %>%
  dplyr::filter(baseline_pain %in% 0:4,
                time_months >= -24, time_months <= 36) %>%
  dplyr::mutate(arm = dplyr::if_else(will_receive_dbs, "DBS", "Never-DBS"),
                direction = factor(direction,
                                   levels = c("Decreasing", "Flat",
                                              "Increasing")),
                baseline_lab = factor(sprintf("Baseline pain = %d",
                                              baseline_pain),
                                      levels = sprintf("Baseline pain = %d",
                                                       0:4)))

make_spag <- function(arm_val) {
  sub <- spag_dat %>% dplyr::filter(arm == arm_val)
  n_pat <- dplyr::n_distinct(sub$PATNO)
  pct <- sub %>% dplyr::distinct(PATNO, direction) %>%
    dplyr::count(direction) %>%
    dplyr::mutate(pct = round(100 * n / sum(n)))
  pct_lab <- setNames(sprintf("%s (%d%%)", pct$direction, pct$pct),
                      as.character(pct$direction))

  sub <- sub %>% dplyr::mutate(
    direction_lab = factor(pct_lab[as.character(direction)],
                           levels = pct_lab[levels(direction)])
  )

  ggplot(sub, aes(time_months, NP1PAIN, group = PATNO,
                  colour = direction)) +
    annotate("rect", xmin = -6, xmax = 0, ymin = -Inf, ymax = Inf,
             alpha = 0.12, fill = "grey70") +
    geom_vline(xintercept = 0, linetype = "dashed",
               colour = "grey50", linewidth = 0.3) +
    geom_line(alpha = 0.55, linewidth = 0.4) +
    geom_point(alpha = 0.6, size = 0.8) +
    facet_grid(baseline_lab ~ direction_lab, switch = "y") +
    scale_colour_manual(values = c("Decreasing" = "#1b9e77",
                                   "Flat"       = "#7f7f7f",
                                   "Increasing" = "#d95f02"),
                        guide = "none") +
    scale_x_continuous("Months", breaks = seq(-24, 36, 12)) +
    scale_y_continuous("Pain score",
                       breaks = 0:4, limits = c(-0.3, 4.3)) +
    labs(title = sprintf("Trajectories of %s patients (n = %d)",
                         arm_val, n_pat)) +
    theme_bw(base_size = 10, base_family = "Helvetica") +
    theme(plot.title = element_text(face = "bold"),
          panel.grid.minor = element_blank(),
          strip.background = element_rect(fill = "grey94", colour = NA),
          strip.text = element_text(face = "bold"))
}

p_spag_dbs   <- make_spag("DBS")
p_spag_never <- make_spag("Never-DBS")

ggsave(file.path(OUT_FIG, "Figure3A_spaghetti_DBS.png"),
       p_spag_dbs, width = 9, height = 9, dpi = 300)
ggsave(file.path(OUT_FIG, "Figure3B_spaghetti_Never-DBS.png"),
       p_spag_never, width = 9, height = 9, dpi = 300)
cat("[4] Spaghetti plots saved\n")

# =========================================================
# 5) Cross-sectional DBS forest plot
# =========================================================
# Weighted linear regression on the MATCHED cohort at the first post-DBS visit
matched_long <- readRDS(file.path(OUT_OBJ, "pain_long.rds"))
xsec <- matched_long %>%
  dplyr::filter(time_pos_months >= 0, time_pos_months <= 12) %>%
  dplyr::group_by(PATNO) %>%
  dplyr::arrange(time_pos_months) %>%
  dplyr::summarise(pain = dplyr::first(NP1PAIN),
                   dbs  = dplyr::first(will_receive_dbs),
                   w    = dplyr::first(weight_sw_trim90),
                   .groups = "drop") %>%
  dplyr::filter(!is.na(pain))

m_xsec <- stats::lm(pain ~ dbs, data = xsec, weights = w)
co <- summary(m_xsec)$coefficients
beta <- co["dbsTRUE", "Estimate"]
se   <- co["dbsTRUE", "Std. Error"]
pval <- co["dbsTRUE", "Pr(>|t|)"]
xsec_out <- tibble(term = "DBS: Yes vs No",
                   est = beta,
                   lo  = beta - 1.96 * se,
                   hi  = beta + 1.96 * se,
                   p   = pval)

p_forest <- ggplot(xsec_out, aes(est, term)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey55") +
  geom_errorbarh(aes(xmin = lo, xmax = hi), height = 0.1,
                 linewidth = 0.6, colour = "grey25") +
  geom_point(size = 3.5, colour = "#332288") +
  geom_text(aes(label = sprintf("%+.2f [%+.2f, %+.2f]   p = %.3f",
                                est, lo, hi, p)),
            hjust = 0, nudge_x = 0.18, size = 3.3) +
  scale_x_continuous("Weighted DBS effect on Pain score [95% CI]",
                     limits = c(-0.6, 0.8)) +
  annotate("text", x = -0.55, y = 1.35, hjust = 0,
           label = "No DBS better", colour = "grey30", size = 3.1) +
  annotate("text", x = 0.7, y = 1.35, hjust = 1,
           label = "DBS better", colour = "grey30", size = 3.1) +
  labs(title = "Figure 8. Cross-sectional weighted regression: DBS effect on pain",
       subtitle = "First post-anchor visit within 0-12 months, matched cohort, IPW weighted",
       y = NULL) +
  theme_classic(base_size = 11, base_family = "Helvetica") +
  theme(plot.title    = element_text(face = "bold"),
        plot.subtitle = element_text(colour = "grey35"),
        axis.text.y   = element_text(size = 11),
        plot.margin   = ggplot2::margin(10, 14, 10, 10))
ggsave(file.path(OUT_FIG, "Figure8_xsec_DBS_forest.png"),
       p_forest, width = 10, height = 3.2, dpi = 300)
cat("[5] Cross-sectional forest saved\n")

# =========================================================
# 6) Sex x DBS and BMI x DBS interactions
# =========================================================
inter_data <- matched_long %>%
  dplyr::filter(time_pos_months >= 0, time_pos_months <= 12,
                !is.na(NP1PAIN)) %>%
  dplyr::group_by(PATNO) %>%
  dplyr::summarise(pain = mean(NP1PAIN, na.rm = TRUE),
                   dbs  = dplyr::first(will_receive_dbs),
                   w    = dplyr::first(weight_sw_trim90),
                   .groups = "drop")

sex_bmi <- rel %>% dplyr::distinct(PATNO, SEX, BMI)
inter_df <- inter_data %>% dplyr::inner_join(sex_bmi, by = "PATNO") %>%
  dplyr::mutate(
    sex_lab = dplyr::if_else(SEX == 1, "Male", "Female"),
    bmi_cat = dplyr::case_when(
      BMI < 25 ~ "Normal",
      BMI < 30 ~ "Overweight",
      BMI >= 30 ~ "Obesity",
      TRUE ~ NA_character_
    ),
    arm = dplyr::if_else(dbs, "Yes", "No")
  )

sex_sum <- inter_df %>% dplyr::filter(!is.na(sex_lab)) %>%
  dplyr::group_by(arm, sex_lab) %>%
  dplyr::summarise(n = dplyr::n(),
                   m = stats::weighted.mean(pain, w, na.rm = TRUE),
                   se = stats::sd(pain, na.rm = TRUE) / sqrt(dplyr::n()),
                   .groups = "drop")

p_sex <- ggplot(sex_sum, aes(arm, m, colour = sex_lab,
                             group = sex_lab)) +
  geom_errorbar(aes(ymin = m - 1.96 * se, ymax = m + 1.96 * se),
                width = 0.12,
                position = position_dodge(0.25)) +
  geom_point(size = 3, position = position_dodge(0.25)) +
  scale_colour_manual(values = c("Female" = "#CC6677", "Male" = "#332288"),
                      name = "Sex") +
  scale_x_discrete("DBS") +
  scale_y_continuous("Pain score (95% CI)") +
  labs(title = "Figure 9A. Interaction between Pain x Sex") +
  theme_classic(base_size = 11, base_family = "Helvetica") +
  theme(plot.title = element_text(face = "bold"),
        legend.position = "right")

bmi_sum <- inter_df %>% dplyr::filter(!is.na(bmi_cat)) %>%
  dplyr::mutate(bmi_cat = factor(bmi_cat,
                                 levels = c("Normal", "Overweight", "Obesity"))) %>%
  dplyr::group_by(arm, bmi_cat) %>%
  dplyr::summarise(n = dplyr::n(),
                   m = stats::weighted.mean(pain, w, na.rm = TRUE),
                   se = stats::sd(pain, na.rm = TRUE) / sqrt(dplyr::n()),
                   .groups = "drop")

p_bmi <- ggplot(bmi_sum, aes(arm, m, colour = bmi_cat,
                             group = bmi_cat)) +
  geom_errorbar(aes(ymin = m - 1.96 * se, ymax = m + 1.96 * se),
                width = 0.12,
                position = position_dodge(0.3)) +
  geom_point(size = 3, position = position_dodge(0.3)) +
  scale_colour_manual(
    values = c("Normal" = "#CC6677", "Overweight" = "#332288", "Obesity" = "#117733"),
    name = "BMI category"
  ) +
  scale_x_discrete("DBS") +
  scale_y_continuous("Pain score (95% CI)") +
  labs(title = "Figure 9B. Interaction between Pain x BMI") +
  theme_classic(base_size = 11, base_family = "Helvetica") +
  theme(plot.title = element_text(face = "bold"),
        legend.position = "right")

fig9 <- p_sex / p_bmi
ggsave(file.path(OUT_FIG, "Figure9_sex_bmi_interaction.png"),
       fig9, width = 6.5, height = 7.5, dpi = 300)
cat("[6] Sex/BMI interaction plots saved\n")

# =========================================================
# 7) Supplementary wide-window Figure S5 (LMM, 0-60 months)
# =========================================================
df_long <- readRDS(file.path(OUT_OBJ, "pain_long.rds")) %>%
  dplyr::mutate(time_m = time_days / DAYS_PER_MONTH)

S_data <- df_long %>% dplyr::filter(time_m >= -60, time_m <= 60)
m_S <- lme4::lmer(
  NP1PAIN ~ time_m * traj + (1 + time_m | PATNO),
  data    = S_data,
  weights = weight_sw_trim90,
  REML    = FALSE,
  control = lme4::lmerControl(optimizer = "bobyqa",
                              optCtrl = list(maxfun = 2e5))
)

grid_S <- dplyr::bind_rows(
  data.frame(time_m = seq(-60, 0,  length.out = 150),
             traj   = factor("Pre-DBS",
                             levels = c("Pre-DBS", "Post-DBS", "Never-DBS"))),
  data.frame(time_m = seq(0,   60, length.out = 150),
             traj   = factor("Post-DBS",
                             levels = c("Pre-DBS", "Post-DBS", "Never-DBS"))),
  data.frame(time_m = seq(-60, 60, length.out = 250),
             traj   = factor("Never-DBS",
                             levels = c("Pre-DBS", "Post-DBS", "Never-DBS")))
)
pr_S <- predict(m_S, newdata = grid_S, re.form = NA, se.fit = TRUE)
pred_S <- dplyr::bind_cols(
  grid_S,
  tibble::tibble(fit = pr_S$fit,
                 lci = pr_S$fit - 1.96 * pr_S$se.fit,
                 uci = pr_S$fit + 1.96 * pr_S$se.fit)
) %>% dplyr::mutate(time_y = time_m / 12)

p_S <- ggplot(pred_S, aes(time_y, fit, colour = traj, fill = traj)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey50") +
  geom_ribbon(aes(ymin = lci, ymax = uci), alpha = 0.22, colour = NA) +
  geom_line(linewidth = 1.1) +
  scale_colour_manual(values = TRAJ_COLORS, name = NULL) +
  scale_fill_manual(values = TRAJ_COLORS, guide = "none") +
  scale_x_continuous("Years from anchor", breaks = seq(-5, 5, 1)) +
  scale_y_continuous("Predicted Pain score") +
  labs(title = "Supplementary Figure S5. LMM wide-window predicted trajectories",
       subtitle = "Matched cohort, 3-phase LMM over +-60 months") +
  theme_classic(base_size = 11, base_family = "Helvetica") +
  theme(plot.title    = element_text(face = "bold"),
        plot.subtitle = element_text(colour = "grey35"),
        legend.position = "top")
ggsave(file.path(OUT_FIG, "FigureS5_lmm_wide_window.png"),
       p_S, width = 9, height = 4.6, dpi = 300)
cat("[7] Supplementary wide-window LMM saved\n")

cat("\nReplication figure pass complete.\n")
