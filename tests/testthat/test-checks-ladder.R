# Model checks, the person check, the GHK bridge, and the two-signal
# ladder. Real-sampler pieces run at toy scale; the GHK total-probability
# and full-ladder runs sit behind skip_on_cran.

test_that("check_fit returns proper probabilities and prints plainly", {
  fit <- demo_fit()
  ck <- check_fit(fit, draws = 20)
  expect_true(ck$agreement$p >= 0 && ck$agreement$p <= 1)
  expect_true(ck$extra_factor$percentile >= 0 && ck$extra_factor$percentile <= 1)
  expect_true(ck$paired$p >= 0 && ck$paired$p <= 1)
  expect_identical(length(ck$paired$p_j), 13L)
  out <- paste(capture.output(print(ck)), collapse = "\n")
  expect_match(out, "agreement check \\(T1a\\)")
  expect_match(out, "extra-factor check \\(T1b\\)")
  expect_match(out, "paired-comparison check \\(T2\\)")
  expect_match(out, "diagnostics to read")
})

test_that("check_persons screens with verdicts and bands", {
  fit <- demo_fit()
  pc <- check_persons(fit, draws = 15, mixes = 30)
  expect_identical(nrow(pc), 8L)
  expect_true(all(pc$verdict %in% c("fits", "no_shared", "unspanned", "atypical")))
  expect_true(all(pc$m >= -1 & pc$m <= 1))
  expect_identical(length(attr(pc, "band_m")), 2L)
  expect_identical(dim(attr(pc, "band_w")), c(8L, 2L))
})

test_that("unspanned_cluster demands mutual partners", {
  pc <- data.frame(participant = c("P1", "P2", "P3"),
                   partner = c("P2", "P3", "P1"),
                   verdict = c("unspanned", "unspanned", "fits"),
                   stringsAsFactors = FALSE)
  expect_false(unspanned_cluster(pc))         # P1 -> P2 but P2 -> P3
  pc$partner <- c("P2", "P1", "P1")
  expect_true(unspanned_cluster(pc))          # P1 <-> P2
})

test_that("loglik_person returns finite log-likelihoods with CRN seeds", {
  fit <- demo_fit()
  ll <- loglik_person(fit, draws = 10, R = 32, seed = 1)
  expect_identical(dim(ll), c(10L, 8L))
  expect_true(all(is.finite(ll)))
  expect_true(all(ll < 0))
  ll2 <- loglik_person(fit, draws = 10, R = 32, seed = 1)
  expect_identical(ll, ll2)                   # deterministic given the seed
})

test_that("GHK probabilities sum to one over all sorts of a toy grid", {
  skip_on_cran()
  distr <- c(1, 2, 1)
  sorts <- list()
  rec <- function(prefix, left) {
    if (!any(left > 0)) { sorts[[length(sorts) + 1]] <<- prefix; return(invisible()) }
    for (c in which(left > 0)) {
      l2 <- left; l2[c] <- l2[c] - 1L
      rec(c(prefix, c), l2)
    }
  }
  rec(integer(0), as.integer(distr))
  set.seed(2)
  m <- rnorm(4, 0, 0.8)
  tot <- sum(vapply(sorts, function(y)
    exp(ghk_loglik(y, m, distr, R = 8192, seed = 9)), numeric(1)))
  expect_equal(tot, 1, tolerance = 0.05)      # the paper's own G1b bar
})

test_that("the ladder fits, selects, and re-selects without refitting", {
  skip_on_cran()
  set.seed(21)
  N <- 9; J <- 13; K0 <- 2
  distr <- get_distribution(J)
  L0 <- matrix(0, N, K0)
  L0[cbind(seq_len(N), rep_len(seq_len(K0), N))] <- 1.4
  F0 <- matrix(rnorm(J * K0), J, K0)
  Y <- t(quota_sort_rows(L0 %*% t(F0) + matrix(rnorm(N * J), N, J), distr))
  qd <- qsort_data(Y, distribution = distr, validate = FALSE)

  lad <- fit_ladder(qd, K_min = 2, K_max = 3, iterations = 700, burn = 100,
                    thin = 3, max_iterations = 700, seed = 3,
                    rhat_max = Inf, ess_min = 0, quiet = TRUE)
  expect_s3_class(lad, "bayesqm_ladder")
  expect_identical(lad$K, 2:3)

  sel <- select_k(lad)
  expect_s3_class(sel, "bayesqm_selection")
  expect_true(sel$verdict %in% c("selected", "tension",
                                 "adequate_but_unsupported", "no_adequate_rung",
                                 "no_shared_structure", "single_viewpoint"))
  expect_identical(nrow(sel$table), 2L)
  out <- paste(capture.output(print(sel)), collapse = "\n")
  expect_match(out, "two-signal rule")

  sel2 <- select_k(lad, q = 0.2)              # re-select, no refit
  expect_identical(sel2$q, 0.2)
})

