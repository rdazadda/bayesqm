# The public fitting interface: validation, migration errors, a real tiny
# fit, the gate warning, and the extend() identity through the public API.

tiny_data <- function(N = 6, J = 9, seed = 3) {
  distr <- get_distribution(J)
  set.seed(seed)
  Y <- t(quota_sort_rows(matrix(rnorm(N * J), N, J), distr))
  colnames(Y) <- paste0("P", seq_len(N))
  qsort_data(Y, distribution = distr, validate = FALSE)
}

test_that("removed 0.1.0 arguments give migration errors", {
  d <- tiny_data()
  expect_error(fit_bayesian(d, K = 2, robust = TRUE), "0.1.0 score-scale")
  expect_error(fit_bayesian(d, K = 2, iter = 2000), "iterations")
  expect_error(fit_bayesian(d, K = 2, chains = 4), "gated chain")
  expect_error(fit_bayesian(d, K = 2, banana = 1), "unused argument")
})

test_that("quota violations are refused by name", {
  d <- tiny_data()
  d$Y[1, 2] <- d$Y[1, 2] %% length(d$distribution) + 1
  err <- tryCatch(fit_bayesian(d, K = 2), error = function(e) conditionMessage(e))
  expect_match(err, "forced sorts matching the design grid")
  expect_match(err, "P2")
})

test_that("K and phase constraints are validated", {
  d <- tiny_data()
  expect_error(fit_bayesian(d, K = 6), "smaller than the number")
  expect_error(fit_bayesian(d, K = 2, iterations = 401, burn = 100, thin = 5),
               "multiple of thin")
})

test_that("a tiny fit returns a complete, converged object", {
  d <- tiny_data()
  fit <- fit_bayesian(d, K = 2, iterations = 500, burn = 100, thin = 5,
                      max_iterations = 500, seed = 4, rhat_max = Inf,
                      ess_min = 0, quiet = TRUE)
  expect_s3_class(fit, "bayesqm_fit")
  expect_identical(dim(fit$draws$F), c(80L, 9L, 2L))
  expect_true(fit$gate$converged)
  expect_false(fit$gate$extended)
  F <- matrix(fit$draws$F[5, , ], ncol = 2)
  expect_lt(max(abs(colMeans(F))), 1e-10)          # conventions applied
  expect_lt(max(abs(colMeans(F^2) - 1)), 1e-10)
  expect_identical(dim(fit$draws_raw$F), dim(fit$draws$F))
})

test_that("an unreachable gate warns and reports honestly", {
  d <- tiny_data()
  expect_warning(
    fit <- fit_bayesian(d, K = 2, iterations = 300, burn = 100, thin = 5,
                        max_iterations = 600, seed = 4, ess_min = 1e6,
                        quiet = TRUE),
    "gate was not met")
  expect_false(fit$gate$converged)
  expect_true(fit$gate$extended)
  expect_identical(fit$gate$iterations, 600L)
})

test_that("extend() reproduces one long chain through the public API", {
  d <- tiny_data()
  straight <- fit_bayesian(d, K = 2, iterations = 700, burn = 100, thin = 5,
                           max_iterations = 700, seed = 5, rhat_max = Inf,
                           ess_min = 0, quiet = TRUE)
  base <- fit_bayesian(d, K = 2, iterations = 400, burn = 100, thin = 5,
                       max_iterations = 400, seed = 5, rhat_max = Inf,
                       ess_min = 0, quiet = TRUE)
  runif(500)                                   # unrelated session RNG use
  grown <- extend(base, iterations = 300, quiet = TRUE)
  expect_identical(grown$draws_raw$F, straight$draws_raw$F)
  expect_identical(grown$draws_raw$Lambda, straight$draws_raw$Lambda)
  expect_identical(grown$draws_raw$sigma, straight$draws_raw$sigma)
  expect_equal(grown$draws$F, straight$draws$F, tolerance = 1e-12)
  expect_identical(grown$gate$iterations, 700L)
})

test_that("extend() requires the raw draws", {
  d <- tiny_data()
  fit <- fit_bayesian(d, K = 2, iterations = 300, burn = 100, thin = 5,
                      max_iterations = 300, seed = 4, rhat_max = Inf,
                      ess_min = 0, keep_raw = FALSE, quiet = TRUE)
  expect_error(extend(fit, 100), "keep_raw")
})

