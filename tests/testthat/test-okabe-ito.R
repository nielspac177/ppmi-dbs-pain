test_that("Okabe-Ito palette + theme + save helper", {
  source(here::here("R/helpers/pain_helpers.R"))

  # 8 distinct colourblind-safe hex codes
  expect_length(OKABE_ITO, 8)
  expect_equal(length(unique(OKABE_ITO)), 8)
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", OKABE_ITO)))

  # Arm + trajectory palettes use only Okabe-Ito values
  expect_true(all(ARM_COLORS_OK %in% OKABE_ITO))
  expect_true(all(TRAJ_COLORS_OK %in% OKABE_ITO))

  # theme_pain_pub returns a ggplot theme
  th <- theme_pain_pub()
  expect_s3_class(th, "theme")

  # DAYS_PER_MONTH precision
  expect_equal(DAYS_PER_MONTH, 365.25 / 12)
})
