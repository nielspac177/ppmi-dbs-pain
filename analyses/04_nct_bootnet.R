#!/usr/bin/env Rscript
# 04_nct_bootnet.R
# ------------------------------------------------------------
# Formal between-arm Network Comparison Test + bootnet stability
# for the 15-node non-motor symptom partial-correlation network
# at three windows (Baseline, Early-post, Late-post).
#
# Three pairwise NCT tests per window (DBS vs Never-DBS):
#   - Network invariance (global structure)
#   - Edge-strength invariance (per-edge)
#   - Global-strength invariance
#
# Plus bootnet edge-weight bootstrap (n=500) per arm × window
# to give 95% CIs on partial correlations.
#
# Outputs:
#   - 04_nct_results.csv (global tests per window)
#   - 04_pain_edge_ci.csv (Pain-anchored edges with CIs)
#   - 04_pain_neighbours.{png,pdf}
# ------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(purrr); library(tibble)
  library(bootnet); library(NetworkComparisonTest); library(qgraph); library(glasso)
})
source("helpers/pain_helpers.R")
set.seed(20260519)

NET_VARS <- c("NP1PAIN", "NP1SLPN", "NP1SLPD", "NP1FATG", "NP1URIN",
              "NP1DPRS", "NP1ANXS", "gds", "stai", "ess",
              "rem", "scopa", "updrs3_score", "BMI", "LEDD")

WINDOWS <- list(
  baseline    = c(-24, 0),
  early_post  = c(6, 18),
  late_post   = c(24, 48)
)

# Build per-patient × window means (one row per patient × arm × window)
rel_full <- load_full_ppmi_rel_patient_anchor()
cat("Full cohort rows:", nrow(rel_full),
    "  patients:", dplyr::n_distinct(rel_full$PATNO), "\n")

# Subset to vars + identifiers
rel_full <- rel_full %>%
  dplyr::select(PATNO, will_receive_dbs, months, dplyr::any_of(NET_VARS))
cat("Available vars:", paste(intersect(NET_VARS, names(rel_full)), collapse = ", "), "\n")

avail_vars <- intersect(NET_VARS, names(rel_full))

# Aggregate per (patient × arm × window): mean of available vars
agg_window <- function(rel, win) {
  rel %>%
    dplyr::filter(months >= win[1], months <= win[2]) %>%
    dplyr::group_by(PATNO, will_receive_dbs) %>%
    dplyr::summarise(across(dplyr::all_of(avail_vars),
                            ~ mean(.x, na.rm = TRUE)), .groups = "drop") %>%
    dplyr::mutate(across(dplyr::all_of(avail_vars),
                         ~ dplyr::if_else(is.nan(.x), NA_real_, .x))) %>%
    tidyr::drop_na(dplyr::all_of(avail_vars))
}

# Run bootnet + NCT per window
nct_results <- list()
edge_ci_list <- list()

