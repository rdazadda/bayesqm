test_that("coef returns the N x K posterior-mean loading matrix", {
  fit <- make_fake_fit(N = 6, J = 12, K = 2)
  co  <- coef(fit)
  expect_true(is.matrix(co))
  expect_equal(dim(co), c(6, 2))
  expect_identical(co, fit$loa)
})

test_that("fitted returns a J x N matrix on the Q-sort scale", {
  fit <- make_fake_fit(N = 5, J = 10, K = 2)
  ft  <- fitted(fit)
  expect_equal(dim(ft), c(10, 5))
  expect_equal(dimnames(ft), dimnames(fit$dataset))
  expect_true(all(is.finite(ft)))
})

test_that("residuals equal data - fitted", {
  fit <- make_fake_fit(N = 5, J = 10, K = 2)
  r   <- residuals(fit)
  expect_equal(dim(r), dim(fit$dataset))
  expect_equal(r, fit$dataset - fitted(fit))
})

test_that("nobs returns the number of participants", {
  fit <- make_fake_fit(N = 7, J = 12, K = 2)
  expect_equal(nobs(fit), 7)
})

test_that("sigma returns a scalar posterior mean", {
  fit <- make_fake_fit(N = 5, J = 10, K = 2)
  s   <- sigma(fit)
  expect_length(s, 1)
  expect_true(is.finite(s))
  expect_equal(s, mean(fit$hyperparams$sigma, na.rm = TRUE))
})

test_that("family returns a bayesqm_family with the expected fields", {
  fit <- make_fake_fit(N = 5, J = 10, K = 2)
  fam <- family(fit)
  expect_s3_class(fam, "bayesqm_family")
  expect_equal(fam$family, "Student-t")
  expect_equal(fam$link, "identity")
  expect_equal(fam$nu, "estimate")
})

test_that("as.matrix produces Stan-style parameter column names", {
  fit <- make_fake_fit(N = 4, J = 8, K = 2, T = 150)
  m   <- as.matrix(fit)
  expect_true(is.matrix(m))
  expect_equal(nrow(m), 150)
  # Expect Lambda[i,k], F[j,k], plus the scalar hyperparameters
  expect_true(all(c("Lambda[1,1]", "Lambda[4,2]", "F[1,1]", "F[8,2]") %in%
                    colnames(m)))
  expect_true(all(c("nu", "sigma", "tau") %in% colnames(m)))
})

test_that("as.array has posterior-compatible iteration/chain/variable dimnames", {
  fit <- make_fake_fit(N = 4, J = 6, K = 2, T = 100)
  a   <- as.array(fit)
  expect_equal(length(dim(a)), 3L)
  expect_equal(dim(a)[2], 1L)  # single synthetic chain
  nms <- names(dimnames(a))
  expect_equal(nms, c("iteration", "chain", "variable"))
  expect_equal(dimnames(a)$chain, "1")
})

test_that("as.data.frame converts the draws matrix", {
  fit <- make_fake_fit(N = 4, J = 6, K = 2, T = 80)
  df  <- as.data.frame(fit)
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 80)
})

test_that("posterior_interval returns the expected shape and column labels", {
  fit <- make_fake_fit(N = 4, J = 6, K = 2, T = 100)
  pi  <- posterior_interval(fit, prob = 0.9)
  expect_true(is.matrix(pi))
  expect_equal(ncol(pi), 2L)
  expect_equal(colnames(pi), c("5.0%", "95.0%"))
})

test_that("posterior_interval filters by pars and regex_pars", {
  fit <- make_fake_fit(N = 4, J = 6, K = 2, T = 80)
  pi  <- posterior_interval(fit, pars = c("nu", "sigma"))
  expect_equal(nrow(pi), 2L)
  expect_setequal(rownames(pi), c("nu", "sigma"))

  pi2 <- posterior_interval(fit, regex_pars = "^Lambda")
  expect_true(all(grepl("^Lambda\\[", rownames(pi2))))
  expect_equal(nrow(pi2), 4 * 2)  # N * K
})

test_that("prior_summary returns a bayesqm_prior data frame", {
  fit <- make_fake_fit(N = 4, J = 6, K = 2)
  ps  <- prior_summary(fit)
  expect_s3_class(ps, "bayesqm_prior")
  expect_s3_class(ps, "data.frame")
  expect_true(all(c("parameter", "prior") %in% names(ps)))
  expect_true(any(grepl("Normal\\(0, tau\\)", ps$prior)))
})

test_that("update(evaluate = FALSE) returns the modified call", {
  fit <- make_fake_fit(N = 4, J = 6, K = 2)
  cl  <- update(fit, K = 3, evaluate = FALSE)
  expect_true(is.call(cl))
  expect_equal(cl$K, 3)
  expect_equal(as.character(cl$Y), "Y")
})
