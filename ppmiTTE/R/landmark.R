#' Compute per-patient Δ outcome between baseline and landmark windows
#'
#' @param rel Long data frame (1 row per visit) with `PATNO`,
#'   `will_receive_dbs`, `months`, and the outcome column.
#' @param var Outcome variable name (string).
#' @param pre_win Pre-anchor window as `c(lower, upper)` in months.
#' @param post_win Post-anchor (landmark) window as `c(lower, upper)`.
#' @return Per-patient tibble with `delta = post_mean - pre_mean` and
#'   arm factor.
#' @export
landmark_delta <- function(rel, var = "NP1PAIN",
                           pre_win = c(-24, 0), post_win = c(6, 18)) {
  pre <- rel %>%
    dplyr::filter(months >= pre_win[1], months <= pre_win[2],
                  !is.na(.data[[var]])) %>%
    dplyr::group_by(PATNO, will_receive_dbs) %>%
    dplyr::summarise(pre_mean = mean(.data[[var]]), .groups = "drop")
  post <- rel %>%
    dplyr::filter(months >= post_win[1], months <= post_win[2],
                  !is.na(.data[[var]])) %>%
    dplyr::group_by(PATNO) %>%
    dplyr::summarise(post_mean = mean(.data[[var]]), .groups = "drop")
  dplyr::inner_join(pre, post, by = "PATNO") %>%
    dplyr::mutate(
      delta = post_mean - pre_mean,
      arm = factor(dplyr::if_else(will_receive_dbs, "DBS", "Never-DBS"),
                   levels = c("Never-DBS", "DBS"))
    )
}

#' TOST non-inferiority test at margin ±d
#'
#' @param d Per-patient delta tibble (output of `landmark_delta()`).
#' @param margin Non-inferiority margin (positive scalar).
#' @return tibble with diff, 95 % CI, TOST P_lower, P_upper, NI verdict.
#' @export
tost_non_inferiority <- function(d, margin = 1) {
  tt <- stats::t.test(d$delta[d$arm == "DBS"],
                      d$delta[d$arm == "Never-DBS"])
  est <- unname(tt$estimate[1] - tt$estimate[2])
  ci  <- unname(tt$conf.int)
  tt_l <- stats::t.test(d$delta[d$arm == "DBS"] + margin,
                        d$delta[d$arm == "Never-DBS"],
                        alternative = "greater", var.equal = FALSE)
  tt_u <- stats::t.test(d$delta[d$arm == "DBS"] - margin,
                        d$delta[d$arm == "Never-DBS"],
                        alternative = "less", var.equal = FALSE)
  tibble::tibble(
    n_dbs    = sum(d$arm == "DBS"),
    n_ctrl   = sum(d$arm == "Never-DBS"),
    diff     = est,
    ci_lo    = ci[1],
    ci_hi    = ci[2],
    welch_p  = tt$p.value,
    tost_p_lower = tt_l$p.value,
    tost_p_upper = tt_u$p.value,
    tost_p_max   = max(tt_l$p.value, tt_u$p.value),
    tost_NI  = (tt_l$p.value < 0.05) && (tt_u$p.value < 0.05),
    margin   = margin
  )
}
