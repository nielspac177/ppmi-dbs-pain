#!/usr/bin/env Rscript
# Regenerate Figure 6 (baseline partial-correlation network) with
#   - large readable short labels
#   - Pain highlighted in red
#   - a companion source-variable legend panel so the reader can see
#     which PPMI variable each short label is drawn from
#   - companion matrix-style heatmap

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(qgraph); library(patchwork)
})
source("helpers/pain_helpers.R")

# Short label -> display name (shown inside node circles)
LAB <- c(
  NP1PAIN="Pain", NP1SLPN="Sleep", NP1SLPD="Sleepy",
  NP1FATG="Fatigue", NP1URIN="Urinary",
  NP1DPRS="Depr.", NP1ANXS="Anx.",
  gds="GDS", stai="STAI", ess="ESS", rem="RBD",
  scopa="Auton.", updrs3_score="Motor",
  BMI="BMI", LEDD="LEDD"
)

# Source-variable description for legend
SRC <- tibble::tribble(
  ~short,     ~source_var,      ~description,
  "Pain",     "NP1PAIN",        "Pain & sensations (MDS-UPDRS I, 1.9)",
  "Sleep",    "NP1SLPN",        "Night sleep problems (MDS-UPDRS I, 1.7)",
  "Sleepy",   "NP1SLPD",        "Daytime sleepiness (MDS-UPDRS I, 1.8)",
  "Fatigue",  "NP1FATG",        "Fatigue (MDS-UPDRS I, 1.13)",
  "Urinary",  "NP1URIN",        "Urinary problems (MDS-UPDRS I, 1.10)",
  "Depr.",    "NP1DPRS",        "Depressed mood (MDS-UPDRS I, 1.3)",
  "Anx.",     "NP1ANXS",        "Anxious mood (MDS-UPDRS I, 1.4)",
  "GDS",      "gds",            "Geriatric Depression Scale (15-item)",
  "STAI",     "stai",           "State-Trait Anxiety Inventory (total)",
  "ESS",      "ess",            "Epworth Sleepiness Scale",
  "RBD",      "rem",            "RBD Screening Questionnaire",
  "Auton.",   "scopa",          "SCOPA-AUT (autonomic total)",
  "Motor",    "updrs3_score",   "MDS-UPDRS Part III (motor total)",
  "BMI",      "BMI",            "Body-mass index (kg/m^2)",
  "LEDD",     "LEDD",           "Levodopa-equivalent dose (mg/day)"
)
readr::write_csv(SRC, file.path(OUT_TAB, "figure6_network_label_sources.csv"))

# ---- Load and relabel the baseline all-patients network ----
P_list <- readRDS(file.path(OUT_OBJ, "partial_correlation_matrices.rds"))
P <- P_list$all
new_lab <- ifelse(rownames(P) %in% names(LAB), LAB[rownames(P)], rownames(P))
rownames(P) <- colnames(P) <- new_lab

# ---- Network rendered into a PNG ----
net_png <- file.path(OUT_FIG, "Figure6_network_only.png")
png(net_png, width = 2400, height = 2400, res = 360)
par(mar = c(0.3, 0.3, 0.3, 0.3))
qgraph::qgraph(
  P,
  layout = "spring",
  theme = "classic",
  labels = colnames(P),
  label.cex = 1.5,
  label.scale = FALSE,
  label.color = "black",
  vsize = 11,
  color = ifelse(colnames(P) == "Pain", "#CC6677", "#D9E3F2"),
  border.color = "grey20",
  border.width = 1.6,
  edge.labels = FALSE,
  esize = 7,
  fade = TRUE
)
invisible(dev.off())

# ---- Source-variable legend as a ggplot (three columns: short, variable, description) ----
SRC2 <- SRC %>%
  dplyr::mutate(rownum = dplyr::row_number(),
                y = -rownum)

p_legend <- ggplot(SRC2, aes(x = 0, y = y)) +
  # Coloured pill for the short label
  geom_label(aes(label = short),
             fill = ifelse(SRC2$short == "Pain", "#CC6677", "#D9E3F2"),
             colour = ifelse(SRC2$short == "Pain", "white", "black"),
             hjust = 0, label.size = 0.3, size = 3.8,
             label.padding = unit(0.18, "lines")) +
  # Source variable name (monospace)
  geom_text(aes(x = 1.0, label = source_var), hjust = 0,
            family = "mono", size = 3.4, colour = "grey20") +
  # Description
  geom_text(aes(x = 2.6, label = description), hjust = 0,
            size = 3.4, colour = "grey10") +
  scale_x_continuous(limits = c(-0.1, 12), expand = c(0, 0)) +
  scale_y_continuous(limits = c(min(SRC2$y) - 0.6, 0.8), expand = c(0, 0)) +
  labs(title = "Node labels - source variables",
       subtitle = "Short label shown inside each node (left); PPMI variable code (middle); what it measures (right)") +
  theme_void(base_size = 11, base_family = "Helvetica") +
  theme(plot.title = element_text(face = "bold", size = 11, hjust = 0),
        plot.subtitle = element_text(colour = "grey30", size = 9, hjust = 0,
                                     margin = margin(b = 8)),
        plot.margin = margin(6, 6, 6, 6))

