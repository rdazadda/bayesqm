test_that("print.bayesqm_fit emits the Bayesian header and returns invisibly", {
  fit <- make_fake_fit(N = 5, J = 10, K = 2)
  out <- capture.output(res <- print(fit))
  expect_identical(res, fit)
  expect_true(any(grepl("Bayesian Q-methodology factor model", out)))
  expect_true(any(grepl("Factor loadings", out)))
  expect_true(any(grepl("Hyperparameters",  out)))
})

test_that("print.bayesqm_fit honors the stored prob in the CI label", {
  fit <- make_fake_fit(N = 4, J = 8, K = 2)
  fit$brief$prob <- 0.80
  out <- capture.output(print(fit))
  expect_true(any(grepl("80% CI", out)))
})

test_that("summary.bayesqm_fit includes factor characteristics", {
  fit <- make_fake_fit(N = 6, J = 12, K = 3)
  out <- capture.output(summary(fit))
  expect_true(any(grepl("Factor characteristics", out)))
  expect_true(any(grepl("eigenvals", out)))
  expect_true(any(grepl("MatchAlign diagnostics", out)))
})

test_that("print.qsort_data shows the distribution and source", {
  Y <- cbind(c(-2, -1, 0, 1, 2), c(-1, -2, 2, 0, 1), c(0, -2, -1, 2, 1))
  obj <- qsort_data(Y, distribution = c(1, 1, 1, 1, 1), source = "test")
  out <- capture.output(print(obj))
  expect_true(any(grepl("Q-sort data", out)))
  expect_true(any(grepl("source", out)))
  expect_true(any(grepl("distribution", out)))
})

test_that("summary.qsort_data reports validation warnings when needed", {
  Y <- matrix(0, nrow = 2, ncol = 2)  # too few statements / participants
  obj <- suppressWarnings(qsort_data(Y, distribution = c(1, 1),
                                     validate = FALSE))
  out <- capture.output(summary(obj))
  expect_true(any(grepl("issues", out)))
})

test_that("print.bayesqm_family shows family/link/nu", {
  fit <- make_fake_fit(N = 4, J = 8, K = 2)
  out <- capture.output(print(family(fit)))
  expect_true(any(grepl("Family", out)))
  expect_true(any(grepl("Link",   out)))
  expect_true(any(grepl("nu",     out)))
})

test_that("print.bayesqm_prior emits header and data frame rows", {
  fit <- make_fake_fit(N = 4, J = 8, K = 2)
  ps  <- prior_summary(fit)
  out <- capture.output(print(ps))
  expect_true(any(grepl("bayesqm priors", out)))
  expect_true(any(grepl("tau",   out)))
  expect_true(any(grepl("sigma", out)))
})
