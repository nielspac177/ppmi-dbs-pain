#!/usr/bin/env Rscript
# build_fig5_and_tables.R
# - Rebuild Figure 5: Panel A LMM pre-DBS vs post-DBS, +-12 months (DBS only)
#                    Panel B LMM post-DBS vs Never-DBS,  0-48 months (matched)
# - Build regression tables (fixed effects + slope contrasts) for both LMMs
# - Use "Pain score" in all display text (NP1PAIN hidden from reader)

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(patchwork)
  library(lme4); library(lmerTest); library(emmeans); library(broom.mixed)
  library(knitr)
})
source("helpers/pain_helpers.R")

# ---------------------------------------------------------
# Load matched long
# ---------------------------------------------------------
df_long <- readRDS(file.path(OUT_OBJ, "pain_long.rds")) %>%
  dplyr::mutate(
    # SIGNED months from anchor: negative = pre-anchor, positive = post-anchor.
    # NOTE: the original build used time_pos_months (unsigned |days-before-surgery|
    # for Pre-DBS), which introduced an axis-inversion artifact -- pre-DBS slope
    # was measured in the "look-backward" direction while post-DBS was forward,
    # making the Pre-DBS vs Post-DBS contrast uninterpretable on calendar time.
    time_m = time_days / DAYS_PER_MONTH
  )

cat("Total rows:", nrow(df_long), " Patients:", dplyr::n_distinct(df_long$PATNO), "\n")

# ---------------------------------------------------------
# Panel A: Pre-DBS vs Post-DBS within DBS patients, +-12 months
# ---------------------------------------------------------
A_data <- df_long %>%
  dplyr::filter(traj %in% c("Pre-DBS", "Post-DBS"),
                time_m >= -12, time_m <= 12) %>%
  dplyr::mutate(traj = droplevels(factor(traj, levels = c("Pre-DBS", "Post-DBS"))))

cat("\nPanel A (pre/post, +-12 mo) rows:", nrow(A_data),
    " Patients:", dplyr::n_distinct(A_data$PATNO), "\n")

m_A <- lme4::lmer(
  NP1PAIN ~ time_m * traj + (1 + time_m | PATNO),
  data    = A_data,
  weights = weight_sw_trim90,
  REML    = FALSE,
  control = lme4::lmerControl(optimizer = "bobyqa",
                              optCtrl = list(maxfun = 2e5))
)

# Slope per month by phase + pairwise contrast
sl_A <- emmeans::emtrends(m_A, specs = "traj", var = "time_m",
                          lmerTest.limit = 1e5, pbkrtest.limit = 1e5)
ct_A <- as.data.frame(pairs(sl_A, adjust = "none"))
print(sl_A); print(ct_A)

# Predicted trajectory with 95% CI -- each phase only over its data support
grid_A <- dplyr::bind_rows(
  data.frame(time_m = seq(-12, 0, length.out = 120),
             traj   = factor("Pre-DBS",  levels = c("Pre-DBS", "Post-DBS"))),
  data.frame(time_m = seq(0,  12, length.out = 120),
             traj   = factor("Post-DBS", levels = c("Pre-DBS", "Post-DBS")))
)
pr_A <- predict(m_A, newdata = grid_A, re.form = NA, se.fit = TRUE)
pred_A <- dplyr::bind_cols(
  grid_A,
  tibble::tibble(fit = pr_A$fit,
                 lci = pr_A$fit - 1.96 * pr_A$se.fit,
                 uci = pr_A$fit + 1.96 * pr_A$se.fit)
) %>% dplyr::mutate(time_y = time_m / 12)

p_A <- ggplot(pred_A, aes(time_y, fit, colour = traj, fill = traj)) +
  geom_ribbon(aes(ymin = lci, ymax = uci), alpha = 0.22, colour = NA) +
  geom_line(linewidth = 1.15) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey40") +
  annotate("text", x = 0.02, y = Inf, vjust = 1.4, hjust = 0,
           label = "DBS", colour = "grey35", size = 3.2, fontface = "italic") +
  scale_colour_manual(values = c("Pre-DBS" = "#1b9e77", "Post-DBS" = "#d95f02"),
                      name = NULL) +
  scale_fill_manual(values   = c("Pre-DBS" = "#1b9e77", "Post-DBS" = "#d95f02"),
                    guide = "none") +
  scale_x_continuous("Years from DBS",
                     breaks = seq(-1, 1, 0.5),
                     limits = c(-1, 1)) +
  scale_y_continuous("Predicted Pain score") +
  labs(title = "A  Pre-DBS vs Post-DBS trajectories (\u00B1 1 year)",
       subtitle = sprintf("Slope flip contrast: p = %.3f", ct_A$p.value[1])) +
  theme_classic(base_size = 12, base_family = "Helvetica") +
  theme(plot.title     = element_text(face = "bold"),
        plot.subtitle  = element_text(colour = "grey35"),
        legend.position = "top",
        panel.grid.major = element_line(colour = "grey92", linewidth = 0.25))

