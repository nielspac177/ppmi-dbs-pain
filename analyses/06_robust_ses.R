#!/usr/bin/env Rscript
# 06_robust_ses.R
# ------------------------------------------------------------
# (a) Cluster-robust SEs on the primary LMMs (m_A = Pre/Post-DBS,
#     m_B = Post-DBS vs Never-DBS), patient-clustered.
# (b) GEE sensitivity: refit Table 3 with AR(1) working correlation
#     vs the original exchangeable.
# ------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(purrr); library(tibble)
  library(lme4); library(emmeans); library(clubSandwich); library(geepack)
})
source("helpers/pain_helpers.R")
set.seed(20260519)

# ============================================================
# (a) Cluster-robust SEs on the primary LMMs
# ============================================================
fits <- readRDS("outputs/objects/fig5_lmm_fits.rds")
m_A <- fits$m_A
m_B <- fits$m_B
cat("(a) Cluster-robust SE on m_A and m_B (CR2)\n")

# Fixed-effects table with model-based vs cluster-robust SEs.
# clubSandwich::vcovCR does not support lme4 models with `weights = ...`;
# refit unweighted as a sensitivity (this changes interpretation but is
# the standard way to obtain CR2 SEs for the slope contrasts).
robust_table <- function(fit, label) {
  fe <- summary(fit)$coefficients

  # Refit unweighted on the same data + formula for robust-SE comparison
  fit_uw <- tryCatch(
    lme4::lmer(formula(fit), data = fit@frame,
               REML = TRUE,
               control = lme4::lmerControl(check.conv.singular = "ignore")),
    error = function(e) {
      cat("  unweighted refit failed:", conditionMessage(e), "\n")
      NULL
    })

  if (is.null(fit_uw)) {
    return(tibble::tibble(model = label, coef = rownames(fe),
                          estimate = unname(fe[, "Estimate"]),
                          se_model_weighted = unname(fe[, "Std. Error"]),
                          se_model_unweighted = NA_real_,
                          se_robust = NA_real_))
  }
  fe_uw <- summary(fit_uw)$coefficients

  vcr <- tryCatch(
    clubSandwich::vcovCR(fit_uw, type = "CR2",
                         cluster = fit_uw@frame$PATNO),
    error = function(e) {
      cat("  CR2 failed for", label, ":", conditionMessage(e), "\n"); NULL
    })
  if (is.null(vcr)) return(NULL)

  cr_se <- sqrt(diag(vcr))
  test_df <- tryCatch(
    clubSandwich::coef_test(fit_uw, vcov = "CR2",
                            cluster = fit_uw@frame$PATNO),
    error = function(e) NULL)

  tibble::tibble(
    model               = label,
    coef                = rownames(fe),
    estimate_weighted   = unname(fe[, "Estimate"]),
    se_model_weighted   = unname(fe[, "Std. Error"]),
    estimate_unweighted = unname(fe_uw[, "Estimate"]),
    se_model_unweighted = unname(fe_uw[, "Std. Error"]),
    se_robust_unweighted = unname(cr_se),
    p_robust_unweighted = if (!is.null(test_df)) test_df$p_Satt else NA
  )
}

robust_tbl <- dplyr::bind_rows(
  robust_table(m_A, "m_A (Pre vs Post-DBS phase)"),
  robust_table(m_B, "m_B (Post-DBS vs Never-DBS)")
)
options(width = 200)
print(robust_tbl)
save_table(06$NAME, "06_lmm_robust_se")

# ============================================================
# (b) GEE AR(1) sensitivity
# ============================================================
gee_fits <- readRDS("outputs/objects/gee_table3_fits.rds")
m_base  <- gee_fits$m_base
m_adj   <- gee_fits$m_adj

# Reconstruct the formulas + data
form_base <- formula(m_base)
form_adj  <- formula(m_adj)
data_base <- m_base$data
data_adj  <- m_adj$data

cat("\n(b) GEE AR(1) vs exchangeable sensitivity\n")
fit_ar1_safely <- function(form, data, label) {
  # geepack requires data sorted by id and visit
  data <- data %>% dplyr::arrange(PATNO, time_m)
  tryCatch({
    fit <- geepack::geeglm(form, id = PATNO, data = data,
                           corstr = "ar1", family = stats::gaussian())
    s <- summary(fit)$coefficients
    s <- as.data.frame(s)
    s$coef <- rownames(s)
    s$corstr <- "ar1"
    s$model  <- label
    s
  }, error = function(e) {
    cat("  AR(1) failed for", label, ":", conditionMessage(e), "\n"); NULL
  })
}

ar1_base <- fit_ar1_safely(form_base, data_base, "base")
ar1_adj  <- fit_ar1_safely(form_adj,  data_adj,  "adj")

# Exchangeable (original) for comparison
ex_base <- as.data.frame(summary(m_base)$coefficients)
ex_base$coef <- rownames(ex_base); ex_base$corstr <- "exchangeable"; ex_base$model <- "base"
ex_adj  <- as.data.frame(summary(m_adj)$coefficients)
ex_adj$coef <- rownames(ex_adj); ex_adj$corstr <- "exchangeable"; ex_adj$model <- "adj"

# Filter out NULL fits
rows <- list(ex_base, ar1_base, ex_adj, ar1_adj)
rows <- rows[!vapply(rows, is.null, logical(1))]
gee_sens <- dplyr::bind_rows(rows) %>%
  tibble::as_tibble() %>%
  dplyr::select(model, corstr, coef, Estimate, `Std.err`, Wald, `Pr(>|W|)`) %>%
  dplyr::rename(estimate = Estimate, se = `Std.err`, wald = Wald,
                p_value = `Pr(>|W|)`) %>%
  dplyr::mutate(across(c(estimate, se, wald, p_value), as.numeric))
options(width = 200)
print(as.data.frame(gee_sens))
save_table(06$NAME, "06_gee_corstr_sens")

# Focus: just the time*traj interactions (the headline rows)
focus <- gee_sens %>%
  dplyr::filter(grepl("time.*traj|traj.*time|^traj|^time", coef))
cat("\nFocus on time × traj interactions:\n")
print(as.data.frame(focus))

cat("\n[OK] 06 outputs saved.\n")
