# save_bayesqm_plot: device handling, extension dispatch, error paths.

test_that("save_bayesqm_plot writes a pdf and returns the path", {
  tmp <- tempfile(fileext = ".pdf")
  out <- save_bayesqm_plot(tmp, plot(1:10))
  expect_identical(out, tmp)
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("save_bayesqm_plot dispatches by extension", {
  for (ext in c(".pdf", ".png")) {
    tmp <- tempfile(fileext = ext)
    save_bayesqm_plot(tmp, plot(1:10), width = 4, height = 3)
    expect_true(file.exists(tmp))
    unlink(tmp)
  }
})

test_that("save_bayesqm_plot errors on missing or unknown extension", {
  expect_error(save_bayesqm_plot(tempfile(), plot(1:10)))
  expect_error(save_bayesqm_plot(tempfile(fileext = ".xyz"), plot(1:10)))
})

test_that("save_bayesqm_plot prints a ggplot automatically", {
  skip_if_not_installed("ggplot2")
  tmp <- tempfile(fileext = ".pdf")
  p <- ggplot2::ggplot(data.frame(x = 1:3, y = 1:3),
                       ggplot2::aes(x, y)) + ggplot2::geom_point()
  save_bayesqm_plot(tmp, p)
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("save_bayesqm_plot closes the device even on error", {
  ndev <- length(grDevices::dev.list())
  tmp <- tempfile(fileext = ".pdf")
  try(save_bayesqm_plot(tmp, stop("boom")), silent = TRUE)
  expect_identical(length(grDevices::dev.list()), ndev)
  unlink(tmp)
})