# ---------------------------------------------------------
# Panel B: Post-DBS vs Never-DBS, 0-48 months
# ---------------------------------------------------------
B_data <- df_long %>%
  dplyr::filter(traj %in% c("Post-DBS", "Never-DBS"),
                time_m >= 0, time_m <= 48) %>%
  dplyr::mutate(traj = droplevels(factor(traj, levels = c("Never-DBS", "Post-DBS"))))

cat("\nPanel B (Post-DBS vs Never-DBS, 0-48 mo) rows:", nrow(B_data),
    " Patients:", dplyr::n_distinct(B_data$PATNO), "\n")

m_B <- lme4::lmer(
  NP1PAIN ~ time_m * traj + (1 + time_m | PATNO),
  data    = B_data,
  weights = weight_sw_trim90,
  REML    = FALSE,
  control = lme4::lmerControl(optimizer = "bobyqa",
                              optCtrl = list(maxfun = 2e5))
)

sl_B <- emmeans::emtrends(m_B, specs = "traj", var = "time_m",
                          lmerTest.limit = 1e5, pbkrtest.limit = 1e5)
ct_B <- as.data.frame(pairs(sl_B, adjust = "none"))
print(sl_B); print(ct_B)

grid_B <- expand.grid(
  time_m = seq(0, 48, length.out = 200),
  traj   = factor(c("Never-DBS", "Post-DBS"), levels = c("Never-DBS", "Post-DBS"))
)
pr_B <- predict(m_B, newdata = grid_B, re.form = NA, se.fit = TRUE)
pred_B <- dplyr::bind_cols(
  grid_B,
  tibble::tibble(fit = pr_B$fit,
                 lci = pr_B$fit - 1.96 * pr_B$se.fit,
                 uci = pr_B$fit + 1.96 * pr_B$se.fit)
) %>% dplyr::mutate(time_y = time_m / 12)

p_B <- ggplot(pred_B, aes(time_y, fit, colour = traj, fill = traj)) +
  geom_ribbon(aes(ymin = lci, ymax = uci), alpha = 0.22, colour = NA) +
  geom_line(linewidth = 1.15) +
  scale_colour_manual(values = c("Post-DBS" = "#d95f02", "Never-DBS" = "#7570b3"),
                      name = NULL) +
  scale_fill_manual(values   = c("Post-DBS" = "#d95f02", "Never-DBS" = "#7570b3"),
                    guide = "none") +
  scale_x_continuous("Years from DBS / index date",
                     breaks = seq(0, 4, 1), limits = c(0, 4)) +
  scale_y_continuous("Predicted Pain score") +
  labs(title = "B  Post-DBS vs Never-DBS trajectories (0\u20134 years)",
       subtitle = sprintf("Slope contrast (Post-DBS \u2212 Never-DBS): p = %.3f", ct_B$p.value[1])) +
  theme_classic(base_size = 12, base_family = "Helvetica") +
  theme(plot.title     = element_text(face = "bold"),
        plot.subtitle  = element_text(colour = "grey35"),
        legend.position = "top",
        panel.grid.major = element_line(colour = "grey92", linewidth = 0.25))

fig5 <- p_A + p_B + patchwork::plot_layout(ncol = 2)
ggsave(file.path(OUT_FIG, "Figure5_lmm_pre_post_and_post_vs_never.png"),
       fig5, width = 13, height = 5.2, dpi = 300)
cat("[Figure 5] written\n")

# ---------------------------------------------------------
# Regression tables: fixed effects + slope contrasts
# ---------------------------------------------------------
name_map <- function(x) {
  x <- gsub("trajPost-DBS",       "Phase [Post-DBS]",        x, fixed = TRUE)
  x <- gsub("trajNever-DBS",      "Arm [Never-DBS]",         x, fixed = TRUE)
  x <- gsub("time_m:trajPost-DBS", "Phase [Post-DBS] x time", x, fixed = TRUE)
  x <- gsub("time_m:trajNever-DBS","Arm [Never-DBS] x time",  x, fixed = TRUE)
  x <- gsub("time_m", "Time (months)", x, fixed = TRUE)
  x <- gsub("\\(Intercept\\)", "Intercept", x)
  x
}

