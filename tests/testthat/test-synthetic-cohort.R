test_that("synthetic cohort meets schema + key invariants", {
  out_csv <- here::here("data-synth", "ppmi_synth_matched_long.csv")
  skip_if_not(file.exists(out_csv), "synth cohort not built — run make synth-data")

  df <- readr::read_csv(out_csv, show_col_types = FALSE)

  required <- c("PATNO", "will_receive_dbs", "INFODT_orig", "NP1PAIN",
                "time_pos", "time_bin", "months", "weight_sw_trim90", "traj")
  expect_true(all(required %in% names(df)))

  pat_arms <- dplyr::distinct(df, PATNO, will_receive_dbs)
  expect_equal(nrow(pat_arms), 1484)
  expect_equal(sum(pat_arms$will_receive_dbs), 105)

  expect_true(all(df$NP1PAIN >= 0 & df$NP1PAIN <= 4))
  expect_true(all(df$weight_sw_trim90 == 1))
  expect_true(all(df$traj %in% c("Pre-DBS", "Post-DBS", "Never-DBS")))

  # CRITICAL regression test: every DBS patient must have BOTH Pre-DBS
  # AND Post-DBS rows. Previously the anchor bug caused all DBS visits
  # to be time_days >= 0 (only Post-DBS).
  dbs_traj <- df |> dplyr::filter(will_receive_dbs) |>
    dplyr::count(traj)
  expect_true("Pre-DBS"  %in% dbs_traj$traj)
  expect_true("Post-DBS" %in% dbs_traj$traj)
  expect_gt(dbs_traj$n[dbs_traj$traj == "Pre-DBS"], 0)
  expect_gt(dbs_traj$n[dbs_traj$traj == "Post-DBS"], 0)
})
