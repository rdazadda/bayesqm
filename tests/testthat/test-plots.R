# Every plot function must (a) run end-to-end on a synthetic fit,
# (b) return its input invisibly, and (c) not error on the K = 1 edge
# case or when factor labels have been renamed. All drawing is routed
# to a temporary PDF device so the tests produce no visible output.

with_pdf_device <- function(expr) {
  f <- tempfile(fileext = ".pdf")
  grDevices::pdf(file = f)
  on.exit({ grDevices::dev.off(); unlink(f) }, add = TRUE)
  force(expr)
}


test_that("plot_elpd runs on a fake bayesqm_run", {
  fake_tab <- data.frame(
    K = 1:4,
    elpd = c(-200, -180, -175, -178),
    se   = c(8, 6, 5, 5),
    delta_elpd = c(NA, -20, -5, 3),
    se_delta   = c(NA, 4, 3, 3),
    ratio      = c(NA, 5, 1.7, 1)
  )
  run <- structure(
    list(call = NULL, fits = list(), tab = fake_tab,
         loo_list = vector("list", 4),
         k_peak = 3L, k_sivula = 2L, case = "gap"),
    class = "bayesqm_run")

  with_pdf_device({
    res <- plot_elpd(run)
    expect_identical(res, run)
  })
})


test_that("plot_elpd with all-NA ELPD errors cleanly", {
  fake_tab <- data.frame(
    K = 1:3, elpd = NA_real_, se = NA_real_,
    delta_elpd = NA_real_, se_delta = NA_real_, ratio = NA_real_)
  run <- structure(
    list(tab = fake_tab, loo_list = list(),
         k_peak = NA_integer_, k_sivula = NA_integer_, case = NA_character_),
    class = "bayesqm_run")
  with_pdf_device({
    expect_error(plot_elpd(run), "No finite ELPD")
  })
})


test_that("plot_membership produces tiles on a multi-factor fit", {
  fit <- make_fake_fit(N = 8, J = 10, K = 3)
  with_pdf_device({
    res <- plot_membership(fit)
    expect_identical(res, fit)
  })
})


test_that("plot_membership handles sort = FALSE", {
  fit <- make_fake_fit(N = 6, J = 10, K = 2)
  with_pdf_device({
    expect_silent(plot_membership(fit, sort = FALSE))
  })
})


test_that("plot_ppc renders the histogram of PPC RMSE", {
  fit <- make_fake_fit(N = 6, J = 10, K = 2)
  with_pdf_device({
    res <- plot_ppc(fit)
    expect_identical(res, fit)
  })
})


test_that("plot_ppc errors when the fit has no PPC stored", {
  fit <- make_fake_fit(N = 6, J = 10, K = 2)
  fit$ppc <- list()
  with_pdf_device({
    expect_error(plot_ppc(fit), "No posterior predictive")
  })
})


test_that("plot_loading_posterior renders one panel per factor", {
  fit <- make_fake_fit(N = 8, J = 12, K = 3)
  with_pdf_device({
    res <- plot_loading_posterior(fit)
    expect_identical(res, fit)
  })
})


test_that("plot_loading_posterior supports factor subsetting by name and index", {
  fit <- make_fake_fit(N = 6, J = 10, K = 3)
  with_pdf_device({
    expect_silent(plot_loading_posterior(fit, factors = 1))
    expect_silent(plot_loading_posterior(fit, factors = c("f1", "f3")))
    expect_error(plot_loading_posterior(fit, factors = "does_not_exist"),
                 "Unknown factor")
  })
})


test_that("plot_loading_posterior respects rename_factors", {
  fit  <- make_fake_fit(N = 6, J = 10, K = 2)
  fit2 <- rename_factors(fit, c("tradition", "innovation"))
  with_pdf_device({
    expect_silent(plot_loading_posterior(fit2))
  })
})


test_that("plot_zscore_posterior runs for one statement (index or name)", {
  fit <- make_fake_fit(N = 5, J = 10, K = 3)
  with_pdf_device({
    expect_silent(plot_zscore_posterior(fit, 1))
    expect_silent(plot_zscore_posterior(fit, "S5"))
    expect_error(plot_zscore_posterior(fit, "nope"), "not found")
  })
})


test_that("plot_tucker renders when congruence is present", {
  fit <- make_fake_fit(N = 6, J = 10, K = 2)
  with_pdf_device({
    res <- plot_tucker(fit)
    expect_identical(res, fit)
  })
})


test_that("plot_tucker errors when align_info is missing", {
  fit <- make_fake_fit(N = 6, J = 10, K = 2)
  fit$align_info$congruence <- NULL
  with_pdf_device({
    expect_error(plot_tucker(fit), "No MatchAlign congruence")
  })
})


