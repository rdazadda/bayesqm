test_that("compute_factor_array returns a tidy data frame with one row per statement", {
  set.seed(1L)
  J <- 10; N <- 6; K <- 2; T <- 120
  F_draws <- array(rnorm(T * J * K), c(T, J, K))
  dimnames(F_draws) <- list(NULL, paste0("S", seq_len(J)), paste0("f", seq_len(K)))
  distr <- get_distribution(J)
  Y     <- discretize_to_grid(matrix(rnorm(J * N), J, N), distr)

  tab <- compute_factor_array(F_draws, Y)
  expect_s3_class(tab, "data.frame")
  expect_equal(nrow(tab), J)
  expect_true(all(c("statement", "f1_grid", "f2_grid") %in% names(tab)))
})

test_that("grid columns match the forced distribution", {
  set.seed(7L)
  J <- 13; N <- 8; K <- 3; T <- 80
  F_draws <- array(rnorm(T * J * K), c(T, J, K))
  distr <- get_distribution(J)
  Y     <- discretize_to_grid(matrix(rnorm(J * N), J, N), distr)

  tab <- compute_factor_array(F_draws, Y)
  for (col in c("f1_grid", "f2_grid", "f3_grid")) {
    counts <- as.integer(table(tab[[col]]))
    expect_equal(sort(counts), sort(distr))
  }
})

test_that("compute_factor_array works with K = 1", {
  set.seed(2L)
  J <- 9; N <- 5; T <- 60
  F_draws <- array(rnorm(T * J * 1), c(T, J, 1))
  distr   <- get_distribution(J)
  Y       <- discretize_to_grid(matrix(rnorm(J * N), J, N), distr)

  tab <- compute_factor_array(F_draws, Y)
  expect_equal(nrow(tab), J)
  expect_true("f1_grid" %in% names(tab))
  expect_equal(sort(as.integer(table(tab$f1_grid))), sort(distr))
})
