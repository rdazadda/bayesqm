test_that("tucker_congruence is 1 on identical vectors and 0 on orthogonal ones", {
  expect_equal(tucker_congruence(c(1, 2, 3), c(1, 2, 3)), 1)
  expect_equal(tucker_congruence(c(1, 0),   c(0, 1)),     0)
})

test_that("procrustes_rotation recovers the target up to sign / rotation", {
  set.seed(1L)
  Target <- matrix(rnorm(30), 10, 3)
  R_true <- qr.Q(qr(matrix(rnorm(9), 3, 3)))
  X      <- Target %*% t(R_true)
  out    <- procrustes_rotation(X, Target)
  expect_lt(max(abs(out - Target)), 1e-8)
  expect_true(!is.null(attr(out, "rotation")))
})

test_that("matchalign runs on tiny draws with K = 1 (no GPArotation needed)", {
  set.seed(1L)
  L <- array(rnorm(6 * 4 * 1), c(6, 4, 1))
  Fd <- array(rnorm(6 * 5 * 1), c(6, 5, 1))
  al <- matchalign(L, Fd)
  expect_equal(dim(al$Lambda), c(6, 4, 1))
  expect_equal(dim(al$Fmat),   c(6, 5, 1))
})

test_that("matchalign preserves shape for K > 1", {
  skip_if_not_installed("GPArotation")
  set.seed(1L)
  L <- array(rnorm(6 * 4 * 2), c(6, 4, 2))
  Fd <- array(rnorm(6 * 5 * 2), c(6, 5, 2))
  al <- matchalign(L, Fd)
  expect_equal(dim(al$Lambda), c(6, 4, 2))
  expect_equal(dim(al$Fmat),   c(6, 5, 2))
  expect_equal(dim(al$congruence), c(6, 2))
})
