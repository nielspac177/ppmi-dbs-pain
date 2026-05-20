test_that("OKABE_ITO palette has 8 distinct hex codes", {
  source(here::here("R/helpers/pain_helpers.R"))
  expect_length(OKABE_ITO, 8)
  expect_equal(length(unique(OKABE_ITO)), 8)
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", OKABE_ITO)))
})

test_that("ARM_COLORS_OK contains DBS and Never-DBS", {
  source(here::here("R/helpers/pain_helpers.R"))
  expect_true(all(c("DBS", "Never-DBS") %in% names(ARM_COLORS_OK)))
})

test_that("DAYS_PER_MONTH is precisely 365.25/12", {
  source(here::here("R/helpers/pain_helpers.R"))
  expect_equal(DAYS_PER_MONTH, 365.25 / 12)
})
