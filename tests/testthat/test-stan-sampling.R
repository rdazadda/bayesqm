# End-to-end Stan sampling tests. Each is gated by skip_on_cran() plus
# skip_if_no_stan(), so CRAN submission checks and Stan-less CI runs are
# not affected. Local development with a Stan backend should exercise the
# full pipeline here.


test_that("fit_bayesian runs end-to-end and produces a well-formed fit", {
  skip_on_cran()
  skip_if_no_stan()

  dat <- make_stan_test_data(N = 12, J = 12, K = 2)
  fit <- fit_bayesian(dat$Y, K = 2,
                      chains = stan_fast$chains,
                      iter   = stan_fast$iter,
                      warmup = stan_fast$warmup,
                      max_draws   = stan_fast$max_draws,
                      adapt_delta = stan_fast$adapt_delta,
                      seed = 1L)

  expect_s3_class(fit, "bayesqm_fit")
  expect_equal(fit$brief$K, 2)
  expect_equal(fit$brief$N, 12)
  expect_equal(fit$brief$J, 12)
  expect_equal(dim(fit$loa), c(12, 2))
  expect_equal(dim(fit$zsc), c(12, 2))
  expect_true(all(is.finite(fit$loa)))
  expect_true(all(is.finite(fit$zsc)))
})


test_that("Stan sampling reaches reasonable convergence on a small model", {
  skip_on_cran()
  skip_if_no_stan()

  dat <- make_stan_test_data(N = 12, J = 12, K = 2)
  fit <- fit_bayesian(dat$Y, K = 2,
                      chains = stan_fast$chains,
                      iter   = stan_fast$iter,
                      warmup = stan_fast$warmup,
                      max_draws   = stan_fast$max_draws,
                      adapt_delta = stan_fast$adapt_delta,
                      seed = 1L)

  # Convergence on the identified scalar parameters only (Lambda and F have
  # rotational ambiguity and aren't included in the diagnostic summary).
  expect_true(is.finite(fit$diagnostics$rhat_max))
  expect_lt(fit$diagnostics$rhat_max, 1.15)
  expect_true(fit$diagnostics$ess_bulk >= 50)
  expect_true(fit$diagnostics$divergences <= 5)
})


test_that("downstream accessors work on a real fit", {
  skip_on_cran()
  skip_if_no_stan()

  dat <- make_stan_test_data(N = 10, J = 10, K = 2)
  fit <- fit_bayesian(dat$Y, K = 2,
                      chains = stan_fast$chains,
                      iter   = stan_fast$iter,
                      warmup = stan_fast$warmup,
                      max_draws   = stan_fast$max_draws,
                      adapt_delta = stan_fast$adapt_delta,
                      seed = 2L)

  expect_equal(dim(coef(fit)),      c(10, 2))
  expect_equal(dim(fitted(fit)),    dim(fit$dataset))
  expect_equal(dim(residuals(fit)), dim(fit$dataset))
  expect_equal(nobs(fit), 10)
  expect_true(is.finite(sigma(fit)))

  m <- as.matrix(fit)
  expect_true("Lambda[1,1]" %in% colnames(m))
  expect_true("F[1,1]"      %in% colnames(m))
  expect_true("sigma"       %in% colnames(m))

  pi <- posterior_interval(fit, prob = 0.9, regex_pars = "^Lambda")
  expect_equal(nrow(pi), 10 * 2)

  ps <- prior_summary(fit)
  expect_s3_class(ps, "bayesqm_prior")

  # Print / summary must not error.
  expect_output(print(fit),   "Bayesian Q-methodology")
  expect_output(summary(fit), "Factor characteristics")
})


test_that("matchalign produces Tucker phi close to 1 on real draws", {
  skip_on_cran()
  skip_if_no_stan()

  dat <- make_stan_test_data(N = 12, J = 12, K = 2)
  fit <- fit_bayesian(dat$Y, K = 2,
                      chains = stan_fast$chains,
                      iter   = stan_fast$iter,
                      warmup = stan_fast$warmup,
                      max_draws   = stan_fast$max_draws,
                      adapt_delta = stan_fast$adapt_delta,
                      seed = 3L)

  mean_phi <- colMeans(fit$align_info$congruence, na.rm = TRUE)
  # After MatchAlign the within-factor congruence should be near 1.
  expect_true(all(mean_phi > 0.8))
})


