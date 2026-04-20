# autoplot() returns a ggplot object that is not drawn; so no device
# capture is needed. Tests are all gated on ggplot2 being installed
# (and ggdist for the half-eye / pointinterval types).

test_that("autoplot.bayesqm_run returns a ggplot object", {
  skip_if_not_installed("ggplot2")

  run <- structure(
    list(tab = data.frame(K = 1:3,
                          elpd = c(-10, -8, -9),
                          se   = c(1,   1,  1),
                          delta_elpd = c(NA, -2, 1),
                          se_delta   = c(NA, 0.5, 0.5),
                          ratio      = c(NA, 4, 2)),
         k_peak = 2L, k_sivula = 2L, case = "agree",
         loo_list = list()),
    class = "bayesqm_run")

  p <- ggplot2::autoplot(run)
  expect_s3_class(p, "ggplot")
})


test_that("autoplot.bayesqm_fit dispatches on type", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("ggdist")

  fit <- make_fake_fit(N = 5, J = 10, K = 2)

  expect_s3_class(ggplot2::autoplot(fit, type = "loadings"),   "ggplot")
  expect_s3_class(ggplot2::autoplot(fit, type = "zscores"),    "ggplot")
  expect_s3_class(ggplot2::autoplot(fit, type = "membership"), "ggplot")
  expect_s3_class(ggplot2::autoplot(fit, type = "hyper"),      "ggplot")
  expect_s3_class(ggplot2::autoplot(fit, type = "zscore_posterior",
                                    statement = 1), "ggplot")
})


test_that("autoplot errors on missing statement for zscore_posterior", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("ggdist")

  fit <- make_fake_fit(N = 5, J = 10, K = 2)
  expect_error(ggplot2::autoplot(fit, type = "zscore_posterior"),
               "required")
})


test_that("autoplot membership works with renamed factors", {
  skip_if_not_installed("ggplot2")

  fit <- make_fake_fit(N = 6, J = 10, K = 2)
  fit <- rename_factors(fit, c("tradition", "innovation"))
  p <- ggplot2::autoplot(fit, type = "membership")
  expect_s3_class(p, "ggplot")
})
