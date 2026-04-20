test_that("run_bayes rejects K_max < 1 before any sampling", {
  Y <- matrix(sample(-2:2, 50, replace = TRUE), nrow = 10, ncol = 5)
  expect_error(run_bayes(Y, K_max = 0),  "positive integer")
  expect_error(run_bayes(Y, K_max = -1), "positive integer")
})

test_that("compute_distinguishing_prob works when K = 2 and J is small", {
  set.seed(1L)
  F_draws <- array(rnorm(100 * 3 * 2), c(100, 3, 2))
  out <- compute_distinguishing_prob(F_draws, delta = 1.0)
  expect_equal(dim(out), c(3, 1))
  expect_true(all(out >= 0 & out <= 1))
})

test_that("compute_consensus_prob returns 1 for every J when K = 1", {
  set.seed(1L)
  F_draws <- array(rnorm(50 * 5 * 1), c(50, 5, 1))
  dimnames(F_draws) <- list(NULL, paste0("S", 1:5), "f1")
  out <- compute_consensus_prob(F_draws)
  expect_length(out, 5)
  expect_true(all(out == 1))
})

test_that("compute_dominant_prob rows sum to 1 across factors", {
  set.seed(1L)
  L <- array(rnorm(200 * 4 * 3), c(200, 4, 3))
  p <- compute_dominant_prob(L)
  expect_true(all(abs(rowSums(p) - 1) < 1e-8))
})

test_that("full posterior-summary pipeline works with K = 1", {
  fit <- make_fake_fit(N = 5, J = 9, K = 1, T = 120)
  loads <- compute_loadings(fit$Lambda_draws)
  zs    <- compute_zscores(fit$F_draws)
  thr   <- compute_threshold_prob(fit$Lambda_draws, threshold = 0.3)
  dom   <- compute_dominant_prob(fit$Lambda_draws)

  expect_equal(nrow(loads), 5)
  expect_equal(nrow(zs),    9)
  expect_equal(dim(thr),    c(5, 1))
  expect_equal(dim(dom),    c(5, 1))
  expect_true(all(dom == 1))  # only one factor to be dominant on
})

test_that("classify_membership returns tiers in the expected order of levels", {
  set.seed(1L)
  # Construct loadings where participant 1 loads strongly on factor 1,
  # participant 2 loads weakly on every factor.
  L <- array(rnorm(300 * 3 * 2), c(300, 3, 2))
  L[, 1, 1] <- L[, 1, 1] + 6    # very strong -> "Strong"
  L[, 2, 1] <- L[, 2, 1] + 0.3  # weak lead
  cls <- classify_membership(L)
  expect_true(all(levels(cls$tier) == c("Strong", "Moderate", "Weak")))
  expect_equal(as.character(cls$tier[1]), "Strong")
})

test_that("compute_posterior_scalars strips NA before summarising", {
  draws <- list(nu = c(rnorm(50, 20, 2), NA, NA),
                sigma = rnorm(52, 1, 0.1),
                all_na = rep(NA_real_, 52))
  out <- compute_posterior_scalars(draws, prob = 0.9)
  # all_na vector should be dropped (zero non-NA entries)
  expect_equal(sort(out$parameter), c("nu", "sigma"))
})

test_that("qsort_data infers distribution from column 1 when NULL", {
  grid <- c(-2, -1, 0, 1, 2)
  Y <- cbind(c(grid, grid), sample(c(grid, grid)))
  obj <- qsort_data(Y)
  expect_equal(obj$distribution, c(2L, 2L, 2L, 2L, 2L))
})

test_that("validate_qsort flags distribution mismatches with a warning message", {
  Y <- matrix(c(-2, -1, 0, 1, 2,
                -2, -2, 0, 0, 2), ncol = 2)  # column 2 not forced
  obj <- suppressMessages(suppressWarnings(
    qsort_data(Y, distribution = c(1, 1, 1, 1, 1), validate = FALSE)))
  v <- validate_qsort(obj)
  expect_true(length(v$warnings) > 0 || length(v$issues) > 0)
})

test_that("update.bayesqm_fit reuses stored data through a bare Y binding", {
  fit <- make_fake_fit(N = 4, J = 8, K = 2)
  # evaluate=FALSE returns the call; Y must be a bare symbol, not inline data.
  cl <- update(fit, K = 3, evaluate = FALSE)
  expect_equal(as.character(cl$Y), "Y")
  expect_true(is.null(dim(cl$Y)))
})
