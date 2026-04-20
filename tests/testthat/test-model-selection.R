test_that("select_k_peak picks the K with the largest ELPD", {
  expect_equal(select_k_peak(c(-10, -5, -7), K_candidates = 1:3), 2L)
  expect_equal(select_k_peak(c(NA, -5, -3), K_candidates = 1:3), 3L)
  expect_true(is.na(select_k_peak(c(NA, NA, NA), K_candidates = 1:3)))
})

test_that("select_k_sivula advances only when both thresholds are cleared", {
  expect_equal(
    select_k_sivula(elpds = c(-100, -98, -97), loo_list = list(NULL, NULL, NULL),
                    K_candidates = 1:3),
    1L
  )
  expect_equal(
    select_k_sivula(elpds = c(-100, -80, -50), loo_list = list(NULL, NULL, NULL),
                    K_candidates = 1:3),
    3L
  )
})