fe_from_summary <- function(m) {
  s <- summary(m)
  co <- as.data.frame(s$coefficients)
  # lmerTest columns: Estimate, Std. Error, df, t value, Pr(>|t|)
  # fallback when lmerTest p not present: use Wald approx from z
  names(co)[names(co) == "Std. Error"] <- "SE"
  names(co)[names(co) == "t value"]    <- "t"
  if ("Pr(>|t|)" %in% names(co)) {
    names(co)[names(co) == "Pr(>|t|)"] <- "p"
  } else {
    co$p <- 2 * (1 - stats::pnorm(abs(co$t)))
  }
  co$term  <- rownames(co)
  co$lower <- co$Estimate - 1.96 * co$SE
  co$upper <- co$Estimate + 1.96 * co$SE
  co %>%
    dplyr::transmute(Predictor = name_map(term),
                     `Change in Pain score` = sprintf("%+.3f", Estimate),
                     `95% CI` = sprintf("[%+.3f, %+.3f]", lower, upper),
                     `P value` = ifelse(p < 0.001, "< 0.001", sprintf("%.3f", p)))
}

fe_A <- fe_from_summary(m_A)
fe_B <- fe_from_summary(m_B)

fmt_slopes <- function(sl_df, key_col) {
  d <- as.data.frame(sl_df)
  lo <- if ("lower.CL" %in% names(d)) d$lower.CL else d$asymp.LCL
  hi <- if ("upper.CL" %in% names(d)) d$upper.CL else d$asymp.UCL
  tibble::tibble(
    !!key_col := d$traj,
    Slope     = sprintf("%+.4f", d$time_m.trend),
    SE        = sprintf("%.4f", d$SE),
    `95% CI`  = sprintf("[%+.4f, %+.4f]", lo, hi)
  )
}
slopes_A <- fmt_slopes(sl_A, "Phase")
slopes_B <- fmt_slopes(sl_B, "Arm")

fmt_contrast <- function(ct) {
  stat_col <- if ("z.ratio" %in% names(ct)) ct$z.ratio else ct$t.ratio
  stat_name <- if ("z.ratio" %in% names(ct)) "Z" else "t"
  out <- tibble::tibble(
    Contrast = as.character(ct$contrast),
    Estimate = sprintf("%+.4f", ct$estimate),
    SE       = sprintf("%.4f", ct$SE),
    stat     = sprintf("%.2f", stat_col),
    `P value` = ifelse(ct$p.value < 0.001, "< 0.001",
                       sprintf("%.3f", ct$p.value))
  )
  names(out)[4] <- stat_name
  out
}
ct_A_fmt <- fmt_contrast(ct_A)
ct_B_fmt <- fmt_contrast(ct_B)

# Save all tables as CSV
save_table(fe_A,      "lmm_A_pre_post_fixed_effects")
save_table(fe_B,      "lmm_B_post_vs_never_fixed_effects")
save_table(slopes_A,  "lmm_A_slopes")
save_table(slopes_B,  "lmm_B_slopes")
save_table(ct_A_fmt,  "lmm_A_slope_contrast")
save_table(ct_B_fmt,  "lmm_B_slope_contrast")

# HTML (for embedding) - one per table
mk_html <- function(df, caption) {
  knitr::kable(df, format = "html", escape = FALSE, align = "l", caption = caption)
}

fe_A_html <- mk_html(fe_A,
  "Table 2a. Linear mixed model: Pain score ~ time * phase (Pre-DBS vs Post-DBS), +-12 months, n = 105 DBS patients")
fe_B_html <- mk_html(fe_B,
  "Table 2b. Linear mixed model: Pain score ~ time * arm (Post-DBS vs Never-DBS), 0-48 months, matched cohort n = 170")
sl_A_html <- mk_html(slopes_A, "Table 2c. Phase-specific slope (Pain units per month) - Pre/Post DBS")
sl_B_html <- mk_html(slopes_B, "Table 2d. Arm-specific slope (Pain units per month) - Post-DBS vs Never-DBS")
ct_A_html <- mk_html(ct_A_fmt, "Table 2e. Slope contrast: Post-DBS minus Pre-DBS (+- 12 months)")
ct_B_html <- mk_html(ct_B_fmt, "Table 2f. Slope contrast: Post-DBS minus Never-DBS (0-48 months)")

writeLines(as.character(fe_A_html), file.path(OUT_TAB, "lmm_A_fe.html"))
writeLines(as.character(fe_B_html), file.path(OUT_TAB, "lmm_B_fe.html"))
writeLines(as.character(sl_A_html), file.path(OUT_TAB, "lmm_A_slopes.html"))
writeLines(as.character(sl_B_html), file.path(OUT_TAB, "lmm_B_slopes.html"))
writeLines(as.character(ct_A_html), file.path(OUT_TAB, "lmm_A_contrast.html"))
writeLines(as.character(ct_B_html), file.path(OUT_TAB, "lmm_B_contrast.html"))

saveRDS(list(m_A = m_A, m_B = m_B,
             pred_A = pred_A, pred_B = pred_B,
             ct_A = ct_A, ct_B = ct_B),
        file.path(OUT_OBJ, "fig5_lmm_fits.rds"))

cat("\nAll regression tables + Figure 5 saved.\n")
