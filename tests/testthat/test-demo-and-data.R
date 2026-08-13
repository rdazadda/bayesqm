# demo_fit: the substrate for examples; fast, complete, reproducible.

test_that("demo_fit returns a complete converged fit in seconds", {
  fit <- demo_fit()
  expect_s3_class(fit, "bayesqm_fit")
  expect_identical(fit$brief$N, 8L)
  expect_identical(fit$brief$J, 13L)
  expect_identical(dim(fit$draws$F)[1], 200L)
  expect_true(fit$gate$converged)
})

test_that("demo_fit is reproducible by seed", {
  a <- demo_fit(seed = 2)
  b <- demo_fit(seed = 2)
  expect_identical(a$draws$F, b$draws$F)
  expect_false(identical(a$draws$F, demo_fit(seed = 3)$draws$F))
})
