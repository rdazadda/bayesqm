test_that("demo_fit returns a bayesqm_fit with the requested dimensions", {
  fit <- demo_fit(N = 12, J = 15, K = 3, Td = 200, seed = 1L)

  expect_s3_class(fit, "bayesqm_fit")
  expect_equal(fit$brief$N, 12)
  expect_equal(fit$brief$J, 15)
  expect_equal(fit$brief$K, 3)
  expect_equal(dim(fit$loa),          c(12, 3))
  expect_equal(dim(fit$ci_lower),     c(12, 3))
  expect_equal(dim(fit$Lambda_draws), c(200, 12, 3))
  expect_equal(dim(fit$F_draws),      c(200, 15, 3))
})


test_that("demo_fit defaults produce a usable fit", {
  fit <- demo_fit()

  expect_s3_class(fit, "bayesqm_fit")
  expect_true(all(c("brief", "dataset", "loa", "loa_median", "ci_lower",
                    "ci_upper", "zsc", "zsc_n", "f_char", "flagged",
                    "qdc", "Lambda_draws", "F_draws", "align_info",
                    "hyperparams", "diagnostics", "ppc") %in%
                  names(fit)))
})


test_that("demo_fit is reproducible at the same seed", {
  a <- demo_fit(N = 6, J = 10, K = 2, seed = 42L)
  b <- demo_fit(N = 6, J = 10, K = 2, seed = 42L)
  expect_identical(a$loa, b$loa)
  expect_identical(a$Lambda_draws, b$Lambda_draws)
})


test_that("standard accessors and the base plot work on demo_fit", {
  fit <- demo_fit(N = 8, J = 10, K = 2)
  expect_equal(nobs(fit), 8)
  expect_true(is.matrix(coef(fit)))
  expect_equal(dim(fitted(fit)),    dim(fit$dataset))
  expect_equal(dim(residuals(fit)), dim(fit$dataset))
  expect_true(is.finite(sigma(fit)))

  pdf(file = tempfile(fileext = ".pdf"))
  on.exit(dev.off(), add = TRUE)
  expect_silent(plot(fit))
})


test_that("demo_run returns a bayesqm_run with the requested K range", {
  run <- demo_run(K_max = 5, k_peak = 3, k_sivula = 2, case = "gap")

  expect_s3_class(run, "bayesqm_run")
  expect_equal(nrow(run$tab), 5L)
  expect_equal(run$tab$K, 1:5)
  expect_equal(run$k_peak,   3L)
  expect_equal(run$k_sivula, 2L)
  expect_equal(run$case, "gap")
})


test_that("demo_run rejects invalid case labels", {
  expect_error(demo_run(case = "nonsense"))
})


test_that("demo_run case = 'agree' has matching peak and Sivula", {
  run <- demo_run(case = "agree", k_peak = 2, k_sivula = 2)
  expect_equal(run$k_peak, run$k_sivula)
  expect_equal(run$case, "agree")
})


