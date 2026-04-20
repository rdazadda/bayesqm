test_that("as_draws_df produces a posterior draws_df", {
  skip_if_not_installed("posterior")

  fit <- make_fake_fit(N = 4, J = 8, K = 2, T = 100)
  dr  <- posterior::as_draws_df(fit)
  expect_s3_class(dr, "draws_df")
  expect_equal(posterior::ndraws(dr), 100)
})

test_that("as_draws_matrix produces a posterior draws_matrix", {
  skip_if_not_installed("posterior")

  fit <- make_fake_fit(N = 4, J = 8, K = 2, T = 80)
  dm  <- posterior::as_draws_matrix(fit)
  expect_s3_class(dm, "draws_matrix")
  expect_equal(posterior::ndraws(dm), 80)
})

test_that("as_draws_array produces a posterior draws_array with one chain", {
  skip_if_not_installed("posterior")

  fit <- make_fake_fit(N = 4, J = 8, K = 2, T = 60)
  da  <- posterior::as_draws_array(fit)
  expect_s3_class(da, "draws_array")
  expect_equal(posterior::nchains(da), 1L)
  expect_equal(posterior::niterations(da), 60)
})

test_that("as_draws_rvars returns an rvars draws object", {
  skip_if_not_installed("posterior")

  fit <- make_fake_fit(N = 3, J = 6, K = 2, T = 50)
  dv  <- posterior::as_draws_rvars(fit)
  expect_s3_class(dv, "draws_rvars")
})

test_that("as_draws_list works", {
  skip_if_not_installed("posterior")

  fit <- make_fake_fit(N = 3, J = 6, K = 2, T = 50)
  dl  <- posterior::as_draws_list(fit)
  expect_s3_class(dl, "draws_list")
})

test_that("posterior::as_draws dispatches to bayesqm_fit", {
  skip_if_not_installed("posterior")

  fit <- make_fake_fit(N = 3, J = 6, K = 2, T = 50)
  d   <- posterior::as_draws(fit)
  expect_true(inherits(d, "draws"))
})

test_that("posterior::ndraws returns the draw count on the fit", {
  skip_if_not_installed("posterior")

  fit <- make_fake_fit(N = 3, J = 6, K = 2, T = 77)
  expect_equal(posterior::ndraws(fit), 77)
})
