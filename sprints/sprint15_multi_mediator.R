#!/usr/bin/env Rscript
# sprint15_multi_mediator.R
# ------------------------------------------------------------
# Reviewer comment #7 — the ΔLEDD-only mediation framing is too
# strong. Test alternative single-mediator candidates: ΔLEDD,
# ΔNHY (Hoehn & Yahr stage), ΔGDS (Geriatric Depression), ΔSCOPA
# (autonomic burden), ΔESS (Epworth Sleepiness).
# ------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(purrr); library(tibble)
  library(here); library(yaml); library(mediation)
})
here::i_am("sprints/sprint15_multi_mediator.R")
source(here::here("R/helpers/pain_helpers.R"))
set.seed(20260519)

PRE_WIN  <- c(-24, 0)
POST_WIN <- c(6, 18)

rel <- load_full_ppmi_rel_patient_anchor()

# Helper: build Δ for any variable
delta_var <- function(rel, var) {
  pre <- rel %>%
    dplyr::filter(months >= PRE_WIN[1], months <= PRE_WIN[2],
                  !is.na(.data[[var]])) %>%
    dplyr::group_by(PATNO) %>%
    dplyr::summarise(pre = mean(.data[[var]]), .groups = "drop")
  post <- rel %>%
    dplyr::filter(months >= POST_WIN[1], months <= POST_WIN[2],
                  !is.na(.data[[var]])) %>%
    dplyr::group_by(PATNO) %>%
    dplyr::summarise(post = mean(.data[[var]]), .groups = "drop")
  pre %>% dplyr::inner_join(post, by = "PATNO") %>%
    dplyr::mutate(d = post - pre) %>%
    dplyr::select(PATNO, !!paste0("d_", var) := d)
}

candidates <- c("LEDD", "NHY", "gds", "scopa", "ess",
                "updrs3_score")
mediator_dfs <- purrr::map(candidates, function(v) delta_var(rel, v))
names(mediator_dfs) <- candidates

# Δ Pain + arm
d_pain <- delta_var(rel, "NP1PAIN") %>%
  dplyr::left_join(rel %>% dplyr::distinct(PATNO, will_receive_dbs),
                   by = "PATNO") %>%
  dplyr::mutate(
    arm_int = as.integer(will_receive_dbs),
    arm = factor(dplyr::if_else(will_receive_dbs, "DBS", "Never-DBS"),
                 levels = c("Never-DBS", "DBS"))
  )

run_mediation <- function(med_name, sims = 1000) {
  cat("  ", med_name, " mediator…\n", sep = "")
  med_d <- mediator_dfs[[med_name]]
  joined <- d_pain %>% dplyr::inner_join(med_d, by = "PATNO") %>%
    tidyr::drop_na()
  med_col <- paste0("d_", med_name)
  if (nrow(joined) < 30) {
    return(tibble::tibble(mediator = med_name,
                          n = nrow(joined),
                          ACME = NA, ACME_lo = NA, ACME_hi = NA, ACME_p = NA,
                          ADE = NA, ADE_lo = NA, ADE_hi = NA, ADE_p = NA,
                          total = NA, total_p = NA, prop_mediated = NA))
  }
  # Static frame: rename the mediator column to a fixed name so
  # mediation::mediate's bootstrap can resolve the formula reliably.
  df_static <- joined %>%
    dplyr::rename(med_d_var = !!rlang::sym(med_col)) %>%
    dplyr::select(d_NP1PAIN, arm_int, med_d_var)
  med_model <- stats::lm(med_d_var ~ arm_int, data = df_static)
  out_model <- stats::lm(d_NP1PAIN ~ arm_int + med_d_var, data = df_static)
  set.seed(20260519)
  m <- tryCatch(
    mediation::mediate(med_model, out_model,
                       treat = "arm_int", mediator = "med_d_var",
                       boot = TRUE, sims = sims),
    error = function(e) {
      cat("    ERROR:", conditionMessage(e), "\n"); NULL
    })
  if (is.null(m)) {
    return(tibble::tibble(mediator = med_name, n = nrow(joined),
                          ACME = NA, ACME_lo = NA, ACME_hi = NA, ACME_p = NA,
                          ADE = NA, ADE_lo = NA, ADE_hi = NA, ADE_p = NA,
                          total = NA, total_p = NA, prop_mediated = NA))
  }
  tibble::tibble(
    mediator = med_name,
    n = nrow(joined),
    ACME = m$d0, ACME_lo = m$d0.ci[1], ACME_hi = m$d0.ci[2], ACME_p = m$d0.p,
    ADE  = m$z0, ADE_lo  = m$z0.ci[1], ADE_hi  = m$z0.ci[2], ADE_p  = m$z0.p,
    total = m$tau.coef, total_p = m$tau.p,
    prop_mediated = m$n0
  )
}

cat("Running per-mediator mediation analyses (B = 1000)…\n")
res <- purrr::map_dfr(candidates, run_mediation)
print(res)
save_table(res, "sprint15_multi_mediator")

# Forest plot of ACME per mediator
p <- ggplot(res, aes(x = ACME, y = reorder(mediator, ACME))) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey55") +
  geom_errorbarh(aes(xmin = ACME_lo, xmax = ACME_hi),
                 height = 0.15, linewidth = 0.8,
                 colour = unname(OKABE_ITO["orange"])) +
  geom_point(size = 3.8, colour = unname(OKABE_ITO["orange"])) +
  geom_text(aes(label = sprintf("ACME = %+.3f, P = %.3f, n = %d",
                                ACME, ACME_p, n)),
            hjust = -0.05, vjust = -1.0, size = 3.0, colour = "grey25") +
  scale_x_continuous("Average causal mediation effect on ΔPain (pain points)",
                     limits = c(-0.2, 0.2)) +
  labs(title = "Multi-mediator analysis — single-mediator effects on Δ Pain",
       subtitle = "Each row tests a different candidate mediator independently.",
       y = NULL) +
  theme_pain_pub(base_size = 11)
save_fig_pub(p, "sprint15_multi_mediator", width = 10, height = 5)
cat("\n[OK] sprint15 outputs saved.\n")
