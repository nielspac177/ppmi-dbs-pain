test_that("TOST non-inferiority correctly rejects/accepts", {
  set.seed(42)
  n <- 200
  # Same-distribution arms (true Δ ≈ 0): should reject NI at margin = 0.5
  delta_dbs  <- rnorm(n, 0, 0.6)
  delta_ctrl <- rnorm(n, 0, 0.6)

  m <- 0.5
  tt_l <- stats::t.test(delta_dbs + m, delta_ctrl,
                        alternative = "greater")
  tt_u <- stats::t.test(delta_dbs - m, delta_ctrl,
                        alternative = "less")
  expect_lt(tt_l$p.value, 0.05)
  expect_lt(tt_u$p.value, 0.05)

  # DBS arm shifted by +1 SD: NI at margin = 0.5 should NOT hold
  delta_dbs_shifted <- rnorm(n, 0.6, 0.6)
  tt_u2 <- stats::t.test(delta_dbs_shifted - m, delta_ctrl,
                         alternative = "less")
  expect_gt(tt_u2$p.value, 0.05)
})
