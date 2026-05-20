#!/usr/bin/env Rscript
# build_gee_table3.R
# ------------------------------------------------------------
# Generalised estimating equations (GEE, exchangeable working
# correlation, IPW weights) for longitudinal Pain score.
#
# Builds "Table 3 - Base + Adjusted" matching the prior paper:
#   Base     : Pain ~ time + trajectory + time:trajectory
#   Adjusted : Base + UPDRS-III + LEDD + BMI + Sex + GDS + STAI
#
# Reference level for trajectory = "Never-DBS"
# Time unit = months from DBS / index anchor.
# id = PATNO, corstr = exchangeable, weights = weight_sw_trim90
# ------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(geepack); library(knitr)
})
source("helpers/pain_helpers.R")

# ---- Load matched long ------------------------------------
df_long <- readRDS(file.path(OUT_OBJ, "pain_long.rds")) %>%
  dplyr::mutate(
    # Signed calendar months from anchor (fix for the time_pos artifact:
    # unsigned time_pos_months made Pre-DBS time axis run backward relative
    # to Post-DBS, distorting the time:traj interaction).
    time_m = time_days / DAYS_PER_MONTH,
    traj   = factor(traj, levels = c("Never-DBS", "Pre-DBS", "Post-DBS"))
  ) %>%
  dplyr::arrange(PATNO, time_m)

cat("Rows:", nrow(df_long),
    " Patients:", dplyr::n_distinct(df_long$PATNO), "\n")
cat("Trajectory N:\n"); print(table(df_long$traj, useNA = "ifany"))

# ---- Keep complete cases for adjusted covariates ----------
cov_vars <- c("updrs3_score","LEDD","BMI","SEX","gds","stai")
have <- intersect(cov_vars, names(df_long))
missing_vars <- setdiff(cov_vars, names(df_long))
if (length(missing_vars) > 0) {
  stop("Missing covariates: ", paste(missing_vars, collapse = ", "))
}

# GEE requires no NA in the model frame; also needs PATNO ordered.
base_df <- df_long %>%
  dplyr::filter(!is.na(NP1PAIN), !is.na(time_m), !is.na(traj),
                !is.na(weight_sw_trim90)) %>%
  dplyr::arrange(PATNO, time_m)

adj_df <- df_long %>%
  dplyr::filter(!is.na(NP1PAIN), !is.na(time_m), !is.na(traj),
                !is.na(weight_sw_trim90)) %>%
  dplyr::filter(dplyr::if_all(dplyr::all_of(have), ~ !is.na(.x))) %>%
  dplyr::mutate(SEX = factor(SEX)) %>%
  dplyr::arrange(PATNO, time_m)

cat("\nBase model     : rows =", nrow(base_df),
    " patients =", dplyr::n_distinct(base_df$PATNO), "\n")
cat("Adjusted model : rows =", nrow(adj_df),
    " patients =", dplyr::n_distinct(adj_df$PATNO), "\n")

# ---- Fit models -------------------------------------------
f_base <- NP1PAIN ~ time_m * traj
f_adj  <- NP1PAIN ~ time_m * traj + updrs3_score + LEDD + BMI + SEX + gds + stai

m_base <- geepack::geeglm(
  f_base,
  id       = PATNO,
  data     = base_df,
  family   = gaussian(),
  corstr   = "exchangeable",
  weights  = weight_sw_trim90
)

m_adj <- geepack::geeglm(
  f_adj,
  id       = PATNO,
  data     = adj_df,
  family   = gaussian(),
  corstr   = "exchangeable",
  weights  = weight_sw_trim90
)

cat("\n--- Base model summary ---\n");     print(summary(m_base))
cat("\n--- Adjusted model summary ---\n"); print(summary(m_adj))

# ---- Pull coefficient table with 95% CI -------------------
gee_coef_tbl <- function(m) {
  s  <- summary(m)
  co <- as.data.frame(s$coefficients)
  # geeglm coefs: Estimate, Std.err, Wald, Pr(>|W|)
  names(co)[names(co) == "Std.err"] <- "SE"
  names(co)[names(co) == "Pr(>|W|)"] <- "p"
  co$term  <- rownames(co)
  co$lower <- co$Estimate - 1.96 * co$SE
  co$upper <- co$Estimate + 1.96 * co$SE
  tibble::as_tibble(co)
}

tbl_base <- gee_coef_tbl(m_base)
tbl_adj  <- gee_coef_tbl(m_adj)

readr::write_csv(tbl_base, file.path(OUT_TAB, "gee_base_coef.csv"))
readr::write_csv(tbl_adj,  file.path(OUT_TAB, "gee_adjusted_coef.csv"))

