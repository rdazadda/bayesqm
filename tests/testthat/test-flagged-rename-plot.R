test_that("$flagged is a logical N x K matrix on every fit", {
  fit <- make_fake_fit(N = 8, J = 12, K = 3)
  expect_true(is.matrix(fit$flagged))
  expect_true(is.logical(fit$flagged))
  expect_equal(dim(fit$flagged), c(8, 3))
  expect_equal(dimnames(fit$flagged),
               list(paste0("P", 1:8), paste0("f", 1:3)))
})

test_that("$flagged marks at most one factor per participant", {
  fit <- make_fake_fit(N = 10, J = 12, K = 3, seed = 1L)
  row_counts <- rowSums(fit$flagged)
  expect_true(all(row_counts <= 1))
})

test_that("rename_factors rejects wrong-length and duplicate names", {
  fit <- make_fake_fit(N = 5, J = 10, K = 2)
  expect_error(rename_factors(fit, "only_one"),        "length K")
  expect_error(rename_factors(fit, c("a", "b", "c")),  "length K")
  expect_error(rename_factors(fit, c("dup", "dup")),   "unique")
})

test_that("rename_factors rewrites every factor-indexed slot", {
  fit <- make_fake_fit(N = 6, J = 10, K = 3)
  fit2 <- rename_factors(fit, c("alpha", "beta", "gamma"))

  nm <- c("alpha", "beta", "gamma")
  expect_equal(colnames(fit2$loa),        nm)
  expect_equal(colnames(fit2$loa_median), nm)
  expect_equal(colnames(fit2$ci_lower),   nm)
  expect_equal(colnames(fit2$ci_upper),   nm)
  expect_equal(colnames(fit2$zsc),        nm)
  expect_equal(colnames(fit2$zsc_n),      nm)
  expect_equal(colnames(fit2$flagged),    nm)
  expect_equal(rownames(fit2$f_char$characteristics), nm)
  expect_equal(dimnames(fit2$f_char$cor_zsc), list(nm, nm))
  expect_equal(dimnames(fit2$Lambda_draws)[[3]], nm)
  expect_equal(dimnames(fit2$F_draws)[[3]],      nm)
})

test_that("rename_factors rewrites qdc pair-column names", {
  fit <- make_fake_fit(N = 6, J = 10, K = 2)
  fit2 <- rename_factors(fit, c("low", "high"))

  # Original qdc has f1_f2_diff / f1_f2_prob; after rename -> low_high_*
  qcols <- names(fit2$qdc)
  expect_true(any(grepl("low_high_diff", qcols)))
  expect_true(any(grepl("low_high_prob", qcols)))
  expect_false(any(grepl("\\bf1\\b|\\bf2\\b", qcols)))
})

test_that("rename_factors is idempotent when the names already match", {
  fit  <- make_fake_fit(N = 4, J = 8, K = 2)
  nm   <- colnames(fit$loa)
  fit2 <- rename_factors(fit, nm)
  expect_identical(fit$loa, fit2$loa)
  expect_identical(fit$qdc, fit2$qdc)
})

test_that("plot.bayesqm_fit returns the fit invisibly and does not error", {
  fit <- make_fake_fit(N = 5, J = 10, K = 2)

  pdf(file = tempfile(fileext = ".pdf"))
  on.exit(dev.off(), add = TRUE)

  res <- plot(fit)
  expect_identical(res, fit)
})

test_that("plot.bayesqm_fit respects renamed factor labels", {
  fit  <- make_fake_fit(N = 5, J = 10, K = 2)
  fit2 <- rename_factors(fit, c("trad", "innov"))

  pdf(file = tempfile(fileext = ".pdf"))
  on.exit(dev.off(), add = TRUE)

  expect_silent(plot(fit2))
})
