#' Propensity-score match with sensible defaults
#'
#' @param data Per-patient data frame.
#' @param treat_col Treatment column name (character).
#' @param covariates Covariate column names (character vector).
#' @param ratio Match ratio (default 2 → 1:2 nearest-neighbour).
#' @param caliper Caliper as SD of the logit propensity (default 0.2).
#' @return A `MatchIt::matchit` object.
#' @export
propensity_match <- function(data, treat_col = "will_receive_dbs",
                             covariates = c("age_at_visit", "SEX",
                                            "duration_yrs", "updrs3_score",
                                            "NHY", "LEDD", "BMI"),
                             ratio = 2, caliper = 0.2) {
  form <- stats::as.formula(paste(treat_col, "~",
                                   paste(covariates, collapse = " + ")))
  MatchIt::matchit(form, data = data, method = "nearest",
                   ratio = ratio, caliper = caliper, replace = FALSE)
}
