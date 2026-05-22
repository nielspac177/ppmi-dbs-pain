test_that("%||% returns LHS when non-null/non-empty, RHS otherwise", {
  source(here::here("R/helpers/pain_helpers.R"))
  expect_equal("a" %||% "b", "a")
  expect_equal(NULL %||% "b", "b")
  expect_equal(character(0) %||% "b", "b")
  expect_equal(integer(0) %||% 99L, 99L)
  expect_equal(list() %||% "fallback", "fallback")
  # Length-1 falsy values should still pass through
  expect_equal(FALSE %||% TRUE, FALSE)
  expect_equal(0 %||% 1, 0)
})
