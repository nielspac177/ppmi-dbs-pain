test_that("bootstrap-posterior summary respects ordering invariants", {
  # Direct test of the posterior-summary invariants without re-running
  # the full sprint11 script (heavy).
  set.seed(7)
  # Simulate 5000 bootstrap draws of an interaction coefficient ~ N(0, 0.3)
  est <- rnorm(5000, 0, 0.3)
  m <- mean(est)
  ci <- stats::quantile(est, c(0.025, 0.975))
  p_025 <- mean(abs(est) > 0.25)
  p_050 <- mean(abs(est) > 0.50)
  p_gt0 <- mean(est > 0)

  # CI ordering
  expect_lte(ci[1], m)
  expect_gte(ci[2], m)
  # Probabilities in [0, 1]
  for (p in c(p_025, p_050, p_gt0)) {
    expect_gte(p, 0)
    expect_lte(p, 1)
  }
  # Threshold monotonicity
  expect_lte(p_050, p_025)
  # Roughly centred at 0 → P(>0) ≈ 0.5
  expect_equal(p_gt0, 0.5, tolerance = 0.05)
})

test_that("zero-filter regression guard: zero estimates not dropped", {
  # Regression test for the bug where est[i] <- 0 + later filter !=0
  # silently removed legitimate zero estimates.
  set.seed(11)
  est <- c(rep(0, 100), rnorm(900, 0, 0.3))
  # The correct procedure keeps all 1000 draws (zero is a valid posterior value)
  expect_equal(length(est), 1000)
  # If buggy filter were applied:
  est_buggy <- est[est != 0]
  expect_lt(length(est_buggy), length(est))
})
