#!/usr/bin/env Rscript
# build_delta_24m_landmark.R
# ------------------------------------------------------------
# Single-panel, time-defined stratified Δ Pain figure.
# Δ Pain = mean Pain in landmark window [18, 30] months
#          − mean Pain in baseline window [-6, 0] months.
# Only patients with at least one visit in BOTH windows enter.
# Stratified by baseline mean pain:
#   Low (<1), Moderate (1–<2), High (≥2).
# Welch t-test per stratum, DBS vs. Never-DBS.
# ------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(purrr); library(tibble)
})
source("helpers/pain_helpers.R")

rel <- load_full_ppmi_rel_patient_anchor()
cat("Rows:", nrow(rel), "  Patients:", dplyr::n_distinct(rel$PATNO), "\n")

# ---- Windows ------------------------------------------------
PRE  <- c(-6,  0)    # baseline (pre-anchor) window
POST <- c(18, 30)    # 24-month landmark ± 6 months

strat <- function(pm) dplyr::case_when(
  pm >= 2 ~ "High (\u2265 2)",
  pm >= 1 ~ "Moderate (1\u2013<2)",
  TRUE    ~ "Low (<1)"
)

pre <- rel %>%
  dplyr::filter(months >= PRE[1], months <= PRE[2], !is.na(NP1PAIN)) %>%
  dplyr::group_by(PATNO, will_receive_dbs) %>%
  dplyr::summarise(pre_mean = mean(NP1PAIN), n_pre = dplyr::n(),
                   .groups = "drop")

post <- rel %>%
  dplyr::filter(months >= POST[1], months <= POST[2], !is.na(NP1PAIN)) %>%
  dplyr::group_by(PATNO) %>%
  dplyr::summarise(post_mean = mean(NP1PAIN), n_post = dplyr::n(),
                   .groups = "drop")

df <- dplyr::inner_join(pre, post, by = "PATNO") %>%
  dplyr::mutate(
    delta = post_mean - pre_mean,
    pain_stratum = factor(strat(pre_mean),
                          levels = c("Low (<1)",
                                     "Moderate (1\u2013<2)",
                                     "High (\u2265 2)")),
    arm = factor(dplyr::if_else(will_receive_dbs, "DBS", "Never-DBS"),
                 levels = c("DBS", "Never-DBS"))
  )

cat("Patients with both baseline + 24m landmark:",
    nrow(df),
    "  DBS:", sum(df$will_receive_dbs),
    "  Never-DBS:", sum(!df$will_receive_dbs), "\n")

# ---- Summary per stratum x arm ------------------------------
summ <- df %>%
  dplyr::group_by(pain_stratum, arm) %>%
  dplyr::summarise(
    n          = dplyr::n(),
    mean_delta = mean(delta, na.rm = TRUE),
    se         = stats::sd(delta, na.rm = TRUE) / sqrt(dplyr::n()),
    .groups    = "drop"
  ) %>%
  dplyr::mutate(
    lo  = mean_delta - 1.96 * se,
    hi  = mean_delta + 1.96 * se,
    lab = sprintf("\u0394 %+.2f\nn=%d", mean_delta, n)
  )

# ---- Welch t-test DBS vs. Never-DBS per stratum -------------
p_tbl <- purrr::map_dfr(levels(df$pain_stratum), function(s) {
  sub <- df %>% dplyr::filter(pain_stratum == s)
  if (sum(sub$will_receive_dbs) < 5 || sum(!sub$will_receive_dbs) < 5) {
    return(tibble::tibble(pain_stratum = s, p_lab = "ns (n<5)"))
  }
  tt <- stats::t.test(delta ~ will_receive_dbs, data = sub)
  tibble::tibble(
    pain_stratum = s,
    p_lab = sprintf("P = %.2f", tt$p.value)
  )
}) %>%
  dplyr::mutate(pain_stratum = factor(pain_stratum,
                                      levels = levels(df$pain_stratum)))

# ---- Interaction P (DBS x baseline-stratum on Δ) ------------
int_fit <- stats::lm(delta ~ arm * pain_stratum, data = df)
int_aov <- stats::anova(int_fit)
p_int <- int_aov["arm:pain_stratum", "Pr(>F)"]
cat(sprintf("DBS x baseline-pain interaction P = %.3f\n", p_int))

# ---- Plot ---------------------------------------------------
yrange <- range(c(summ$lo, summ$hi), na.rm = TRUE)
yhead  <- yrange[2] + 0.25 * diff(yrange)

p <- ggplot(summ, aes(pain_stratum, mean_delta, fill = arm)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey55") +
  geom_col(position = position_dodge(0.8), width = 0.65,
           colour = "white", linewidth = 0.3) +
  geom_errorbar(aes(ymin = lo, ymax = hi),
                position = position_dodge(0.8), width = 0.18,
                linewidth = 0.55, colour = "grey20") +
  geom_text(aes(label = lab,
                y = ifelse(mean_delta >= 0, hi + 0.03, lo - 0.03)),
            position = position_dodge(0.8),
            vjust = ifelse(summ$mean_delta >= 0, 0, 1),
            lineheight = 0.9, size = 3.3, colour = "grey15") +
  geom_text(data = p_tbl,
            aes(x = pain_stratum, y = yhead, label = p_lab),
            inherit.aes = FALSE, size = 3.4,
            colour = "grey30", fontface = "italic") +
  scale_fill_manual(values = c(DBS = "#CC6677", `Never-DBS` = "#332288"),
                    name = NULL) +
  scale_y_continuous("\u0394 Pain  (24 mo landmark \u2212 baseline)",
                     expand = expansion(mult = c(0.15, 0.25))) +
  labs(
    title    = "\u0394 Pain score by baseline-pain stratum and DBS arm",
    subtitle = sprintf(
      "Landmark: 24 \u00b1 6 mo. Baseline: [\u22126, 0] mo. DBS \u00d7 baseline-pain interaction P = %.2f.",
      p_int),
    x = NULL
  ) +
  theme_classic(base_size = 12, base_family = "Helvetica") +
  theme(
    plot.title        = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle     = element_text(colour = "grey35", hjust = 0.5, size = 10),
    axis.text.x       = element_text(size = 11),
    axis.title.y      = element_text(size = 11),
    legend.position   = "top",
    legend.text       = element_text(size = 11),
    panel.grid.major.y = element_line(colour = "grey92", linewidth = 0.25)
  )

out_path <- file.path(OUT_FIG, "Figure_delta_24m_landmark.png")
ggsave(out_path, p, width = 10, height = 5.5, dpi = 300)
cat("[OK] saved", out_path, "\n")

# ---- Companion CSVs ----------------------------------------
readr::write_csv(summ,  file.path(OUT_TAB, "delta_24m_landmark_summary.csv"))
readr::write_csv(p_tbl, file.path(OUT_TAB, "delta_24m_landmark_welch.csv"))
cat("[OK] tables saved\n")

print(summ)
print(p_tbl)
