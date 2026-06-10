test_that("generate_data returns the declared shape", {
  dat <- generate_data(N = 12, J = 20, K = 2, seed = 1L)
  expect_equal(dim(dat$Y),           c(20, 12))
  expect_equal(dim(dat$Lambda_true), c(12, 2))
  expect_equal(dim(dat$F_true),      c(20, 2))
  expect_equal(sum(dat$distribution), 20)
})

test_that("generate_data is reproducible for a given seed", {
  d1 <- generate_data(N = 8, J = 15, K = 2, seed = 7)
  d2 <- generate_data(N = 8, J = 15, K = 2, seed = 7)
  expect_identical(d1$Y, d2$Y)
  expect_identical(d1$Lambda_true, d2$Lambda_true)
})

test_that("generate_data without seed leaves RNG advanced (not reset)", {
  set.seed(42)
  x1 <- runif(1)

  set.seed(42)
  generate_data(N = 8, J = 15, K = 2)
  x2 <- runif(1)

  expect_false(identical(x1, x2))
})

test_that("get_distribution returns J-summing integer counts", {
  for (J in c(9L, 15L, 20L, 30L, 47L)) {
    d <- get_distribution(J)
    expect_equal(sum(d), J)
    expect_true(all(d >= 1))
  }
})

test_that("discretize_to_grid honours the forced distribution", {
  Y <- discretize_to_grid(matrix(rnorm(60), 20, 3), distr = get_distribution(20))
  for (j in seq_len(ncol(Y))) {
    tab <- as.integer(table(Y[, j]))
    expect_equal(sort(tab), sort(get_distribution(20)))
  }
})