for (wname in names(WINDOWS)) {
  win <- WINDOWS[[wname]]
  df <- agg_window(rel_full, win)
  cat(sprintf("\n=== Window: %s [%d, %d] ===\n", wname, win[1], win[2]))
  cat(sprintf("  n_total=%d (DBS=%d, Never-DBS=%d)\n",
              nrow(df), sum(df$will_receive_dbs), sum(!df$will_receive_dbs)))

  if (sum(df$will_receive_dbs) < 25 || sum(!df$will_receive_dbs) < 25) {
    cat("  SKIP — insufficient n per arm.\n")
    next
  }

  data_dbs <- df %>% dplyr::filter(will_receive_dbs) %>%
    dplyr::select(dplyr::all_of(avail_vars)) %>% as.data.frame()
  data_ndb <- df %>% dplyr::filter(!will_receive_dbs) %>%
    dplyr::select(dplyr::all_of(avail_vars)) %>% as.data.frame()

  # Estimate networks via EBICglasso with tuning=0 (BIC) and lower
  # lambda.min.ratio so the DBS arm (small n) doesn't collapse to empty.
  # Also fall back to the original paper's fixed rho=0.12 GLASSO if needed.
  net_dbs <- bootnet::estimateNetwork(
    data_dbs, default = "EBICglasso",
    corMethod = "cor_auto", missing = "pairwise",
    tuning = 0, lambda.min.ratio = 0.001, verbose = FALSE)
  net_ndb <- bootnet::estimateNetwork(
    data_ndb, default = "EBICglasso",
    corMethod = "cor_auto", missing = "pairwise",
    tuning = 0, lambda.min.ratio = 0.001, verbose = FALSE)

  if (all(net_dbs$graph == 0)) {
    cat("  DBS EBICglasso empty — refitting with fixed rho=0.12 (paper convention)\n")
    S_dbs <- stats::cor(data_dbs, use = "pairwise.complete.obs")
    g_dbs <- glasso::glasso(S_dbs, rho = 0.12)
    P <- -stats::cov2cor(g_dbs$wi); diag(P) <- 0
    rownames(P) <- colnames(P) <- names(data_dbs)
    net_dbs$graph <- P
  }
  if (all(net_ndb$graph == 0)) {
    cat("  Never-DBS EBICglasso empty — refitting with fixed rho=0.12\n")
    S_ndb <- stats::cor(data_ndb, use = "pairwise.complete.obs")
    g_ndb <- glasso::glasso(S_ndb, rho = 0.12)
    P <- -stats::cov2cor(g_ndb$wi); diag(P) <- 0
    rownames(P) <- colnames(P) <- names(data_ndb)
    net_ndb$graph <- P
  }

  # NCT — comparison test
  cat("  Running NCT (it = 500)…\n")
  nct <- NetworkComparisonTest::NCT(
    net_dbs, net_ndb,
    it = 500,
    test.edges = TRUE,
    edges = "all",
    test.centrality = FALSE,
    progressbar = FALSE
  )
  nct_results[[wname]] <- nct

  # Bootstrap edge CIs (faster, fewer iterations for time)
  cat("  Bootstrapping edges (nBoots=500, parallel)…\n")
  boot_dbs <- bootnet::bootnet(net_dbs, nBoots = 500, type = "nonparametric",
                               nCores = 1, statistics = "edge", verbose = FALSE)
  boot_ndb <- bootnet::bootnet(net_ndb, nBoots = 500, type = "nonparametric",
                               nCores = 1, statistics = "edge", verbose = FALSE)

  # Pull pain-anchored edge CIs from bootTable (full per-iteration rows)
  extract_pain_edges <- function(boot_obj, arm_lbl) {
    bt <- boot_obj$bootTable %>%
      dplyr::filter(type == "edge") %>%
      tidyr::separate(id, into = c("a", "b"), sep = "--", remove = FALSE,
                      fill = "right") %>%
      dplyr::filter(a == "NP1PAIN" | b == "NP1PAIN") %>%
      dplyr::mutate(other = dplyr::if_else(a == "NP1PAIN", b, a),
                    arm = arm_lbl) %>%
      dplyr::select(other, value, arm)
    bt %>%
      dplyr::group_by(other, arm) %>%
      dplyr::summarise(
        boot_mean = mean(value, na.rm = TRUE),
        ci_lo = stats::quantile(value, 0.025, na.rm = TRUE),
        ci_hi = stats::quantile(value, 0.975, na.rm = TRUE),
        n_boot = sum(!is.na(value)),
        .groups = "drop"
      )
  }
  edge_ci <- dplyr::bind_rows(
    extract_pain_edges(boot_dbs, "DBS"),
    extract_pain_edges(boot_ndb, "Never-DBS")
  ) %>% dplyr::mutate(window = wname)

  edge_ci_list[[wname]] <- edge_ci

  cat(sprintf("  NCT global strength P = %.3f\n", nct$glstrinv.pval))
  cat(sprintf("  NCT network invariance P (max edge diff) = %.3f\n", nct$nwinv.pval))
}

# ---- Assemble tables ----
nct_tbl <- purrr::imap_dfr(nct_results, function(nct, wname) {
  tibble::tibble(
    window = wname,
    global_strength_dbs    = nct$glstrinv.sep[1],
    global_strength_neverdbs = nct$glstrinv.sep[2],
    global_strength_diff   = nct$glstrinv.real,
    global_strength_pval   = nct$glstrinv.pval,
    network_invariance_stat = nct$nwinv.real,
    network_invariance_pval = nct$nwinv.pval
  )
})
print(nct_tbl)
save_table(04$NAME, "04_nct_global")

edge_ci_tbl <- dplyr::bind_rows(edge_ci_list)
print(head(edge_ci_tbl, 20))
save_table(04$NAME, "04_pain_edge_ci")

# Save objects for downstream plotting
save_object(nct_results, "04_nct_objects")
save_object(edge_ci_list, "04_edge_ci_objects")

# ---- Plot: Pain-anchored edges across windows ----
plot_df <- edge_ci_tbl %>%
  dplyr::mutate(window = factor(window,
                                levels = c("baseline", "early_post", "late_post"),
                                labels = c("Baseline\n[-24, 0]",
                                           "Early-post\n[+6, +18]",
                                           "Late-post\n[+24, +48]")))

p <- ggplot(plot_df, aes(x = boot_mean, y = reorder(other, boot_mean),
                          colour = arm)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey55") +
  geom_errorbarh(aes(xmin = ci_lo, xmax = ci_hi),
                 height = 0.15, linewidth = 0.7,
                 position = ggplot2::position_dodge(width = 0.55)) +
  geom_point(size = 2.4,
             position = ggplot2::position_dodge(width = 0.55)) +
  facet_wrap(~ window, nrow = 1) +
  scale_colour_manual(values = ARM_COLORS_OK, name = NULL) +
  scale_x_continuous("Bootstrap mean partial correlation with Pain (95% CI)",
                     limits = c(-0.2, 0.5)) +
  labs(
    title = "Pain-anchored partial correlations across windows, by arm",
    subtitle = "Bootstrap 500 resamples per arm × window. Mean ± 95% percentile CI.",
    y = NULL
  ) +
  theme_pain_pub(base_size = 10)

save_fig_pub(04$NAME, "04_pain_neighbours", width = 11, height = 5.5)
cat("\n[OK] 04 outputs saved.\n")
