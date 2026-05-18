test_that("new_bayesqm_fit populates qmethod-parallel slots", {
  fit <- make_fake_fit(N = 5, J = 12, K = 2)

  expect_s3_class(fit, "bayesqm_fit")
  for (slot in c("brief", "dataset", "loa", "loa_median",
                 "ci_lower", "ci_upper", "zsc", "zsc_n",
                 "f_char", "flagged", "qdc",
                 "Lambda_draws", "F_draws",
                 "align_info", "hyperparams",
                 "diagnostics", "ppc"))
    expect_true(slot %in% names(fit),
                info = paste0("missing slot: ", slot))

  # qmethod compatibility: the slot is $dataset, not $data.
  expect_false("data" %in% names(fit))
})

test_that("brief carries the canonical metadata", {
  fit <- make_fake_fit(N = 5, J = 12, K = 3)
  b   <- fit$brief
  expect_equal(b$K, 3)
  expect_equal(b$N, 5)
  expect_equal(b$J, 12)
  expect_equal(b$family, "Student-t")
  expect_equal(b$prob, 0.95)
  expect_true(is.list(b$priors))
  expect_true(is.character(b$info))
})

test_that("loa/ci_lower/ci_upper have N x K dim and matching dimnames", {
  fit <- make_fake_fit(N = 6, J = 10, K = 2)
  expect_equal(dim(fit$loa),      c(6, 2))
  expect_equal(dim(fit$ci_lower), c(6, 2))
  expect_equal(dim(fit$ci_upper), c(6, 2))
  expect_identical(dimnames(fit$loa), dimnames(fit$ci_lower))
  expect_identical(dimnames(fit$loa), dimnames(fit$ci_upper))
  expect_equal(colnames(fit$loa), c("f1", "f2"))
})

test_that("zsc and zsc_n are J x K", {
  fit <- make_fake_fit(N = 5, J = 10, K = 2)
  expect_equal(dim(fit$zsc),   c(10, 2))
  expect_equal(dim(fit$zsc_n), c(10, 2))
  expect_equal(rownames(fit$zsc), paste0("S", seq_len(10)))
})

test_that("zsc_n values match the forced distribution counts", {
  fit <- make_fake_fit(N = 5, J = 10, K = 2)
  distr <- fit$distribution
  for (k in seq_len(ncol(fit$zsc_n))) {
    tab <- as.integer(table(fit$zsc_n[, k]))
    expect_equal(sort(tab), sort(distr))
  }
})

test_that("f_char has characteristics and cor_zsc with correct shape", {
  fit <- make_fake_fit(N = 6, J = 12, K = 3)
  expect_true(all(c("nload", "eigenvals", "expl_var") %in%
                    names(fit$f_char$characteristics)))
  expect_equal(nrow(fit$f_char$characteristics), 3L)
  expect_equal(dim(fit$f_char$cor_zsc), c(3, 3))
  expect_equal(unname(diag(fit$f_char$cor_zsc)), c(1, 1, 1))
})

test_that("qdc reports the divergence summary schema", {
  fit <- make_fake_fit(N = 6, J = 10, K = 3)
  expect_true(all(c("statement", "D_median", "D_lower", "D_upper",
                     "pi_D", "pi_C", "kstar", "gsign", "p_gstar")
                   %in% names(fit$qdc)))
  expect_false("dist.and.cons" %in% names(fit$qdc))
  expect_equal(nrow(fit$qdc), 10)
  # delta is the computed reliability-adjusted critical difference,
  # so the probabilities are numeric (not NA) and well formed.
  expect_true(all(fit$qdc$pi_D >= 0 & fit$qdc$pi_D <= 1))
  expect_equal(fit$qdc$pi_C, 1 - fit$qdc$pi_D)
  expect_true(all(fit$qdc$kstar %in% seq_len(3)))
  expect_true(all(fit$qdc$gsign %in% c(-1, 0, 1)))
})

test_that("K = 1 fit preserves matrix dimensions across all slots", {
  fit <- make_fake_fit(N = 5, J = 8, K = 1, T = 120)
  expect_equal(dim(fit$loa),      c(5, 1))
  expect_equal(dim(fit$zsc),      c(8, 1))
  expect_equal(dim(fit$zsc_n),    c(8, 1))
  expect_equal(dim(fit$ci_lower), c(5, 1))
  expect_equal(dim(fit$ci_upper), c(5, 1))
})

test_that("hyperparams contains numeric draw vectors of equal length", {
  fit <- make_fake_fit(N = 5, J = 10, K = 2, T = 150)
  hp  <- fit$hyperparams
  expect_length(hp$nu, 150)
  expect_length(hp$sigma, 150)
  expect_length(hp$tau, 150)
})
