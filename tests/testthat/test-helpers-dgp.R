test_that("generate_loadings produces an N x K matrix in [-1, 1]-ish range", {
  set.seed(1L)
  L <- generate_loadings(N = 30, K = 3, type = "simple")
  expect_equal(dim(L), c(30, 3))
  expect_true(all(abs(L) <= 1))
})

test_that("generate_loadings with complex type adds secondary loadings for some participants", {
  set.seed(1L)
  L <- generate_loadings(N = 30, K = 3, type = "complex")
  # At least some participants have two moderate loadings
  n_complex <- sum(apply(abs(L), 1, function(r) sum(r > 0.2) >= 2))
  expect_gt(n_complex, 0L)
})

test_that("generate_noise returns a J x N matrix for each error type", {
  set.seed(1L)
  for (type in c("normal", "t", "contaminated")) {
    E <- generate_noise(J = 10, N = 5, type = type)
    expect_equal(dim(E), c(10, 5))
  }
})

test_that("generate_noise rejects an unknown error type", {
  expect_error(generate_noise(J = 5, N = 5, type = "nope"),
               "Unknown error type")
})

test_that("assess_recovery compares estimate to truth and returns metrics", {
  set.seed(1L)
  Ltrue <- generate_loadings(N = 25, K = 2)
  Lhat  <- Ltrue + matrix(rnorm(50, 0, 0.05), 25, 2)
  res <- assess_recovery(Lhat, Ltrue)
  expect_true(is.finite(res$rmse))
  expect_length(res$rmse_factor, 2)
  expect_length(res$tucker, 2)
  expect_true(all(res$tucker > 0.9))
})

test_that("assess_recovery with posterior draws returns coverage and interval score", {
  set.seed(1L)
  Ltrue <- generate_loadings(N = 15, K = 2)
  T     <- 120
  draws <- array(rep(c(Ltrue), each = T), c(T, 15, 2)) +
           array(rnorm(T * 15 * 2, 0, 0.1), c(T, 15, 2))
  Lhat  <- apply(draws, c(2, 3), mean)
  res <- assess_recovery(Lhat, Ltrue, Lambda_draws = draws, prob = 0.9)
  expect_true(is.finite(res$coverage))
  expect_true(is.finite(res$ci_width))
  expect_true(is.finite(res$interval_score))
  expect_true(res$coverage >= 0 && res$coverage <= 1)
})

test_that("assess_classification with all TRUE flags recovers the true partition", {
  set.seed(1L)
  Ltrue <- generate_loadings(N = 12, K = 3)
  true_assign <- apply(abs(Ltrue), 1, which.max)
  flags <- matrix(FALSE, 12, 3)
  for (i in seq_len(12)) flags[i, true_assign[i]] <- TRUE
  res <- assess_classification(flags, Ltrue)
  expect_equal(res$accuracy, 1)
})

test_that("procrustes_rotation attaches the rotation matrix", {
  set.seed(1L)
  T <- matrix(rnorm(20), 10, 2)
  X <- T %*% qr.Q(qr(matrix(rnorm(4), 2, 2)))
  out <- procrustes_rotation(X, T)
  R <- attr(out, "rotation")
  expect_equal(dim(R), c(2, 2))
  expect_lt(max(abs(crossprod(R) - diag(2))), 1e-8)
})

test_that("tucker_congruence handles zero-norm inputs safely", {
  expect_true(is.na(tucker_congruence(c(0, 0), c(1, 2))))
  expect_true(is.na(tucker_congruence(c(1, 2), c(0, 0))))
})
