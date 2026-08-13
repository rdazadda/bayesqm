# Construct a synthetic bayesqm_fit without sampling. Draws respect the
# column conventions (centered, unit-sd score columns), so every accessor,
# print method, and summary function works against a fit built this way.

make_fake_fit <- function(N = 6, J = 10, K = 2, T = 120, seed = 1L,
                          converged = TRUE, extended = FALSE) {
  set.seed(seed)
  distr <- get_distribution(J)
  L0 <- matrix(0, N, K)
  L0[cbind(seq_len(N), rep_len(seq_len(K), N))] <- 1.2

  Fd <- array(NA_real_, c(T, J, K))
  Ld <- array(NA_real_, c(T, N, K))
  Sd <- matrix(abs(rnorm(T * K, 1, 0.1)), T, K)
  si <- matrix(NA_real_, T, N)
  for (t in seq_len(T)) {
    F <- matrix(rnorm(J * K), J, K)
    F <- sweep(F, 2, colMeans(F))
    F <- sweep(F, 2, sqrt(colMeans(F^2)), "/")
    L <- L0 + matrix(rnorm(N * K, 0, 0.15), N, K)
    Fd[t, , ] <- F; Ld[t, , ] <- L
    si[t, ] <- sqrt(rowSums((L %*% (crossprod(F) / J)) * L))
  }
  draws <- list(F = Fd, Lambda = Ld, sigma = Sd, s_i = si)

  Fm <- apply(Fd, c(2, 3), mean); dim(Fm) <- c(J, K)
  Lm <- apply(Ld, c(2, 3), mean); dim(Lm) <- c(N, K)
  Y <- quota_sort_rows(t(Fm %*% t(Lm)) + matrix(rnorm(N * J, 0, .1), N, J), distr)
  Y <- t(Y)
  rownames(Y) <- paste0("S", seq_len(J))
  colnames(Y) <- paste0("P", seq_len(N))

  gate <- list(converged = converged, extended = extended,
               iterations = if (extended) 1600L else 800L, floor = 800L,
               cap = 3200L, rhat = 1.004, ess_bulk = 450, ess_tail = 430,
               rhat_max = 1.01, ess_min = 400)

  new_bayesqm_fit(
    call = quote(fit_bayesian(Y, K = K)),
    Y = Y, distribution = distr, K = K,
    draws = draws, draws_raw = NULL, state = NULL,
    gate = gate,
    align = list(pivot = 1L, congruence = rep(0.95, T)),
    prob = 0.95, seed = seed,
    settings = list(burn = 200L, thin = 5L, sigma_scale = 1)
  )
}
