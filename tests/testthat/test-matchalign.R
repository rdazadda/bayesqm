# Alignment: conventions exactness, the polarity canon at the stabilized
# mean, sigma carriage, and invariance of the aligned draws to signed
# label permutations of the input.

align_fixture <- function(T_ = 40, N = 10, J = 12, K = 3, seed = 4) {
  set.seed(seed)
  base_F <- matrix(rnorm(J * K), J, K)
  base_L <- matrix(rnorm(N * K, 0, c(1.6, 1.0, 0.6)), N, K, byrow = TRUE)
  fit <- list(F = array(NA_real_, c(T_, J, K)),
              Lambda = array(NA_real_, c(T_, N, K)),
              sigma = matrix(NA_real_, T_, K),
              N = N, J = J, K = K)
  for (t in 1:T_) {
    th <- runif(1, 0, 2 * pi)
    R <- diag(K)
    R[1:2, 1:2] <- matrix(c(cos(th), sin(th), -sin(th), cos(th)), 2)
    p <- sample(K); s <- sample(c(-1, 1), K, replace = TRUE)
    M <- (R[, p] %*% diag(s, K))
    fit$F[t, , ] <- (base_F + matrix(rnorm(J * K, 0, .1), J, K)) %*% M
    fit$Lambda[t, , ] <- (base_L + matrix(rnorm(N * K, 0, .1), N, K)) %*% M
    fit$sigma[t, ] <- rotate_sigma(c(1.6, 1.0, 0.6), M)
  }
  fit
}

test_that("conventions are exact after the full postprocess", {
  pp <- postprocess(align_fixture())
  for (t in c(1, 17, 40)) {
    F <- matrix(pp$F[t, , ], ncol = 3)
    expect_lt(max(abs(colMeans(F))), 1e-10)
    expect_lt(max(abs(colMeans(F^2) - 1)), 1e-10)
  }
})

test_that("the polarity canon holds at the aligned mean", {
  pp <- postprocess(align_fixture())
  Lm <- apply(pp$Lambda, c(2, 3), mean)
  expect_true(all(colSums(Lm^3) > 0))
})

test_that("alignment is equivariant to signed label permutations of the input", {
  # the aligned posteriors must agree up to one GLOBAL label permutation
  # (the pivot's varimax column order follows its input order); signs are
  # fixed by the polarity canon, so the matched columns must agree exactly
  fit <- align_fixture()
  scr <- fit
  p <- c(3, 1, 2); s <- c(-1, 1, -1)
  for (t in seq_len(dim(fit$F)[1])) {
    scr$F[t, , ] <- sweep(matrix(fit$F[t, , p], ncol = 3), 2, s, "*")
    scr$Lambda[t, , ] <- sweep(matrix(fit$Lambda[t, , p], ncol = 3), 2, s, "*")
    scr$sigma[t, ] <- fit$sigma[t, p]
  }
  a <- postprocess(fit, pivot = 5)
  b <- postprocess(scr, pivot = 5)
  La <- apply(a$Lambda, c(2, 3), mean)
  Lb <- apply(b$Lambda, c(2, 3), mean)
  perm <- apply(abs(cor(La, Lb)), 1, which.max)
  expect_identical(sort(perm), 1:3)                    # a real permutation
  expect_equal(a$Lambda, b$Lambda[, , perm, drop = FALSE], tolerance = 1e-8)
  expect_equal(a$F, b$F[, , perm, drop = FALSE], tolerance = 1e-8)
  expect_equal(a$sigma, b$sigma[, perm, drop = FALSE], tolerance = 1e-8)
})

test_that("conventions hold for every draw and congruence to the pivot is high", {
  pp <- postprocess(align_fixture(), pivot = 5)
  for (t in seq_len(dim(pp$F)[1])) {
    F <- matrix(pp$F[t, , ], ncol = 3)
    expect_lt(max(abs(colMeans(F))), 1e-10)
    expect_lt(max(abs(colMeans(F^2) - 1)), 1e-10)
  }
  # the fixture is one structure plus noise, so alignment must recover it
  expect_gt(mean(pp$congruence), 0.9)
})

test_that("sigma is carried exactly through permutation and sign", {
  sig <- c(1.6, 1.0, 0.6)
  P <- diag(3)[, c(2, 3, 1)] %*% diag(c(-1, 1, -1))
  expect_equal(rotate_sigma(sig, P), sig[c(2, 3, 1)], tolerance = 1e-12)
})

test_that("K = 1 aligns by sign only", {
  set.seed(6)
  fit <- list(F = array(rnorm(20 * 8), c(20, 8, 1)),
              Lambda = array(rnorm(20 * 5), c(20, 5, 1)),
              sigma = matrix(1, 20, 1), N = 5, J = 8, K = 1)
  for (t in 1:20) {
    s <- sample(c(-1, 1), 1)
    fit$F[t, , 1] <- s * (1:8 / 4 + rnorm(8, 0, .1))
    fit$Lambda[t, , 1] <- s * (c(2, 1.5, 1, .5, .2) + rnorm(5, 0, .1))
  }
  pp <- postprocess(fit)
  Lm <- apply(pp$Lambda, c(2, 3), mean)
  expect_true(all(sign(Lm) == sign(Lm[1])))   # one common orientation
})

test_that("stored s_i is invariant to the whole alignment", {
  skip_if_not_installed("posterior")
  distr <- c(2, 3, 4, 2, 1)
  set.seed(11)
  Y <- quota_sort_rows(matrix(rnorm(8 * 12), 8, 12), distr)
  fit <- fit_partition(Y, distr, K = 2, n_iter = 400, burn = 100, thin = 5,
                       seed = 2)
  pp <- postprocess(fit)
  t <- 7
  F <- matrix(pp$F[t, , ], ncol = 2); L <- matrix(pp$Lambda[t, , ], ncol = 2)
  Fc <- sweep(F, 2, colMeans(F))
  expect_equal(sqrt(rowSums((L %*% (crossprod(Fc) / 12)) * L)),
               fit$s_i[t, ], tolerance = 1e-8)
})
