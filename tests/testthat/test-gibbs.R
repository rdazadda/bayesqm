# The partition-likelihood engine: quota sort, grid constants, the PX-Gibbs
# sampler's warm-start contract, and the convergence gate. The bitwise
# identity tests are frozen: any change to the sampler's RNG consumption
# order must fail here before it ships.

toy_sort <- function(N = 8, J = 12, distr = c(2, 3, 4, 2, 1), seed = 1) {
  set.seed(seed)
  quota_sort_rows(matrix(rnorm(N * J), N, J), distr)
}

test_that("delta_grid pins the paper's constants", {
  expect_equal(delta_grid(c(2, 3, 4, 5, 7, 7, 5, 4, 3, 2)), 0.4268636566,
               tolerance = 1e-9)
  expect_equal(delta_grid(c(1, 2, 2, 3, 4, 3, 2, 2, 1)), 0.4714045208,
               tolerance = 1e-9)
  expect_equal(delta_grid(c(4, 5, 7, 9, 10, 10, 10, 9, 7, 5, 4)), 0.3720326659,
               tolerance = 1e-9)
})

test_that("quota_sort obeys the quotas, order, and permutation equivariance", {
  distr <- c(2, 3, 4, 5, 7, 7, 5, 4, 3, 2)
  set.seed(2)
  u <- rnorm(42)
  y <- quota_sort(u, distr)
  expect_identical(tabulate(y, 10), as.integer(distr))
  expect_true(all(diff(y[order(u)]) >= 0))
  p <- sample(42)
  expect_identical(quota_sort(u[p], distr), y[p])
  U <- matrix(rnorm(5 * 42), 5, 42)
  expect_identical(quota_sort_rows(U, distr),
                   t(apply(U, 1, quota_sort, distr = distr)))
})

test_that("midranks are the tied ranks of the grid positions", {
  distr <- c(2, 3, 4, 2, 1)
  y <- rep(seq_along(distr), distr)
  expect_equal(midranks(distr), unique(rank(y)))
  expect_equal(sum(midranks(distr) * distr), sum(seq_len(sum(distr))))
})

test_that("a continued chain is draw-for-draw identical to one long run", {
  distr <- c(2, 3, 4, 2, 1)
  Y <- toy_sort(distr = distr)
  straight <- fit_partition(Y, distr, K = 2, n_iter = 1200, burn = 200,
                            thin = 5, seed = 7)
  base <- fit_partition(Y, distr, K = 2, n_iter = 600, burn = 200,
                        thin = 5, seed = 7)
  ext <- fit_partition(Y, distr, K = 2, n_iter = 600, burn = 0, thin = 5,
                       state = base$state)
  grown <- grow_fit(base, ext)
  expect_identical(straight$F, grown$F)
  expect_identical(straight$Lambda, grown$Lambda)
  expect_identical(straight$sigma, grown$sigma)
  expect_identical(straight$s_i, grown$s_i)
  expect_identical(straight$state, grown$state)
})

test_that("the identity survives unrelated RNG use between fit and extension", {
  distr <- c(2, 3, 4, 2, 1)
  Y <- toy_sort(distr = distr)
  straight <- fit_partition(Y, distr, K = 2, n_iter = 1200, burn = 200,
                            thin = 5, seed = 7)
  base <- fit_partition(Y, distr, K = 2, n_iter = 600, burn = 200,
                        thin = 5, seed = 7)
  runif(1000); sample(1e6, 50)              # a user's session happens here
  ext <- fit_partition(Y, distr, K = 2, n_iter = 600, burn = 0, thin = 5,
                       state = base$state)
  expect_identical(straight$F, grow_fit(base, ext)$F)
})

test_that("the gate consumes no RNG", {
  distr <- c(2, 3, 4, 2, 1)
  Y <- toy_sort(distr = distr)
  fit <- fit_partition(Y, distr, K = 2, n_iter = 400, burn = 100, thin = 5,
                       seed = 3)
  before <- .Random.seed
  cv <- check_conv(fit)
  expect_identical(.Random.seed, before)
  expect_true(is.finite(cv$rhat))
})

test_that("the ladder extends to the cap and reports honestly", {
  distr <- c(2, 3, 4, 2, 1)
  Y <- toy_sort(distr = distr)
  # unreachable bar: every rung fails, the ladder stops exactly at the cap
  fit <- fit_partition_gated(Y, distr, K = 2, seed = 5, n_iter = 400,
                             burn = 100, thin = 5, n_max = 1600,
                             ess_min = 1e6)
  expect_false(fit$converged)
  expect_true(fit$extended)
  expect_identical(fit$iters, 1600L)
  expect_identical(dim(fit$F)[1], as.integer((1600 - 100) / 5))
  # trivial bar: the floor suffices, nothing extends
  fit2 <- fit_partition_gated(Y, distr, K = 2, seed = 5, n_iter = 400,
                              burn = 100, thin = 5, n_max = 1600,
                              rhat_max = Inf, ess_min = 0)
  expect_true(fit2$converged)
  expect_false(fit2$extended)
  expect_identical(fit2$iters, 400L)
})

test_that("fit_partition refuses sorts that violate the quotas", {
  distr <- c(2, 3, 4, 2, 1)
  Y <- toy_sort(distr = distr)
  Y[1, 1] <- Y[1, 1] %% 5 + 1               # break one person's counts
  expect_error(fit_partition(Y, distr, K = 2, n_iter = 200, burn = 50,
                             thin = 5, seed = 1))
})

test_that("the stored s_i matches its definition on the kept draws", {
  distr <- c(2, 3, 4, 2, 1)
  Y <- toy_sort(distr = distr)
  fit <- fit_partition(Y, distr, K = 2, n_iter = 400, burn = 100, thin = 5,
                       seed = 9)
  t <- 10
  F <- matrix(fit$F[t, , ], ncol = 2)
  L <- matrix(fit$Lambda[t, , ], ncol = 2)
  Fc <- sweep(F, 2, colMeans(F))
  expect_equal(fit$s_i[t, ],
               sqrt(rowSums((L %*% (crossprod(Fc) / ncol(Y))) * L)),
               tolerance = 1e-12)
})
