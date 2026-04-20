test_that("read_qsort_csv reads a generic wide CSV with statement rows", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)

  # 5 statements x 4 participants; first column is statement ID.
  writeLines(c(
    "id,P1,P2,P3,P4",
    "S1,-2,-1,0,1",
    "S2,-1,-2,1,0",
    "S3,0,0,-1,-2",
    "S4,1,1,-2,2",
    "S5,2,2,2,-1"
  ), tmp)

  d <- read_qsort_csv(tmp)
  expect_s3_class(d, "qsort_data")
  expect_equal(dim(d$Y), c(5, 4))
  expect_equal(rownames(d$Y), c("S1", "S2", "S3", "S4", "S5"))
})

test_that("read_qsort_csv auto-detects HTMLQ header signatures", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)

  writeLines(c(
    "uid,datetime,s1,s2,s3,s4,s5",
    "u001,2025-01-01,-2,-1,0,1,2",
    "u002,2025-01-02,-1,0,1,2,-2",
    "u003,2025-01-03,0,1,2,-2,-1"
  ), tmp)

  d <- read_qsort_csv(tmp)
  expect_s3_class(d, "qsort_data")
  expect_equal(ncol(d$Y), 3)  # 3 participants
  expect_equal(nrow(d$Y), 5)
  expect_true(grepl("^htmlq:", d$source))
})

test_that("read_qsort auto-dispatches from file extension", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)

  writeLines(c(
    "id,P1,P2,P3",
    "S1,-1,0,1",
    "S2,0,1,-1",
    "S3,1,-1,0"
  ), tmp)

  d <- read_qsort(tmp)
  expect_s3_class(d, "qsort_data")
})

test_that("read_qsort errors on unknown extension", {
  tmp <- tempfile(fileext = ".xyz")
  on.exit(unlink(tmp), add = TRUE)
  writeLines("anything", tmp)
  expect_error(read_qsort(tmp), "No reader for extension")
})

test_that("read_qsort errors when the file does not exist", {
  expect_error(read_qsort("does_not_exist_12345.csv"), "File not found")
})

test_that("read_statements reads a .txt statements file", {
  tmp <- tempfile(fileext = ".txt")
  on.exit(unlink(tmp), add = TRUE)
  writeLines(c("First statement.",
               "Second statement.",
               "Third statement."), tmp)
  s <- read_statements(tmp)
  expect_length(s, 3)
  expect_equal(unname(s[1]), "First statement.")
  expect_equal(names(s), c("S1", "S2", "S3"))
})

test_that("parse_distribution reads a distribution from a file", {
  tmp <- tempfile(fileext = ".txt")
  on.exit(unlink(tmp), add = TRUE)
  writeLines("1 2 3 2 1", tmp)
  expect_equal(parse_distribution(tmp), c(1L, 2L, 3L, 2L, 1L))
})

test_that("dotted import aliases forward to the snake_case readers", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  writeLines(c(
    "uid,datetime,s1,s2,s3",
    "u1,2025-01-01,-1,0,1",
    "u2,2025-01-02,0,1,-1",
    "u3,2025-01-03,1,-1,0"
  ), tmp)
  d <- import.htmlq(tmp)
  expect_s3_class(d, "qsort_data")
})
