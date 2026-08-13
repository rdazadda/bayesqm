# posterior-package bridges registered in .onLoad.

test_that("as_draws_df round-trips the flat matrix", {
  fit <- make_fake_fit(T = 40)
  dd <- posterior::as_draws_df(fit)
  expect_identical(posterior::ndraws(dd), 40L)
  expect_true("Lambda[1,1]" %in% posterior::variables(dd))
})

test_that("as_draws_matrix and as_draws_rvars work", {
  fit <- make_fake_fit(T = 40)
  m <- posterior::as_draws_matrix(fit)
  expect_identical(dim(m), c(40L, ncol(as.matrix(fit))))
  rv <- posterior::as_draws_rvars(fit)
  expect_identical(dim(rv$Lambda), c(6L, 2L))
})

test_that("ndraws dispatches on the fit", {
  fit <- make_fake_fit(T = 40)
  expect_identical(posterior::ndraws(fit), 40L)
})
