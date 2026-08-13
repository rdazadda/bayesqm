# Edge cases that live at the data boundary.

test_that("qsort_data infers distribution from column 1 when NULL", {
  Y <- matrix(c(1, 1, 2, 2, 3,
                1, 2, 2, 3, 3), ncol = 2)
  expect_warning(qd <- qsort_data(Y), "participants")
  expect_identical(qd$distribution, c(2L, 2L, 1L))
})

test_that("validate_qsort reports distribution mismatches", {
  Y <- matrix(c(1, 1, 2, 2, 3,
                1, 2, 2, 3, 3), ncol = 2)
  v <- validate_qsort(Y, distribution = c(2, 2, 1))
  expect_match(v$warnings, "do not match the forced distribution")
})

test_that("K = 1 flows through fit, print, and accessors", {
  fit <- make_fake_fit(N = 5, J = 9, K = 1, T = 80)
  expect_identical(dim(coef(fit)), c(5L, 1L))
  out <- paste(capture.output(print(fit)), collapse = "\n")
  expect_match(out, "1 factor;")
  expect_identical(ncol(as.matrix(fit)), 5L + 9L + 1L + 5L)
})
