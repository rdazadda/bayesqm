# vdiffr snapshot tests for every exported plot function. Each plot is
# rendered to SVG and diffed against a baseline in
# tests/testthat/_snaps/plots-snap/. Snapshots are tied to a small
# fixed-seed demo_fit() / demo_run() so they stay deterministic and tiny.
# If a plot's appearance shifts (e.g. a ggplot2 / base-R rendering tweak,
# a palette change, an off-by-one ordering bug) the test fails AND vdiffr
# ships a Shiny app for visual diff review (`vdiffr::manage_cases()`).


test_that("plot.bayesqm_fit matches snapshot", {
  skip_if_not_installed("vdiffr")
  fit <- demo_fit(N = 10, J = 14, K = 2, seed = 1L)
  vdiffr::expect_doppelganger("plot-bayesqm-fit",
                              function() plot(fit))
})


test_that("plot_loading_posterior matches snapshot", {
  skip_if_not_installed("vdiffr")
  fit <- demo_fit(N = 10, J = 14, K = 2, seed = 1L)
  vdiffr::expect_doppelganger("plot-loading-posterior",
                              function() plot_loading_posterior(fit))
})


test_that("plot_zscore_posterior matches snapshot", {
  skip_if_not_installed("vdiffr")
  fit <- demo_fit(N = 10, J = 14, K = 2, seed = 1L)
  vdiffr::expect_doppelganger("plot-zscore-posterior",
                              function() plot_zscore_posterior(fit, statement = 1))
})


test_that("plot_membership matches snapshot", {
  skip_if_not_installed("vdiffr")
  fit <- demo_fit(N = 10, J = 14, K = 2, seed = 1L)
  vdiffr::expect_doppelganger("plot-membership",
                              function() plot_membership(fit))
})


test_that("plot_elpd matches snapshot", {
  skip_if_not_installed("vdiffr")
  run <- demo_run(K_max = 4, k_peak = 3, k_sivula = 2,
                  case = "gap", seed = 1L)
  vdiffr::expect_doppelganger("plot-elpd",
                              function() plot_elpd(run))
})


test_that("plot_ppc matches snapshot", {
  skip_if_not_installed("vdiffr")
  fit <- demo_fit(N = 10, J = 14, K = 2, seed = 1L)
  vdiffr::expect_doppelganger("plot-ppc",
                              function() plot_ppc(fit))
})


test_that("plot_tucker matches snapshot", {
  skip_if_not_installed("vdiffr")
  fit <- demo_fit(N = 10, J = 14, K = 2, seed = 1L)
  vdiffr::expect_doppelganger("plot-tucker",
                              function() plot_tucker(fit))
})


test_that("plot_dist_cons matches snapshot", {
  skip_if_not_installed("vdiffr")
  fit <- demo_fit(N = 10, J = 14, K = 2, seed = 1L)
  vdiffr::expect_doppelganger("plot-dist-cons",
                              function() plot_dist_cons(fit))
})


test_that("plot_hyper matches snapshot", {
  skip_if_not_installed("vdiffr")
  fit <- demo_fit(N = 10, J = 14, K = 2, seed = 1L)
  vdiffr::expect_doppelganger("plot-hyper",
                              function() plot_hyper(fit))
})