# ---- Rename predictors for display -----------------------
# Reference = Never-DBS.
pretty_name <- function(x) {
  x <- gsub("trajPre-DBS",        "Phase [Pre-DBS vs Never-DBS]",   x, fixed = TRUE)
  x <- gsub("trajPost-DBS",       "Phase [Post-DBS vs Never-DBS]",  x, fixed = TRUE)
  x <- gsub("time_m:trajPre-DBS", "Time x Phase [Pre-DBS]",          x, fixed = TRUE)
  x <- gsub("time_m:trajPost-DBS","Time x Phase [Post-DBS]",         x, fixed = TRUE)
  x <- gsub("time_m",       "Time (months)", x, fixed = TRUE)
  x <- gsub("\\(Intercept\\)", "Intercept", x)
  x <- gsub("updrs3_score", "UPDRS-III",     x, fixed = TRUE)
  x <- gsub("LEDD",         "LEDD",          x, fixed = TRUE)
  x <- gsub("BMI",          "BMI",           x, fixed = TRUE)
  x <- gsub("SEXM",         "Sex [Male]",    x, fixed = TRUE)
  x <- gsub("SEXMale",      "Sex [Male]",    x, fixed = TRUE)
  x <- gsub("SEX1",         "Sex [Male]",    x, fixed = TRUE)
  x <- gsub("gds",          "GDS",           x, fixed = TRUE)
  x <- gsub("stai",         "STAI",          x, fixed = TRUE)
  x
}

fmt_est_ci <- function(est, lo, hi) sprintf("%+.3f [%+.3f, %+.3f]", est, lo, hi)
fmt_p      <- function(p) ifelse(p < 0.001, "< 0.001", sprintf("%.3f", p))

base_pretty <- tbl_base %>%
  dplyr::transmute(term,
                   Predictor = pretty_name(term),
                   Base      = fmt_est_ci(Estimate, lower, upper),
                   `Base P`  = fmt_p(p))

adj_pretty <- tbl_adj %>%
  dplyr::transmute(term,
                   Predictor = pretty_name(term),
                   Adjusted  = fmt_est_ci(Estimate, lower, upper),
                   `Adjusted P` = fmt_p(p))

# ---- Merge side-by-side into Table 3 ----------------------
# Order rows to match the Google-Doc screenshot:
#   Intercept, Time, Phase[Pre], Phase[Post],
#   UPDRS-III, LEDD, BMI, Sex, GDS, STAI,
#   Time x Phase[Pre], Time x Phase[Post]
row_order <- c(
  "(Intercept)",
  "time_m",
  "trajPre-DBS",
  "trajPost-DBS",
  "updrs3_score",
  "LEDD",
  "BMI",
  "SEXM", "SEX1", "SEXMale",
  "gds",
  "stai",
  "time_m:trajPre-DBS",
  "time_m:trajPost-DBS"
)

tbl3 <- dplyr::full_join(
  base_pretty %>% dplyr::select(-Predictor),
  adj_pretty  %>% dplyr::select(-Predictor),
  by = "term"
) %>%
  dplyr::mutate(Predictor = pretty_name(term)) %>%
  dplyr::mutate(ord = match(term, row_order),
                ord = dplyr::coalesce(ord, 999L)) %>%
  dplyr::arrange(ord) %>%
  dplyr::select(Predictor, Base, `Base P`, Adjusted, `Adjusted P`) %>%
  dplyr::mutate(dplyr::across(dplyr::everything(), ~ ifelse(is.na(.x), "\u2014", .x)))

print(tbl3)

# ---- Save outputs -----------------------------------------
readr::write_csv(tbl3, file.path(OUT_TAB, "gee_table3_base_vs_adjusted.csv"))

tbl3_html <- knitr::kable(
  tbl3, format = "html", escape = FALSE, align = "l",
  caption = paste0(
    "Table 3. GEE (exchangeable working correlation, IPW-weighted) for ",
    "longitudinal Pain score. Reference phase = Never-DBS. ",
    "Estimates are change in Pain score per unit predictor ",
    "(per month for Time; per SD for continuous covariates after the ",
    "model's native scale). Base model: time x trajectory only. ",
    "Adjusted: additionally controls for UPDRS-III, LEDD, BMI, sex, GDS, STAI."
  )
)
writeLines(as.character(tbl3_html), file.path(OUT_TAB, "gee_table3.html"))

# ---- Save fitted objects ----------------------------------
saveRDS(list(m_base = m_base, m_adj = m_adj,
             tbl_base = tbl_base, tbl_adj = tbl_adj,
             tbl3 = tbl3),
        file.path(OUT_OBJ, "gee_table3_fits.rds"))

cat("\n[OK] GEE Table 3 written:\n")
cat("  - outputs/tables/gee_base_coef.csv\n")
cat("  - outputs/tables/gee_adjusted_coef.csv\n")
cat("  - outputs/tables/gee_table3_base_vs_adjusted.csv\n")
cat("  - outputs/tables/gee_table3.html\n")
cat("  - outputs/objects/gee_table3_fits.rds\n")
