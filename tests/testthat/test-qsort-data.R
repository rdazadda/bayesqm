test_that("qsort_data constructs from a matrix", {
  set.seed(1L)
  grid <- c(-2, -1, 0, 1, 2)
  Y    <- cbind(grid, sample(grid), sample(grid), sample(grid))
  obj  <- qsort_data(Y, distribution = c(1, 1, 1, 1, 1))

  expect_s3_class(obj, "qsort_data")
  expect_equal(dim(obj$Y), c(5, 4))
  expect_length(obj$statements, 5)
  expect_length(obj$participants, 4)
  expect_equal(obj$distribution, c(1L, 1L, 1L, 1L, 1L))
})

test_that("infer_distribution recovers the grid counts from column 1", {
  y1 <- c(-2, -1, -1, 0, 0, 0, 1, 1, 2)
  Y  <- cbind(y1, sample(y1), sample(y1))
  expect_equal(infer_distribution(Y), c(1L, 2L, 3L, 2L, 1L))
})

test_that("parse_distribution handles numeric, string, and separators", {
  expect_equal(parse_distribution(c(1, 2, 3, 2, 1)), c(1L, 2L, 3L, 2L, 1L))
  expect_equal(parse_distribution("1 2 3 2 1"),       c(1L, 2L, 3L, 2L, 1L))
  expect_equal(parse_distribution("1,2,3,2,1"),       c(1L, 2L, 3L, 2L, 1L))
  expect_equal(parse_distribution("1;2;3;2;1"),       c(1L, 2L, 3L, 2L, 1L))
})

test_that("check_distribution flags non-conforming columns", {
  Y <- cbind(c(-1, -1, 0, 1, 1),
             c(-1,  0, 0, 0, 1))
  res <- check_distribution(Y, distribution = c(2, 1, 2))
  expect_false(res$ok)
  expect_equal(res$non_conforming, 2L)
})

test_that("validate_qsort reports too-small datasets", {
  Y <- matrix(0, nrow = 2, ncol = 2)
  v <- validate_qsort(Y, distribution = c(1, 1))
  expect_false(v$valid)
  expect_true(any(grepl("statements", v$issues)))
  expect_true(any(grepl("participants", v$issues)))
})
