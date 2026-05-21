#!/usr/bin/env Rscript
# build_causal_dag.R
# ------------------------------------------------------------
# Build the causal DAG that motivates the propensity-score / IPW
# adjustment set and the mediation / competing-risk analyses.
#
# Nodes:
#   - DBS              : treatment / exposure (binary)
#   - Pain             : outcome (longitudinal NP1PAIN trajectory)
#   - Confounders     : age, sex, disease_duration, UPDRS3, NHY, LEDD,
#                       BMI, gds, stai, baseline_pain
#   - Mediators        : delta_LEDD (post-DBS LEDD reduction)
#   - Competing event  : dropout
#   - Selection arrow  : baseline pain → DBS (channeling bias)
#
# Outputs:
#   - outputs/figures/Figure_causal_DAG.{png,pdf}
#   - outputs/objects/causal_dag.txt (dagitty syntax for reviewers)
# ------------------------------------------------------------

suppressPackageStartupMessages({
  library(dagitty); library(ggdag); library(ggplot2); library(dplyr)
})
source("helpers/pain_helpers.R")

# Build the DAG using dagitty syntax.
dag <- dagitty::dagitty('
dag {
  bb="0,0,1,1"

  "Age"           [pos="0.05,0.10"]
  "Sex"           [pos="0.10,0.20"]
  "Duration_PD"   [pos="0.05,0.32"]
  "UPDRS_III"     [pos="0.20,0.05"]
  "NHY_stage"     [pos="0.30,0.10"]
  "BMI"           [pos="0.10,0.55"]
  "GDS_STAI"      [pos="0.18,0.78"]
  "Baseline_Pain" [pos="0.10,0.92"]
  "LEDD_pre"      [pos="0.35,0.25"]

  "DBS"           [exposure, pos="0.50,0.50"]
  "Delta_LEDD"    [pos="0.65,0.78"]
  "Stim_circuit"  [pos="0.65,0.50"]
  "Dropout"       [pos="0.80,0.25"]
  "Pain_traj"     [outcome, pos="0.90,0.50"]

  Age             -> DBS
  Sex             -> DBS
  Duration_PD     -> DBS
  UPDRS_III       -> DBS
  NHY_stage       -> DBS
  LEDD_pre        -> DBS
  BMI             -> DBS
  Baseline_Pain   -> DBS
  Baseline_Pain   -> Pain_traj
  GDS_STAI        -> DBS
  GDS_STAI        -> Pain_traj

  Age             -> Pain_traj
  Sex             -> Pain_traj
  Duration_PD     -> Pain_traj
  UPDRS_III       -> Pain_traj
  NHY_stage       -> Pain_traj
  LEDD_pre        -> Pain_traj
  BMI             -> Pain_traj

  DBS             -> Delta_LEDD
  DBS             -> Stim_circuit
  Delta_LEDD      -> Pain_traj
  Stim_circuit    -> Pain_traj

  DBS             -> Dropout
  Baseline_Pain   -> Dropout
  Dropout         -> Pain_traj
}
')

# Print adjustment set required to estimate the total effect of DBS on Pain
cat("Minimal adjustment set for DBS -> Pain_traj (total effect):\n")
print(dagitty::adjustmentSets(dag, exposure = "DBS",
                              outcome = "Pain_traj",
                              effect = "total"))

cat("\nMinimal adjustment set for DBS -> Pain_traj (direct effect):\n")
print(dagitty::adjustmentSets(dag, exposure = "DBS",
                              outcome = "Pain_traj",
                              effect = "direct"))

cat("\nTestable implications (conditional independencies):\n")
print(head(dagitty::impliedConditionalIndependencies(dag), 10))

# Save dagitty source
dir.create("outputs/objects", showWarnings = FALSE, recursive = TRUE)
writeLines(as.character(dag), "outputs/objects/causal_dag.txt")

# ggdag rendering
tidy_dag <- ggdag::tidy_dagitty(dag)

p <- ggdag::ggdag(tidy_dag, node_size = 16, text_size = 2.6) +
  ggdag::theme_dag_blank() +
  ggplot2::labs(
    title    = "Causal DAG for DBS effect on longitudinal pain",
    subtitle = "Solid arrows: causal directions. DBS = exposure; Pain_traj = outcome. Adjusted via PS/IPW on the parents-of-DBS set."
  )

# Manual colour pass: confounders blue, mediators orange, outcome vermillion
nodes <- tidy_dag$data %>% dplyr::distinct(name)
nodes$role <- dplyr::case_when(
  nodes$name == "DBS"          ~ "Exposure",
  nodes$name == "Pain_traj"    ~ "Outcome",
  nodes$name %in% c("Delta_LEDD", "Stim_circuit") ~ "Mediator",
  nodes$name == "Dropout"      ~ "Competing",
  TRUE                         ~ "Confounder"
)
tidy_dag$data <- tidy_dag$data %>% dplyr::left_join(nodes, by = "name")

p <- ggplot2::ggplot(tidy_dag$data,
                     ggplot2::aes(x = x, y = y, xend = xend, yend = yend)) +
  ggdag::geom_dag_edges_arc(curvature = 0.05,
                            edge_width = 0.6,
                            arrow_directed = grid::arrow(
                              length = grid::unit(7, "pt"), type = "closed")) +
  ggdag::geom_dag_node(ggplot2::aes(colour = role), size = 17) +
  ggdag::geom_dag_text(colour = "white", size = 2.4) +
  ggplot2::scale_colour_manual(
    values = c(Confounder = unname(OKABE_ITO["blue"]),
               Exposure   = unname(OKABE_ITO["vermillion"]),
               Outcome    = unname(OKABE_ITO["green"]),
               Mediator   = unname(OKABE_ITO["orange"]),
               Competing  = unname(OKABE_ITO["pink"])),
    name = NULL) +
  ggdag::theme_dag_blank() +
  ggplot2::labs(
    title    = "Causal DAG: DBS → longitudinal pain in PD",
    subtitle = paste(
      "Exposure = DBS, outcome = Pain trajectory.",
      "Backdoor confounders adjusted via PS-matching + IPW.",
      "Mediators (Delta_LEDD, Stim_circuit) analysed in Sprint 9; Dropout handled by competing-risk + MNAR sensitivity.",
      sep = "\n")
  ) +
  ggplot2::theme(legend.position = "right")

save_fig_pub(p, "Figure_causal_DAG", width = 11, height = 7)
cat("\n[OK] DAG outputs saved.\n")
