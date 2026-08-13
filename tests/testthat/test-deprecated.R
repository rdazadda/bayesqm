# Defunct 0.1.0 entry points must error with a pointer, never return
# different numbers under an old name.

test_that("defunct stubs error with their replacement named", {
  expect_error(run_bayes(), "fit_ladder")
  expect_error(select_k_peak(), "select_k")
  expect_error(select_k_sivula(), "loo_ladder")
  expect_error(compute_dominant_prob(), "compute_flags")
  expect_error(compute_dominant_sign(), "compute_flags")
  expect_error(compute_threshold_prob(), "compute_flags")
  expect_error(classify_membership(), "compute_flags")
  expect_error(compute_divergence(), "compute_qdc")
  expect_error(critical_delta(), "compute_qdc")
  expect_error(suggest_delta(), "delta_grid")
  expect_error(compute_posterior_scalars(), "as_draws_df")
  expect_error(demo_run(), "demo_fit")
})
