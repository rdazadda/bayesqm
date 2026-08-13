# The bayesqm_fit object: structure, dimnames, print, summary.

test_that("the fit carries draws, gate, and alignment with dimnames", {
  fit <- make_fake_fit(N = 6, J = 10, K = 2)
  expect_s3_class(fit, "bayesqm_fit")
  expect_named(fit, c("brief", "dataset", "distribution", "draws",
                      "draws_raw", "state", "gate", "align"))
  expect_identical(dimnames(fit$draws$Lambda)[[2]], paste0("P", 1:6))
  expect_identical(dimnames(fit$draws$F)[[2]], paste0("S", 1:10))
  expect_identical(dimnames(fit$draws$sigma)[[2]], c("f1", "f2"))
  expect_identical(fit$brief$K, 2)
  expect_identical(fit$brief$N, 6L)
  expect_identical(dim(fit$dataset), c(10L, 6L))
})

test_that("print names the model, the gate, and the alignment", {
  fit <- make_fake_fit()
  out <- paste(capture.output(print(fit)), collapse = "\n")
  expect_match(out, "exact partition \\(rank-order\\) likelihood")
  expect_match(out, "gate: passed")
  expect_match(out, "max Rhat 1.004")
  expect_match(out, "alignment: pivot draw 1")
  expect_match(out, "compute_loadings")
})

test_that("a failed gate prints NOT MET and an extended fit says so", {
  fit <- make_fake_fit(converged = FALSE, extended = TRUE)
  out <- paste(capture.output(print(fit)), collapse = "\n")
  expect_match(out, "gate: NOT MET")
  expect_match(out, "extend\\(\\)")
  expect_match(out, "warm-extended")
})

test_that("summary previews bounded loadings inside [-1, 1]", {
  fit <- make_fake_fit()
  out <- paste(capture.output(summary(fit)), collapse = "\n")
  expect_match(out, "Bounded loadings")
  rho <- .rho_draws(fit)
  expect_true(all(abs(rho) <= 1))
})
