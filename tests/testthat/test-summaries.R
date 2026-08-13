# The summary tables and the one publication rule. The coherence tests are
# the contract: claims() and the table functions must always agree.

test_that("compute_loadings returns the wide schema on the bounded scale", {
  fit <- make_fake_fit()
  lo <- compute_loadings(fit)
  expect_identical(names(lo)[1], "participant")
  expect_true(all(c("f1_loading", "f1_lower", "f1_upper", "f2_loading",
                    "spread") %in% names(lo)))
  vals <- unlist(lo[, grep("_loading|_lower|_upper", names(lo))])
  expect_true(all(abs(vals) <= 1))
  expect_true(all(lo$spread > 0))
})

test_that("flags carry probabilities, the unclassified state, and the FDR bound", {
  fit <- make_fake_fit()
  fl <- compute_flags(fit, q = 0.05)
  expect_identical(nrow(fl), 6L)
  expect_true(all(fl$flag_prob >= 0 & fl$flag_prob <= 1))
  expect_true(all(fl$unclassified_prob >= 0 & fl$unclassified_prob <= 1))
  phi <- attr(fl, "phi")
  expect_identical(dim(phi), c(6L, 5L))
  expect_equal(unname(rowSums(phi)), rep(1, 6), tolerance = 1e-12)
  expect_lte(attr(fl, "expected_false"), 0.05 * max(1, sum(fl$selected)))
})

test_that("fdr_select keeps the expected-FDR promise and the floor", {
  p <- c(.99, .97, .9, .6, .55, .3)
  r <- fdr_select(p, q = 0.05)
  expect_true(all(r$selected[1:2]))
  expect_lte(r$expected_false / max(1, sum(r$selected)), 0.05)
  rf <- fdr_select(p, q = 0.5, floor = 0.56)
  expect_false(rf$selected[5])               # under the floor, never selected
})

test_that("factor arrays are quota-exact and mirror on a symmetric grid", {
  fit <- make_fake_fit(N = 6, J = 9, K = 2)
  ar <- compute_factor_array(fit, negative = TRUE)
  distr <- fit$distribution
  for (k in c("f1_grid", "f2_grid")) {
    expect_identical(tabulate(ar[[k]], length(distr)), as.integer(distr))
  }
  if (all(distr == rev(distr))) {
    expect_identical(ar$f1_grid_neg, length(distr) + 1L - ar$f1_grid)
  }
  skip_if_not_installed("clue")
  expect_true(is.finite(attr(ar, "footrule_disagreement")))
})

test_that("qdc gives three-state verdicts with landmarks attached", {
  fit <- make_fake_fit()
  qdc <- compute_qdc(fit)
  expect_true(all(grepl("^distinguishing|^consensus$|^indeterminate$",
                        qdc$verdict)))
  expect_true(all(attr(qdc, "delta_kl") > 0))
  expect_equal(attr(qdc, "delta_grid"), delta_grid(fit$distribution))
  ct <- attr(qdc, "contrasts")
  expect_true(all(ct$lower <= ct$median & ct$median <= ct$upper))
  expect_identical(nrow(ct), fit$brief$J * 1L)      # K = 2, one pair
})

test_that("qdc refuses K = 1", {
  fit <- make_fake_fit(N = 5, J = 9, K = 1, T = 60)
  expect_error(compute_qdc(fit), "K >= 2")
})

test_that("claims() agrees with the table functions exactly", {
  fit <- make_fake_fit()
  q <- 0.10
  cl <- claims(fit, q = q)
  fl <- compute_flags(fit, q = q)
  expect_identical(cl$flags$participant, fl$participant[fl$selected])
  qdc <- compute_qdc(fit, q = q)
  dist_stmts <- qdc$statement[grepl("^distinguishing", qdc$verdict)]
  expect_identical(sort(unique(cl$distinguishing$statement)),
                   sort(dist_stmts))
  cons_stmts <- qdc$statement[qdc$verdict == "consensus"]
  expect_identical(cl$consensus$statement, cons_stmts)
  ct <- attr(qdc, "contrasts")
  expect_identical(nrow(cl$stars), sum(ct$selected))
})

test_that("claims print with all four families and the level", {
  fit <- make_fake_fit()
  out <- paste(capture.output(print(claims(fit, q = 0.05))), collapse = "\n")
  expect_match(out, "q = 0.05")
  expect_match(out, "flags")
  expect_match(out, "distinguishing")
  expect_match(out, "consensus")
  expect_match(out, "stars")
})

test_that("crib_sheet probabilities are proper and complete", {
  fit <- make_fake_fit(N = 6, J = 9, K = 2)
  cs <- crib_sheet(fit)
  expect_identical(nrow(cs), 9L * 2L)
  probs <- unlist(cs[, c("p_top", "p_bottom", "p_highest", "p_lowest")])
  expect_true(all(probs >= 0 & probs <= 1))
})

test_that("the summary layer runs end to end on a real tiny fit", {
  fit <- demo_fit()
  expect_s3_class(compute_loadings(fit), "data.frame")
  expect_s3_class(compute_flags(fit), "data.frame")
  expect_s3_class(compute_zscores(fit), "data.frame")
  expect_s3_class(compute_factor_array(fit), "data.frame")
  expect_s3_class(compute_qdc(fit), "data.frame")
  expect_s3_class(claims(fit), "bayesqm_claims")
})


test_that("factor_characteristics reports the per-factor block", {
  fit <- make_fake_fit()
  ch <- factor_characteristics(fit)
  K <- fit$brief$K; N <- fit$brief$N
  expect_equal(nrow(ch), K)
  expect_true(all(c("factor", "flagged", "defining_modal", "defining_mean",
                    "defining_lower", "defining_upper", "score_spread",
                    "reliability") %in% names(ch)))
  expect_true(all(ch$defining_mean >= 0 & ch$defining_mean <= N))
  expect_true(all(ch$defining_lower <= ch$defining_mean + 1e-9))
  expect_true(all(ch$defining_upper >= ch$defining_mean - 1e-9))
  expect_true(all(ch$flagged >= 0 & ch$flagged <= N))
  expect_true(all(ch$score_spread > 0))
  ok <- !is.na(ch$reliability)
  expect_true(all(ch$reliability[ok] > 0 & ch$reliability[ok] < 1))
  sc <- attr(ch, "score_correlations")
  expect_equal(dim(sc), c(K, K))
  expect_equal(unname(diag(sc)), rep(1, K), tolerance = 1e-8)
  expect_equal(sc, t(sc), tolerance = 1e-12)
})

test_that("contrasts carry the on-grid probability and two-level stars", {
  fit <- make_fake_fit()
  qdc <- compute_qdc(fit)
  co <- attr(qdc, "contrasts")
  expect_true(all(c("diff_column_prob", "stars") %in% names(co)))
  expect_true(all(co$diff_column_prob >= 0 & co$diff_column_prob <= 1))
  expect_true(all(co$stars %in% c("", "*", "**")))
  expect_identical(co$selected, co$stars != "")    # stars grade selected claims
  d1 <- attr(qdc, "delta_kl"); d99 <- attr(qdc, "delta_kl99")
  expect_identical(names(d1), names(d99))
  expect_true(all(d99 > d1))
})
