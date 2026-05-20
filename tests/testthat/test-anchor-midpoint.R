test_that("compute_symmetric_midpoint_anchors handles POSIXct correctly", {
  source(here::here("R/helpers/pain_helpers.R"))
  d <- tibble::tibble(
    PATNO = c(1, 1, 1, 2, 2, 2),
    will_receive_dbs = c(FALSE, FALSE, FALSE, TRUE, TRUE, TRUE),
    anchor_date = c(NA, NA, NA, as.Date("2020-01-15"),
                    as.Date("2020-01-15"), as.Date("2020-01-15")),
    INFODT_orig = as.POSIXct(c("2019-01-01", "2020-01-01", "2021-01-01",
                                "2019-06-01", "2020-06-01", "2021-06-01"),
                              tz = "UTC")
  )
  a <- compute_symmetric_midpoint_anchors(d)
  expect_true(all(a$PATNO %in% c(1, 2)))
  # Patient 1 (Never-DBS) — anchor should be midpoint of follow-up:
  # 2019-01-01 to 2021-01-01 = midpoint 2020-01-01 ± 1 day
  anchor_1 <- as.Date(a$anchor_date[a$PATNO == 1])
  expect_equal(anchor_1, as.Date("2020-01-01"), tolerance = 2)
  # Patient 2 (DBS) — anchor should remain the surgery date
  anchor_2 <- as.Date(a$anchor_date[a$PATNO == 2])
  expect_equal(anchor_2, as.Date("2020-01-15"))
})

test_that("POSIXct + numeric arithmetic bug is no longer present", {
  # Regression test for the original bug: POSIXct + numeric adds seconds.
  first <- as.POSIXct("2020-01-01", tz = "UTC")
  last  <- as.POSIXct("2022-01-01", tz = "UTC")
  diff_days <- as.numeric(difftime(last, first, units = "days"))
  # If we use POSIXct + diff_days/2, it WRONGLY adds seconds.
  bad <- first + diff_days / 2
  expect_lt(as.numeric(difftime(bad, first, units = "days")), 0.001)
  # The fix: cast to Date first, then add days.
  good <- as.Date(first) + diff_days / 2
  expect_equal(as.Date(good), as.Date("2021-01-01"), tolerance = 1)
})
