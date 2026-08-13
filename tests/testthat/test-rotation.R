# Judgmental rotation, pole flips, and renaming.

test_that("orthogonal rotation preserves the latent utilities", {
  fit <- make_fake_fit()
  target <- .summarize_draws(fit$draws$F, mean)[, c(2, 1)]   # swap the factors
  rot <- rotate_factors(fit, target)
  t <- 7
  U0 <- matrix(fit$draws$F[t, , ], 10, 2) %*%
    t(matrix(fit$draws$Lambda[t, , ], 6, 2))
  U1 <- matrix(rot$draws$F[t, , ], 10, 2) %*%
    t(matrix(rot$draws$Lambda[t, , ], 6, 2))
  expect_equal(U0, U1, tolerance = 1e-10)
  expect_identical(rot$align$rotated, "orthogonal target")
})

test_that("oblique rotation preserves the latent utilities", {
  fit <- make_fake_fit()
  target <- .summarize_draws(fit$draws$F, mean)
  target[, 1] <- target[, 1] + 0.3 * target[, 2]             # oblique mix
  rot <- rotate_factors(fit, target, oblique = TRUE)
  t <- 3
  U0 <- matrix(fit$draws$F[t, , ], 10, 2) %*%
    t(matrix(fit$draws$Lambda[t, , ], 6, 2))
  U1 <- matrix(rot$draws$F[t, , ], 10, 2) %*%
    t(matrix(rot$draws$Lambda[t, , ], 6, 2))
  expect_equal(U0, U1, tolerance = 1e-10)
})

test_that("rotation validates the target shape", {
  fit <- make_fake_fit()
  expect_error(rotate_factors(fit, matrix(0, 3, 2)), "10 x 2")
})

test_that("flip_factor reverses one pole everywhere", {
  fit <- make_fake_fit()
  fl <- flip_factor(fit, "f2")
  expect_identical(fl$draws$F[, , 2], -fit$draws$F[, , 2])
  expect_identical(fl$draws$Lambda[, , 2], -fit$draws$Lambda[, , 2])
  expect_identical(fl$draws$F[, , 1], fit$draws$F[, , 1])
  expect_error(flip_factor(fit, 5), "no such factor")
})

test_that("rename_factors relabels every carrier", {
  fit <- make_fake_fit()
  rn <- rename_factors(fit, c("Optimists", "Skeptics"))
  expect_identical(dimnames(rn$draws$F)[[3]], c("Optimists", "Skeptics"))
  expect_identical(dimnames(rn$draws$sigma)[[2]], c("Optimists", "Skeptics"))
  lo <- compute_loadings(rn)
  expect_true("Optimists_loading" %in% names(lo))
  expect_error(rename_factors(fit, c("a", "a")), "distinct")
})
