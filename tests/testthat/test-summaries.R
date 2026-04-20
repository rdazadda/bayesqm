test_that("compute_threshold_prob and compute_dominant_prob return N x K matrices", {
  set.seed(1L)
  L <- array(rnorm(50 * 6 * 3), c(50, 6, 3))
  thr <- compute_threshold_prob(L, threshold = 0.5)
  dom <- compute_dominant_prob(L)
  expect_equal(dim(thr), c(6, 3))
  expect_equal(dim(dom), c(6, 3))
  expect_true(all(thr >= 0 & thr <= 1))
  expect_true(all(abs(rowSums(dom) - 1) < 1e-8))
})

test_that("compute_threshold_prob handles K = 1", {
  set.seed(1L)
  L <- array(rnorm(40 * 5 * 1), c(40, 5, 1))
  thr <- compute_threshold_prob(L, threshold = 0.3)
  expect_equal(dim(thr), c(5, 1))
})

test_that("compute_distinguishing_prob and consensus_prob require K >= 2", {
  set.seed(1L)
  Fd_k1 <- array(rnorm(40 * 5 * 1), c(40, 5, 1))
  expect_error(compute_distinguishing_prob(Fd_k1), "K >= 2")

  Fd <- array(rnorm(40 * 5 * 3), c(40, 5, 3))
  dist_prob <- compute_distinguishing_prob(Fd, delta = 1)
  cons_prob <- compute_consensus_prob(Fd,     delta = 1)
  expect_equal(dim(dist_prob), c(5, 3))
  expect_length(cons_prob, 5)
})

test_that("classify_membership produces correct tiers", {
  set.seed(1L)
  L <- array(rnorm(200 * 4 * 2), c(200, 4, 2))
  L[, 1, 1] <- L[, 1, 1] + 5
  cls <- classify_membership(L)
  expect_s3_class(cls, "data.frame")
  expect_equal(nrow(cls), 4)
  expect_equal(cls$tier[1], factor("Strong", levels = c("Strong", "Moderate", "Weak")))
})

test_that("compute_loadings and compute_zscores produce the expected column names", {
  set.seed(1L)
  L <- array(rnorm(60 * 5 * 3), c(60, 5, 3))
  loads <- compute_loadings(L, prob = 0.9)
  expect_equal(nrow(loads), 5)
  expect_true(all(c("f1_loa", "f1_lower", "f1_upper",
                    "f2_loa", "f2_lower", "f2_upper",
                    "f3_loa", "f3_lower", "f3_upper") %in% names(loads)))

  Fd <- array(rnorm(60 * 7 * 3), c(60, 7, 3))
  z <- compute_zscores(Fd, prob = 0.9)
  expect_equal(nrow(z), 7)
  expect_true(all(c("f1_zsc", "f1_lower", "f1_upper") %in% names(z)))
})

test_that("compute_posterior_scalars returns one row per non-empty vector", {
  draws <- list(nu = rt(200, df = 5) + 6, sigma = abs(rnorm(200)) + 1)
  out <- compute_posterior_scalars(draws, prob = 0.8)
  expect_equal(nrow(out), 2)
  expect_equal(out$parameter, c("nu", "sigma"))
  expect_true(all(c("mean", "median", "sd", "lower", "upper") %in% names(out)))
})
