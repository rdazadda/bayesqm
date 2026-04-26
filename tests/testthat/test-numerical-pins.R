# Seed-pinned numerical regression tests. Each test fixes a seed, runs a
# deterministic demo_fit() / demo_run() (or a derived summary), and
# compares to a hard-coded value to a 1e-6 tolerance. These guard against
# silent numerical drift in the summary computations: any change to
# loading flattening, MatchAlign post-processing, quantile aggregation,
# or the demo data-generating process will break exactly one of these
# tests with a clear diff. Pin values were captured by running each
# expression once at the recorded seed; see the inline comments for the
# capture command.
#
# Bit-exact reproducibility is a property of the machine the pins were
# captured on. Different BLAS implementations (Apple Accelerate, OpenBLAS,
# MKL) round summation chains differently and can exceed the 1e-6
# tolerance. The tests therefore skip on CRAN and on every CI runner;
# they are meant to be re-run locally by the maintainer before each release.

pin_skip <- function() {
  testthat::skip_on_cran()
  testthat::skip_on_ci()
}


test_that("posterior_interval is numerically stable for a fixed-seed demo fit", {
  pin_skip()
  fit <- demo_fit(N = 10, J = 14, K = 2, Td = 200, seed = 42L)
  pi  <- posterior_interval(fit, prob = 0.95, pars = c("sigma", "tau"))

  # Captured: posterior_interval(demo_fit(N=10, J=14, K=2, Td=200, seed=42),
  #                              prob = 0.95, pars = c("sigma", "tau"))
  expect_equal(unname(pi["sigma", ]),
               c(0.339284288303802, 0.668171544127994),
               tolerance = 1e-6)
  expect_equal(unname(pi["tau", ]),
               c(0.347677780011759, 0.652181889837828),
               tolerance = 1e-6)
})


test_that("coef returns the same posterior-mean loadings for a fixed-seed demo fit", {
  pin_skip()
  fit <- demo_fit(N = 10, J = 14, K = 2, Td = 200, seed = 42L)
  co  <- coef(fit)

  # Captured: coef(demo_fit(N=10, J=14, K=2, Td=200, seed=42))[1, ]
  expect_equal(dim(co), c(10L, 2L))
  expect_equal(unname(co[1, ]),
               c(0.629857713087339, 0.13090892540762),
               tolerance = 1e-6)
})


test_that("compute_dominant_prob matches the pinned 2x2 corner", {
  pin_skip()
  fit <- demo_fit(N = 10, J = 14, K = 2, Td = 200, seed = 42L)
  dp  <- compute_dominant_prob(fit$Lambda_draws)

  # Captured: compute_dominant_prob(demo_fit(N=10, J=14, K=2, Td=200,
  #                                          seed=42))[1:2, 1:2]
  expect_equal(dim(dp), c(10L, 2L))
  expect_equal(unname(dp[1:2, 1:2]),
               matrix(c(1, 0, 0, 1), nrow = 2L, ncol = 2L),
               tolerance = 1e-6)
})


test_that("compute_loadings matches the pinned first-row entries", {
  pin_skip()
  fit   <- demo_fit(N = 10, J = 14, K = 2, Td = 200, seed = 42L)
  loads <- compute_loadings(fit$Lambda_draws, prob = 0.95)

  # Captured: c(loads$f1_loa[1], loads$f1_lower[1], loads$f1_upper[1])
  expect_equal(loads$f1_loa[1],   0.629857713087339, tolerance = 1e-6)
  expect_equal(loads$f1_lower[1], 0.475720024202007, tolerance = 1e-6)
  expect_equal(loads$f1_upper[1], 0.781126643039257, tolerance = 1e-6)
})


test_that("caption_bayesqm starts with the expected K, N, J header", {
  pin_skip()
  fit <- demo_fit(N = 10, J = 14, K = 2, Td = 200, seed = 42L)
  cap <- caption_bayesqm(fit)

  expect_type(cap, "character")
  expect_length(cap, 1L)
  expect_match(cap,
               "^Bayesian Q-methodology factor model \\(K = 2, N = 10, J = 14\\)",
               fixed = FALSE)
})


test_that("demo_run elpd peak is numerically stable at a fixed seed", {
  pin_skip()
  run <- demo_run(K_max = 4, k_peak = 3, k_sivula = 2,
                  case = "gap", seed = 1L)

  # Captured: demo_run(...)$tab$elpd[3] -- the peak ELPD entry.
  expect_equal(run$tab$elpd[3], -165.417814306205, tolerance = 1e-6)
})