test_that("a noise panel reaches the no-shared-structure branch", {
  skip_on_cran()
  set.seed(5)
  N <- 8; J <- 13
  distr <- get_distribution(J)
  Y <- t(quota_sort_rows(matrix(rnorm(N * J), N, J), distr))
  qd <- qsort_data(Y, distribution = distr, validate = FALSE)
  lad <- fit_ladder(qd, K_min = 2, K_max = 2, iterations = 500, burn = 100,
                    thin = 4, max_iterations = 500, seed = 7,
                    rhat_max = Inf, ess_min = 0, quiet = TRUE)
  sel <- select_k(lad)
  expect_true(sel$verdict %in% c("no_shared_structure", "no_adequate_rung",
                                 "adequate_but_unsupported", "single_viewpoint"))
  expect_true(is.na(sel$K))
})

test_that("the selection carries per-factor evidence and plots the decision", {
  skip_on_cran()
  set.seed(21)
  N <- 9; J <- 13; K0 <- 2
  distr <- get_distribution(J)
  L0 <- matrix(0, N, K0)
  L0[cbind(seq_len(N), rep_len(seq_len(K0), N))] <- 1.4
  F0 <- matrix(rnorm(J * K0), J, K0)
  Y <- t(quota_sort_rows(L0 %*% t(F0) + matrix(rnorm(N * J), N, J), distr))
  qd <- qsort_data(Y, distribution = distr, validate = FALSE)
  lad <- fit_ladder(qd, K_min = 2, K_max = 3, iterations = 700, burn = 100,
                    thin = 3, max_iterations = 700, seed = 3,
                    rhat_max = Inf, ess_min = 0, quiet = TRUE)
  sel <- select_k(lad)
  expect_identical(names(sel$detail),
                   c("K", "factor", "flags", "has_dist", "supported"))
  expect_identical(nrow(sel$detail), 2L + 3L)      # per-factor rows per rung
  expect_identical(sel$detail$supported,
                   sel$detail$flags >= 2 & sel$detail$has_dist)
  tmp <- tempfile(fileext = ".pdf"); grDevices::pdf(tmp)
  expect_invisible(plot_choice_k(sel))
  grDevices::dev.off(); unlink(tmp)
})

test_that("dead plot names error with pointers; plot_tucker forwards", {
  expect_error(plot_elpd(), "plot_choice_k")
  expect_error(make_elpd_diff(), "loo_ladder")
  expect_error(make_ppc_ridge(), "select_k")
  expect_error(make_dominant_panel(), "plot_flags")
  fit <- demo_fit()
  tmp <- tempfile(fileext = ".pdf"); grDevices::pdf(tmp)
  expect_warning(plot_tucker(fit), "plot_convergence")
  grDevices::dev.off(); unlink(tmp)
})

test_that("unanimity and emptiness get opposite null verdicts", {
  fake_rung <- function(K, flags_n, has_dist) {
    fit <- make_fake_fit(N = 6, J = 10, K = K)
    fac <- dimnames(fit$draws$sigma)[[2]]
    list(K = K, fit = fit, t1b = 0.5, cluster = FALSE,
         converged = TRUE,
         supported = rep(FALSE, K),
         flags = data.frame(participant = if (flags_n) paste0("P", seq_len(flags_n)) else character(0),
                            factor = rep(fac[1], flags_n),
                            sign = rep(1, flags_n),
                            flag_prob = rep(0.9, flags_n)),
         distinguishing = data.frame(statement = character(0),
                                     factor = character(0),
                                     dist_prob = numeric(0)))
  }
  unanimous <- structure(list(K = 2L, rungs = list(fake_rung(2, 5, FALSE)),
                              q = 0.05, N = 6), class = "bayesqm_ladder")
  expect_identical(select_k(unanimous)$verdict, "single_viewpoint")
  empty <- structure(list(K = 2L, rungs = list(fake_rung(2, 0, FALSE)),
                          q = 0.05, N = 6), class = "bayesqm_ladder")
  expect_identical(select_k(empty)$verdict, "no_shared_structure")
})
