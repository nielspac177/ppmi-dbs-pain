#' Compute symmetric-midpoint anchors for Never-DBS controls
#'
#' For each Never-DBS patient, compute the midpoint of their observed
#' follow-up window (`(first_visit + last_visit) / 2`). DBS patients
#' retain their existing `anchor_date` (first surgery).
#'
#' Critically, this function casts POSIXct to Date *before* arithmetic,
#' which fixes a long-standing bug where POSIXct + numeric added seconds
#' rather than days, collapsing the midpoint to the first visit.
#'
#' @param rel_raw A long data frame with columns `PATNO`, `INFODT_orig`
#'   (POSIXct or Date), `will_receive_dbs` (logical), `anchor_date`
#'   (DBS arm only).
#' @return A data frame with `PATNO` and `anchor_date` per patient.
#' @export
compute_symmetric_midpoint_anchors <- function(rel_raw) {
  dbs_a <- rel_raw %>%
    dplyr::filter(will_receive_dbs, !is.na(anchor_date)) %>%
    dplyr::distinct(PATNO, anchor_date)
  ctl_a <- rel_raw %>%
    dplyr::filter(!will_receive_dbs, !is.na(INFODT_orig)) %>%
    dplyr::group_by(PATNO) %>%
    dplyr::summarise(
      anchor_date = {
        f <- as.Date(min(INFODT_orig, na.rm = TRUE))
        l <- as.Date(max(INFODT_orig, na.rm = TRUE))
        f + as.numeric(difftime(l, f, units = "days")) / 2
      },
      .groups = "drop"
    )
  dplyr::bind_rows(dbs_a, ctl_a) %>%
    dplyr::distinct(PATNO, .keep_all = TRUE)
}

#' Rebind time columns relative to a fresh anchor table
#'
#' @param rel_raw Long data frame.
#' @param anchors `PATNO` × `anchor_date` table from
#'   `compute_symmetric_midpoint_anchors()`.
#' @return Long data frame with rebuilt `time_days`, `time_months`,
#'   `time_bin`, and `months` columns.
#' @export
rebind_time_cols <- function(rel_raw, anchors) {
  rel_raw %>%
    dplyr::select(-dplyr::any_of(c(
      "anchor_date", "time_days", "time_pos",
      "time_pos_months", "months", "time_bin"))) %>%
    dplyr::left_join(anchors, by = "PATNO") %>%
    dplyr::filter(!is.na(anchor_date)) %>%
    dplyr::mutate(
      time_days   = as.numeric(difftime(as.Date(INFODT_orig),
                                        as.Date(anchor_date),
                                        units = "days")),
      time_months = time_days / (365.25 / 12),
      time_bin    = floor(time_days / 180),
      months      = time_bin * 6
    ) %>%
    dplyr::filter(is.finite(time_bin))
}