test_that("K = 1 path runs end-to-end and preserves matrix dimensions", {
  skip_on_cran()
  skip_if_no_stan()

  dat <- make_stan_test_data(N = 10, J = 10, K = 1)
  fit <- fit_bayesian(dat$Y, K = 1,
                      chains = stan_fast$chains,
                      iter   = stan_fast$iter,
                      warmup = stan_fast$warmup,
                      max_draws   = stan_fast$max_draws,
                      adapt_delta = stan_fast$adapt_delta,
                      seed = 4L)

  expect_equal(dim(fit$loa),      c(10, 1))
  expect_equal(dim(fit$zsc),      c(10, 1))
  expect_equal(dim(fit$ci_lower), c(10, 1))
  expect_equal(dim(fit$zsc_n),    c(10, 1))
  expect_equal(dim(compute_dominant_prob(fit$Lambda_draws)), c(10, 1))
})


test_that("robust = FALSE switches to the Normal likelihood", {
  skip_on_cran()
  skip_if_no_stan()

  dat <- make_stan_test_data(N = 10, J = 10, K = 2)
  fit <- fit_bayesian(dat$Y, K = 2, robust = FALSE,
                      chains = stan_fast$chains,
                      iter   = stan_fast$iter,
                      warmup = stan_fast$warmup,
                      max_draws   = stan_fast$max_draws,
                      adapt_delta = stan_fast$adapt_delta,
                      seed = 5L)

  expect_equal(fit$brief$family, "Gaussian")
  expect_equal(family(fit)$family, "Gaussian")
})


test_that("fixed nu (numeric) is respected", {
  skip_on_cran()
  skip_if_no_stan()

  dat <- make_stan_test_data(N = 10, J = 10, K = 2)
  fit <- fit_bayesian(dat$Y, K = 2, nu = 5,
                      chains = stan_fast$chains,
                      iter   = stan_fast$iter,
                      warmup = stan_fast$warmup,
                      max_draws   = stan_fast$max_draws,
                      adapt_delta = stan_fast$adapt_delta,
                      seed = 6L)

  expect_equal(fit$brief$nu, 5)
})


test_that("run_bayes produces an ELPD table with a peak / Sivula verdict", {
  skip_on_cran()
  skip_if_no_stan()
  skip_if_not_installed("loo")

  dat <- make_stan_test_data(N = 12, J = 12, K = 2)
  run <- run_bayes(dat$Y, K_max = 2,
                   chains = stan_fast$chains,
                   iter   = stan_fast$iter,
                   warmup = stan_fast$warmup,
                   max_draws   = stan_fast$max_draws,
                   adapt_delta = stan_fast$adapt_delta,
                   seed = 7L)

  expect_s3_class(run, "bayesqm_run")
  expect_equal(nrow(run$tab), 2L)
  expect_true(!is.na(run$k_peak))
  expect_true(!is.na(run$k_sivula))
  expect_true(run$case %in% c("agree", "gap", "reversed"))
})


test_that("update() re-fits with modified K and reuses stored data", {
  skip_on_cran()
  skip_if_no_stan()

  dat <- make_stan_test_data(N = 10, J = 10, K = 2)
  fit <- fit_bayesian(dat$Y, K = 2,
                      chains = stan_fast$chains,
                      iter   = stan_fast$iter,
                      warmup = stan_fast$warmup,
                      max_draws   = stan_fast$max_draws,
                      adapt_delta = stan_fast$adapt_delta,
                      seed = 8L)

  fit2 <- update(fit, K = 1, seed = 9L)
  expect_s3_class(fit2, "bayesqm_fit")
  expect_equal(fit2$brief$K, 1)
  expect_equal(dim(fit2$loa), c(10, 1))
})


test_that("posterior package dispatch works on a real fit", {
  skip_on_cran()
  skip_if_no_stan()
  skip_if_not_installed("posterior")

  dat <- make_stan_test_data(N = 10, J = 10, K = 2)
  fit <- fit_bayesian(dat$Y, K = 2,
                      chains = stan_fast$chains,
                      iter   = stan_fast$iter,
                      warmup = stan_fast$warmup,
                      max_draws   = stan_fast$max_draws,
                      adapt_delta = stan_fast$adapt_delta,
                      seed = 10L)

  dr <- posterior::as_draws_df(fit)
  expect_s3_class(dr, "draws_df")
  expect_gt(posterior::ndraws(dr), 0L)

  da <- posterior::as_draws_array(fit)
  expect_s3_class(da, "draws_array")
})


test_that("loo dispatch works on a real fit", {
  skip_on_cran()
  skip_if_no_stan()
  skip_if_not_installed("loo")

  dat <- make_stan_test_data(N = 12, J = 12, K = 2)
  fit <- fit_bayesian(dat$Y, K = 2,
                      chains = stan_fast$chains,
                      iter   = stan_fast$iter,
                      warmup = stan_fast$warmup,
                      max_draws   = stan_fast$max_draws,
                      adapt_delta = stan_fast$adapt_delta,
                      seed = 11L)

  expect_s3_class(loo::loo(fit), "loo")
})
