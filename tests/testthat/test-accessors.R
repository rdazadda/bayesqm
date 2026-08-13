# Standard R accessors on the new fit object.

test_that("coef returns bounded loadings with names", {
  fit <- make_fake_fit()
  co <- coef(fit)
  expect_identical(dim(co), c(6L, 2L))
  expect_identical(rownames(co), paste0("P", 1:6))
  expect_true(all(abs(co) <= 1))
})

test_that("fitted reconstructs on the utility scale, residuals refuse", {
  fit <- make_fake_fit()
  fv <- fitted(fit)
  expect_identical(dim(fv), dim(fit$dataset))
  expect_identical(dimnames(fv), dimnames(fit$dataset))
  expect_error(residuals(fit), "no residual scale")
})

test_that("nobs, sigma, family behave", {
  fit <- make_fake_fit()
  expect_identical(nobs(fit), 6L)
  s <- sigma(fit)
  expect_named(s, c("f1", "f2"))
  expect_true(all(s > 0))
  out <- paste(capture.output(print(family(fit))), collapse = "\n")
  expect_match(out, "exact partition")
})

test_that("the flat draw matrix follows the bracketed naming convention", {
  fit <- make_fake_fit(T = 50)
  m <- as.matrix(fit)
  expect_identical(nrow(m), 50L)
  expect_true(all(c("Lambda[1,1]", "F[10,2]", "sigma[2]", "s_i[6]") %in%
                    colnames(m)))
  expect_identical(ncol(m), 6L * 2L + 10L * 2L + 2L + 6L)
})

test_that("posterior_interval subsets and validates", {
  fit <- make_fake_fit()
  pi_all <- posterior_interval(fit)
  expect_identical(colnames(pi_all), c("2.5%", "97.5%"))
  pi_sig <- posterior_interval(fit, regex_pars = "^sigma")
  expect_identical(nrow(pi_sig), 2L)
  expect_error(posterior_interval(fit, pars = "nope"), "matched")
})

test_that("prior_summary prints the partition priors", {
  fit <- make_fake_fit()
  out <- paste(capture.output(print(prior_summary(fit))), collapse = "\n")
  expect_match(out, "sigma_k")
  expect_match(out, "half-Normal")
})