# ---- Combine network + legend (patchwork) ----
# Read the network PNG into a ggplot panel via geom_image? Simpler: redraw network
# as a wrapped plot using qgraph + patchwork::wrap_elements(). We re-render the qgraph
# into a grob via png() capture and then inset it.
# Simplest approach: save network solo and save legend solo, then use magick/pdf
# stitching is overkill. Instead build the combined figure using par(mfrow) / layout().

combined_png <- file.path(OUT_FIG, "Figure6_network_labeled.png")
combined_tiff <- file.path(OUT_FIG, "Figure6_network_labeled.tiff")

draw_combined <- function(file, device_fn) {
  device_fn(file, width = 4600, height = 2600, res = 360)
  layout(matrix(c(1, 2), nrow = 1), widths = c(1.0, 1.05))
  par(mar = c(0.5, 0.5, 1.0, 0.5))
  qgraph::qgraph(
    P,
    layout = "spring",
    theme = "classic",
    labels = colnames(P),
    label.cex = 1.5,
    label.scale = FALSE,
    label.color = "black",
    vsize = 11,
    color = ifelse(colnames(P) == "Pain", "#CC6677", "#D9E3F2"),
    border.color = "grey20",
    border.width = 1.6,
    edge.labels = FALSE,
    esize = 7,
    fade = TRUE,
    title = "A  Partial-correlation network"
  )
  # Right panel: manual text table with source variables
  par(mar = c(1, 1, 2.2, 1))
  plot.new()
  plot.window(xlim = c(0, 1), ylim = c(0, 1), xaxs = "i", yaxs = "i")
  title(main = "B  Node source variables", adj = 0, font.main = 2, cex.main = 1.2)

  n <- nrow(SRC)
  y_top <- 0.93; y_bot <- 0.04
  ys <- seq(y_top, y_bot, length.out = n)
  # Column header
  text(0.02, 0.98, "Label",       adj = c(0, 0.5), font = 2, cex = 0.95)
  text(0.22, 0.98, "PPMI variable", adj = c(0, 0.5), font = 2, cex = 0.95)
  text(0.48, 0.98, "Description",  adj = c(0, 0.5), font = 2, cex = 0.95)

  for (i in seq_len(n)) {
    is_pain <- SRC$short[i] == "Pain"
    # Coloured pill for the short label (rect + text)
    rect(0.01, ys[i] - 0.022, 0.18, ys[i] + 0.022,
         col = if (is_pain) "#CC6677" else "#D9E3F2",
         border = "grey30", lwd = 1)
    text(0.095, ys[i], SRC$short[i], adj = c(0.5, 0.5),
         col = if (is_pain) "white" else "black", cex = 0.95,
         font = if (is_pain) 2 else 1)
    # Source code
    text(0.22, ys[i], SRC$source_var[i], adj = c(0, 0.5),
         family = "mono", cex = 0.9, col = "grey15")
    # Description
    text(0.48, ys[i], SRC$description[i], adj = c(0, 0.5),
         cex = 0.85, col = "grey15")
  }
  invisible(dev.off())
}

draw_combined(combined_png, png)
draw_combined(combined_tiff, function(f, width, height, res) {
  tiff(f, width = width, height = height, res = res, compression = "lzw")
})
cat("[OK] Figure6_network_labeled with source-variable legend\n")

# ---- Companion heatmap (unchanged) ----
long <- as.data.frame(P) %>% tibble::rownames_to_column("row") %>%
  tidyr::pivot_longer(-row, names_to = "col", values_to = "pcor") %>%
  dplyr::mutate(row = factor(row, levels = colnames(P)),
                col = factor(col, levels = colnames(P)))

p_hm <- ggplot(long, aes(col, row, fill = pcor)) +
  geom_tile(colour = "white", linewidth = 0.25) +
  geom_text(aes(label = ifelse(abs(pcor) >= 0.05, sprintf("%.2f", pcor), "")),
            size = 2.6, colour = "black") +
  scale_fill_gradient2(low = "#CC6677", mid = "white", high = "#332288",
                       midpoint = 0, limits = c(-0.35, 0.35),
                       oob = scales::squish,
                       name = "Partial\ncorrelation") +
  coord_fixed() +
  labs(title = "Partial-correlation matrix of 15 non-motor symptoms",
       subtitle = "All patients at baseline; cells with |rho| >= 0.05 labelled.",
       x = NULL, y = NULL) +
  theme_classic(base_size = 11, base_family = "Helvetica") +
  theme(plot.title = element_text(face = "bold"),
        plot.subtitle = element_text(colour = "grey30"),
        axis.text.x = element_text(angle = 40, hjust = 1),
        panel.grid = element_blank())

ggsave(file.path(OUT_FIG, "Figure6b_network_heatmap.png"),
       p_hm, width = 9.5, height = 8.5, dpi = 300)
ggsave(file.path(OUT_FIG, "Figure6b_network_heatmap.tiff"),
       p_hm, width = 9.5, height = 8.5, dpi = 300, compression = "lzw")
cat("[OK] Figure6b_network_heatmap\n")
