test_that("save_bayesqm_plot writes a pdf and returns the path", {
  fit <- make_fake_fit(N = 4, J = 8, K = 2)
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)

  path <- save_bayesqm_plot(tmp, plot(fit))

  expect_identical(path, tmp)
  expect_true(file.exists(tmp))
  expect_gt(file.info(tmp)$size, 100L)
})

test_that("save_bayesqm_plot dispatches by extension", {
  fit <- make_fake_fit(N = 4, J = 8, K = 2)
  for (ext in c("pdf", "svg", "png", "tiff", "jpeg")) {
    tmp <- tempfile(fileext = paste0(".", ext))
    on.exit(unlink(tmp), add = TRUE)
    save_bayesqm_plot(tmp, plot(fit), width = 4, height = 3)
    expect_true(file.exists(tmp), info = ext)
  }
})

test_that("save_bayesqm_plot errors on missing or unknown extension", {
  fit <- make_fake_fit(N = 4, J = 8, K = 2)
  expect_error(save_bayesqm_plot(tempfile(), plot(fit)),
               "must have an extension")
  expect_error(save_bayesqm_plot(tempfile(fileext = ".xyz"), plot(fit)),
               "Unsupported extension")
})

test_that("save_bayesqm_plot prints a ggplot automatically", {
  skip_if_not_installed("ggplot2")

  fit <- make_fake_fit(N = 4, J = 8, K = 2)
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)

  save_bayesqm_plot(tmp, ggplot2::autoplot(fit, type = "membership"))
  expect_true(file.exists(tmp))
  expect_gt(file.info(tmp)$size, 100L)
})

test_that("save_bayesqm_plot closes the device even on error", {
  fit <- make_fake_fit(N = 4, J = 8, K = 2)
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)

  n_before <- length(dev.list())
  expect_error(save_bayesqm_plot(tmp, stop("nope")))
  expect_equal(length(dev.list()), n_before)
})


test_that("caption_bayesqm returns a length-1 string with core metadata", {
  fit <- make_fake_fit(N = 15, J = 20, K = 3)
  cap <- caption_bayesqm(fit)

  expect_type(cap, "character")
  expect_length(cap, 1L)
  expect_true(grepl("K = 3", cap))
  expect_true(grepl("N = 15", cap))
  expect_true(grepl("J = 20", cap))
  expect_true(grepl("Student-t|Gaussian", cap))
  expect_true(grepl("max Rhat", cap))
  expect_true(grepl("divergent", cap))
  expect_true(grepl("bayesqm R package", cap))
})

test_that("caption_bayesqm respects include_ref and include_diag toggles", {
  fit <- make_fake_fit(N = 6, J = 10, K = 2)

  cap <- caption_bayesqm(fit, include_ref = FALSE)
  expect_false(grepl("bayesqm R package", cap))

  cap <- caption_bayesqm(fit, include_diag = FALSE)
  expect_false(grepl("max Rhat", cap))
})

test_that("caption_bayesqm handles missing diagnostics gracefully", {
  fit <- make_fake_fit(N = 6, J = 10, K = 2)
  fit$diagnostics <- list(
    rhat_max = NA_real_, ess_bulk = NA_real_,
    ess_tail = NA_real_, divergences = NA_integer_)
  cap <- caption_bayesqm(fit)
  expect_true(grepl("max Rhat = NA", cap))
})


test_that("plot_hyper auto-switches to log x when range spans orders of magnitude", {
  fit <- make_fake_fit(N = 5, J = 10, K = 2)
  # Force tau onto (~0.01, ~5); range > 20 triggers the auto-log branch.
  fit$hyperparams$tau <- exp(runif(200, log(0.01), log(5)))

  pdf(file = tempfile(fileext = ".pdf"))
  on.exit(dev.off(), add = TRUE)

  expect_silent(plot_hyper(fit, pars = "tau"))
  expect_silent(plot_hyper(fit, pars = "tau", log = ""))
  expect_silent(plot_hyper(fit, pars = "sigma", log = "x"))
})
