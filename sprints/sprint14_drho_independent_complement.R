#!/usr/bin/env Rscript
# sprint14_drho_independent_complement.R
# ------------------------------------------------------------
# Reviewer comment #6 — the directional consistency between matched-
# cohort and full-cohort Δρ is partly artefactual because the full
# cohort *contains* the matched controls. Compute Δρ in the
# *unmatched non-overlapping complement*: Never-DBS patients NOT
# selected as matched controls (and the full DBS arm).
# ------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(purrr); library(tibble)
  library(here); library(yaml)
})
here::i_am("sprints/sprint14_drho_independent_complement.R")
source(here::here("R/helpers/pain_helpers.R"))
set.seed(20260519)

PRE_WIN  <- c(-24, 0)
POST_WIN <- c(6, 18)
N_BOOT   <- 5000

# Build matched cohort to identify which patients were selected as controls
rel_match_raw <- load_matched_long()
anchors <- compute_symmetric_midpoint_anchors(rel_match_raw)
rel_match <- rebind_time_cols(rel_match_raw, anchors)

matched_patnos <- unique(rel_match$PATNO)
cat("Matched cohort patients:", length(matched_patnos), "\n")

# Full cohort
rel_full <- load_full_ppmi_rel_patient_anchor()
all_patnos <- unique(rel_full$PATNO)

# Unmatched complement = all PPMI patients - matched cohort
unmatched_patnos <- setdiff(all_patnos, matched_patnos)
cat("Unmatched complement patients:", length(unmatched_patnos), "\n")

build_pair_delta <- function(rel, patnos) {
  build1 <- function(var) {
    pre <- rel %>% dplyr::filter(PATNO %in% patnos,
                                  months >= PRE_WIN[1], months <= PRE_WIN[2],
                                  !is.na(.data[[var]])) %>%
      dplyr::group_by(PATNO, will_receive_dbs) %>%
      dplyr::summarise(pre = mean(.data[[var]]), .groups = "drop")
    post <- rel %>% dplyr::filter(PATNO %in% patnos,
                                   months >= POST_WIN[1], months <= POST_WIN[2],
                                   !is.na(.data[[var]])) %>%
      dplyr::group_by(PATNO) %>%
      dplyr::summarise(post = mean(.data[[var]]), .groups = "drop")
    pre %>% dplyr::inner_join(post, by = "PATNO") %>%
      dplyr::mutate(delta = post - pre) %>%
      dplyr::select(PATNO, !!paste0("d_", var) := delta)
  }
  d_pain  <- build1("NP1PAIN")
  d_motor <- build1("updrs3_score")
  d_pain %>% dplyr::inner_join(d_motor, by = "PATNO") %>%
    dplyr::left_join(rel %>% dplyr::distinct(PATNO, will_receive_dbs),
                     by = "PATNO") %>%
    dplyr::mutate(arm = factor(dplyr::if_else(will_receive_dbs, "DBS", "Never-DBS"),
                               levels = c("Never-DBS", "DBS")))
}

d_unm <- build_pair_delta(rel_full, unmatched_patnos)
cat("\nUnmatched-complement Δ-Δ pairs:\n")
print(d_unm %>% dplyr::count(arm))

boot_drho <- function(d, B = N_BOOT) {
  d_dbs <- d %>% dplyr::filter(arm == "DBS")
  d_nd  <- d %>% dplyr::filter(arm == "Never-DBS")
  if (nrow(d_dbs) < 5 || nrow(d_nd) < 5) {
    return(tibble::tibble(rho_dbs = NA, rho_nd = NA,
                          d_rho = NA, d_rho_lo = NA, d_rho_hi = NA,
                          p_2sided = NA, msg = "insufficient n"))
  }
  d_rho_b <- numeric(B)
  for (i in seq_len(B)) {
    s_d <- d_dbs[sample(nrow(d_dbs), nrow(d_dbs), replace = TRUE), ]
    s_n <- d_nd[sample(nrow(d_nd),  nrow(d_nd),  replace = TRUE), ]
    rd  <- suppressWarnings(stats::cor(s_d$d_NP1PAIN, s_d$d_updrs3_score,
                                       method = "spearman"))
    rn  <- suppressWarnings(stats::cor(s_n$d_NP1PAIN, s_n$d_updrs3_score,
                                       method = "spearman"))
    d_rho_b[i] <- rd - rn
  }
  d_rho_b <- d_rho_b[!is.na(d_rho_b)]
  tibble::tibble(
    rho_dbs = suppressWarnings(stats::cor(d_dbs$d_NP1PAIN, d_dbs$d_updrs3_score, method = "spearman")),
    rho_nd  = suppressWarnings(stats::cor(d_nd$d_NP1PAIN,  d_nd$d_updrs3_score,  method = "spearman")),
    d_rho      = mean(d_rho_b),
    d_rho_lo   = unname(stats::quantile(d_rho_b, 0.025)),
    d_rho_hi   = unname(stats::quantile(d_rho_b, 0.975)),
    p_2sided   = 2 * min(mean(d_rho_b > 0), mean(d_rho_b < 0))
  )
}

cat("\nBootstrap Δρ in unmatched complement (B =", N_BOOT, ")…\n")
res_unm <- boot_drho(d_unm) %>%
  dplyr::mutate(cohort = "unmatched_complement",
                n_dbs = sum(d_unm$arm == "DBS"),
                n_ctrl = sum(d_unm$arm == "Never-DBS"),
                .before = 1)

# Also re-run on the matched cohort as comparator
d_match <- build_pair_delta(rel_match, matched_patnos) %>%
  dplyr::rename(d_NP1PAIN = d_NP1PAIN, d_updrs3_score = d_updrs3_score)
res_mat <- boot_drho(d_match) %>%
  dplyr::mutate(cohort = "matched",
                n_dbs = sum(d_match$arm == "DBS"),
                n_ctrl = sum(d_match$arm == "Never-DBS"),
                .before = 1)

res <- dplyr::bind_rows(res_mat, res_unm)
print(res)
save_table(res, "sprint14_drho_independent")

# Plot
p <- ggplot(res, aes(x = d_rho, y = cohort)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey55") +
  geom_errorbarh(aes(xmin = d_rho_lo, xmax = d_rho_hi),
                 height = 0.15, linewidth = 0.8,
                 colour = unname(OKABE_ITO["blue"])) +
  geom_point(size = 4, colour = unname(OKABE_ITO["blue"])) +
  geom_text(aes(label = sprintf("Δρ = %+.3f (%.3f, %.3f) | n=%d/%d",
                                d_rho, d_rho_lo, d_rho_hi, n_dbs, n_ctrl)),
            hjust = -0.05, vjust = -1.0, size = 3.2, colour = "grey25") +
  scale_x_continuous("Δρ (DBS − Never-DBS), bootstrap mean ± 95 % CI",
                     limits = c(-0.8, 0.8)) +
  labs(title = "Bootstrap Δρ — matched vs unmatched-complement (independent replication)",
       y = NULL) +
  theme_pain_pub(base_size = 11)
save_fig_pub(p, "sprint14_drho_independent", width = 10, height = 4)
cat("\n[OK] sprint14 outputs saved.\n")