test_that("update() re-evaluates the stored call with new arguments", {
  d <- tiny_data()
  fit <- fit_bayesian(d, K = 2, iterations = 300, burn = 100, thin = 5,
                      max_iterations = 300, seed = 4, rhat_max = Inf,
                      ess_min = 0, quiet = TRUE)
  refit <- update(fit, seed = 9)
  expect_identical(refit$brief$seed, 9)
  expect_false(identical(refit$draws$F, fit$draws$F))
})

test_that("printed grid labels recode monotonically and change nothing", {
  d <- tiny_data()
  C <- length(d$distribution)
  ref <- fit_bayesian(d, K = 2, iterations = 300, burn = 100, thin = 5,
                      max_iterations = 300, seed = 4, rhat_max = Inf,
                      ess_min = 0, quiet = TRUE)
  shifted <- d$Y - ceiling(C / 2)                # -4..+4 style labels
  expect_message(
    fit <- fit_bayesian(shifted, K = 2, iterations = 300, burn = 100,
                        thin = 5, max_iterations = 300, seed = 4,
                        rhat_max = Inf, ess_min = 0),
    "monotone relabeling")
  expect_identical(fit$draws$F, ref$draws$F)     # identical inference
})

test_that("missing entries and alien value sets get their own errors", {
  d <- tiny_data()
  Yna <- d$Y; Yna[2, 3] <- NA
  expect_error(fit_bayesian(Yna, K = 2), "missing entr")
  Yalien <- d$Y * 10                             # 10,20,...: C values, fine
  idx <- which(Yalien == 20)                     # plenty of these remain
  Yalien[idx[1]] <- 3.7                          # now C+1 distinct values
  qa <- qsort_data(Yalien, distribution = d$distribution, validate = FALSE)
  expect_error(fit_bayesian(qa, K = 2), "distinct values")
})

test_that("zero-count grid columns collapse as a monotone relabeling", {
  distr <- c(2, 0, 3, 4)                          # interior zero, KADE-style
  set.seed(8)
  Yn <- t(quota_sort_rows(matrix(rnorm(6 * 9), 6, 9), c(2, 3, 4)))
  Yn[Yn >= 2] <- Yn[Yn >= 2] + 1                  # gap-coded on 1,3,4
  expect_message(
    fit <- fit_bayesian(qsort_data(Yn, distribution = distr, validate = FALSE),
                        K = 2, iterations = 300, burn = 100, thin = 5,
                        max_iterations = 300, seed = 4, rhat_max = Inf,
                        ess_min = 0),
    "zero-count")
  expect_equal(fit$distribution, c(2, 3, 4))
})

test_that("matchalign realigns a public fit under a chosen pivot", {
  d <- tiny_data()
  fit <- fit_bayesian(d, K = 2, iterations = 300, burn = 100, thin = 5,
                      max_iterations = 300, seed = 4, rhat_max = Inf,
                      ess_min = 0, quiet = TRUE)
  re <- matchalign(fit, pivot = 10)
  expect_s3_class(re, "bayesqm_fit")
  expect_identical(re$align$pivot, 10)
  expect_identical(re$draws_raw$F, fit$draws_raw$F)   # raw untouched
  slim <- fit_bayesian(d, K = 2, iterations = 300, burn = 100, thin = 5,
                       max_iterations = 300, seed = 4, rhat_max = Inf,
                       ess_min = 0, keep_raw = FALSE, quiet = TRUE)
  expect_error(matchalign(slim, pivot = 2), "keep_raw")
})

test_that("extend carries factor names and warns after judgmental rotation", {
  d <- tiny_data()
  fit <- fit_bayesian(d, K = 2, iterations = 300, burn = 100, thin = 5,
                      max_iterations = 300, seed = 5, rhat_max = Inf,
                      ess_min = 0, quiet = TRUE)
  named <- rename_factors(fit, c("Care", "Cost"))
  ext <- extend(named, 100, quiet = TRUE)
  expect_identical(dimnames(ext$draws$sigma)[[2]], c("Care", "Cost"))
  rot <- rotate_factors(fit, .summarize_draws(fit$draws$F, mean)[, 2:1])
  expect_warning(extend(rot, 100, quiet = TRUE), "not carried over")
})

test_that("K and budget arguments are validated up front", {
  d <- tiny_data()
  expect_error(fit_bayesian(d, K = 2.5), "whole number")
  expect_error(fit_bayesian(d, K = 2, iterations = 100, burn = 100), "exceed")
  expect_error(fit_bayesian(d, K = 2, thin = 0), "at least 1")
})
