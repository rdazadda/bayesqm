# The plot suite: every view draws without error on a complete fit, par()
# is restored, and each returns its input invisibly.

expect_plots_cleanly <- function(code) {
  tmp <- tempfile(fileext = ".pdf")
  grDevices::pdf(tmp)
  op <- par(no.readonly = TRUE)
  out <- force(code)
  expect_identical(par("mfrow"), op$mfrow)
  grDevices::dev.off()
  unlink(tmp)
  invisible(out)
}

test_that("every fit view draws cleanly", {
  fit <- demo_fit()
  expect_plots_cleanly(expect_invisible(plot_loading_posterior(fit)))
  expect_plots_cleanly(expect_invisible(plot_flags(fit)))
  expect_plots_cleanly(expect_invisible(plot_factor_array(fit)))
  expect_plots_cleanly(expect_invisible(plot_factor_array(fit, factor = "f2")))
  expect_plots_cleanly(expect_invisible(plot_contrasts(fit)))
  expect_plots_cleanly(expect_invisible(plot_convergence(fit)))
  expect_plots_cleanly(expect_invisible(plot(fit)))
})

test_that("check and selection views draw cleanly", {
  fit <- demo_fit()
  ck <- check_fit(fit, draws = 15)
  expect_plots_cleanly(expect_invisible(plot_ppc(ck)))
  pc <- check_persons(fit, draws = 10, mixes = 20)
  expect_plots_cleanly(expect_invisible(plot_person_check(pc)))
})

test_that("plot inputs are validated", {
  fit <- demo_fit()
  expect_error(plot_factor_array(fit, factor = 9), "no such factor")
  expect_error(plot_contrasts(fit, pair = "f9-f1"), "no such pair")
  expect_error(plot_ppc(fit), "bayesqm_checks")
  expect_error(plot_person_check(fit), "bayesqm_persons")
})

test_that("deprecated plot names forward with a deprecation signal", {
  fit <- demo_fit()
  tmp <- tempfile(fileext = ".pdf")
  grDevices::pdf(tmp)
  expect_warning(plot_membership(fit), "plot_flags")
  expect_warning(plot_dist_cons(fit), "plot_contrasts")
  expect_error(plot_hyper(fit), "factor_characteristics")
  grDevices::dev.off()
  unlink(tmp)
})

test_that("autoplot serves the flagship four", {
  skip_if_not_installed("ggplot2")
  fit <- demo_fit()
  for (ty in c("loadings", "flags", "contrasts", "array")) {
    p <- ggplot2::autoplot(fit, type = ty)
    expect_s3_class(p, "ggplot")
  }
})

test_that("caption carries provenance and the gate verdict", {
  fit <- demo_fit()
  cap <- caption_bayesqm(fit)
  expect_match(cap, "Exact partition")
  expect_match(cap, "N = 8, J = 13, K = 2")
  expect_match(cap, "gate passed")
  expect_false(grepl("gate", caption_bayesqm(fit, include_gate = FALSE)))
})

test_that("plot_sorts previews every participant on any labeling", {
  distr <- c(1, 2, 3, 2, 1)
  set.seed(2)
  Y <- t(quota_sort_rows(matrix(rnorm(5 * 9), 5, 9), distr)) - 3   # -2..+2
  qd <- qsort_data(Y, distribution = distr, validate = FALSE)
  expect_plots_cleanly(expect_invisible(plot_sorts(qd)))
  expect_plots_cleanly(expect_invisible(plot(qd)))                 # dispatch
  expect_plots_cleanly(expect_invisible(plot_sorts(qd, participants = c(2, 4))))
  expect_plots_cleanly(expect_invisible(plot_sorts(qd, per_page = 2)))
  expect_error(plot_sorts(qd, participants = "nobody"), "unknown participant")
  # asymmetric grid
  distr2 <- c(1, 2, 4, 2)
  Y2 <- t(quota_sort_rows(matrix(rnorm(3 * 9), 3, 9), distr2))
  expect_plots_cleanly(
    expect_invisible(plot_sorts(qsort_data(Y2, distribution = distr2,
                                           validate = FALSE))))
})

test_that("autoplot previews sorts as faceted pyramids", {
  skip_if_not_installed("ggplot2")
  distr <- c(1, 2, 3, 2, 1)
  set.seed(2)
  Y <- t(quota_sort_rows(matrix(rnorm(4 * 9), 4, 9), distr))
  qd <- qsort_data(Y, distribution = distr, validate = FALSE)
  p <- ggplot2::autoplot(qd)
  expect_s3_class(p, "ggplot")
})

test_that("statement views draw cleanly and validate", {
  fit <- demo_fit()
  expect_plots_cleanly(expect_invisible(plot_zscores(fit)))
  expect_plots_cleanly(expect_invisible(plot_zscores(fit, order_by = "score")))
  expect_plots_cleanly(expect_invisible(plot_statement(fit, "S3")))
  expect_plots_cleanly(expect_invisible(plot_statement(fit, 5)))
  expect_error(plot_statement(fit, "S99"), "no such statement")
  tmp <- tempfile(fileext = ".pdf"); grDevices::pdf(tmp)
  expect_warning(plot_zscore_posterior(fit, 2), "plot_statement")
  grDevices::dev.off(); unlink(tmp)
  fit1 <- make_fake_fit(N = 5, J = 9, K = 1, T = 80)
  expect_plots_cleanly(expect_invisible(plot_zscores(fit1)))   # K = 1 path
})