test_that("plot_dist_cons renders a heatmap and errors for K < 2", {
  fit  <- make_fake_fit(N = 6, J = 8, K = 3)
  fit1 <- make_fake_fit(N = 6, J = 8, K = 1)
  with_pdf_device({
    res <- plot_dist_cons(fit, delta = 1.0)
    expect_identical(res, fit)
    expect_error(plot_dist_cons(fit1), "K >= 2")
  })
})


test_that("plot_hyper renders a panel per available parameter", {
  fit <- make_fake_fit(N = 5, J = 10, K = 2)
  with_pdf_device({
    res <- plot_hyper(fit)
    expect_identical(res, fit)
  })
})


test_that("plot_hyper gracefully handles partially-NA hyperparams", {
  fit <- make_fake_fit(N = 5, J = 10, K = 2)
  fit$hyperparams$nu <- rep(NA_real_, length(fit$hyperparams$nu))
  with_pdf_device({
    # sigma and tau remain; nu should be silently skipped
    expect_silent(plot_hyper(fit))
  })
})


test_that("plot_hyper errors when every parameter is empty", {
  fit <- make_fake_fit(N = 5, J = 10, K = 2)
  for (p in c("nu", "sigma", "tau"))
    fit$hyperparams[[p]] <- rep(NA_real_, length(fit$hyperparams[[p]]))
  with_pdf_device({
    expect_error(plot_hyper(fit), "No non-empty hyperparameter")
  })
})


test_that("plot.bayesqm_fit sort_by accepts a factor index", {
  fit <- make_fake_fit(N = 5, J = 10, K = 3)
  with_pdf_device({
    expect_silent(plot(fit, sort_by = 2))
    expect_error(plot(fit, sort_by = 0), "1:K")
    expect_error(plot(fit, sort_by = 99), "1:K")
  })
})


test_that("plot functions do not collide with user-supplied ... args", {
  # These args all conflict with hardcoded ones -- must NOT error.
  fit <- make_fake_fit(N = 4, J = 8, K = 2)

  fake_run <- structure(
    list(tab = data.frame(K = 1:3, elpd = c(-10, -8, -9), se = c(1, 1, 1),
                          delta_elpd = c(NA, -2, 1), se_delta = c(NA, 0.5, 0.5),
                          ratio = c(NA, 4, 2)),
         k_peak = 2L, k_sivula = 2L, case = "agree",
         loo_list = list()),
    class = "bayesqm_run")

  with_pdf_device({
    expect_silent(plot(fit, main = "Custom", xlab = "Custom"))
    expect_silent(plot_elpd(fake_run, main = "Custom", xlab = "Custom"))
    expect_silent(plot_ppc(fit, main = "Custom", col = "red"))
    expect_silent(plot_membership(fit, main = "Custom"))
    expect_silent(plot_loading_posterior(fit, main = "Custom"))
    expect_silent(plot_zscore_posterior(fit, 1, main = "Custom"))
    expect_silent(plot_tucker(fit, main = "Custom", col = "red"))
    expect_silent(plot_dist_cons(fit, main = "Custom"))
    expect_silent(plot_hyper(fit, main = "Custom"))
  })
})


test_that("plot_ppc errors when PPC draws are non-finite or too few", {
  fit <- make_fake_fit(N = 4, J = 8, K = 2)
  fit$ppc$rmse.r <- rep(Inf, 10L)
  with_pdf_device({
    expect_error(plot_ppc(fit), "Not enough finite")
  })
  fit$ppc$rmse.r <- c(0.3, NA, NA)
  with_pdf_device({
    expect_error(plot_ppc(fit), "Not enough finite")
  })
})


test_that("plot_tucker rejects non-matrix congruence", {
  fit <- make_fake_fit(N = 4, J = 8, K = 2, T = 40)
  fit$align_info$congruence <- array(0.9, dim = c(40, 2, 2))
  with_pdf_device({
    expect_error(plot_tucker(fit), "must be a matrix")
  })
})


test_that("plot_loading_posterior rejects empty factor selection", {
  fit <- make_fake_fit(N = 4, J = 8, K = 2)
  with_pdf_device({
    expect_error(plot_loading_posterior(fit, factors = integer(0)),
                 "No factors selected")
  })
})


test_that("plot_dist_cons cleans up layout() on exit", {
  fit <- make_fake_fit(N = 5, J = 10, K = 3)
  with_pdf_device({
    plot_dist_cons(fit)
    # After the function returns, a fresh plot() should succeed --
    # meaning the layout was reset.
    expect_silent(plot(1:3))
  })
})
