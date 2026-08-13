# demo_fit.R
# A tiny real fit for examples, tests, and vignettes: seconds of sampling,
# no convergence gate, fixed seed. Everything a bayesqm_fit carries is
# present, at toy scale.


#' A small demonstration fit
#'
#' @description
#' Runs the partition-model sampler on a small synthetic forced-sort
#' dataset with a fixed seed and the convergence gate disabled. It exists
#' so examples and tests have a complete `bayesqm_fit` in about a second;
#' it is no substitute for [fit_bayesian()] at its defaults on real data.
#'
#' @param N,J,K Panel size, statement count, factors (defaults 8, 13, 2).
#' @param draws Kept posterior draws (default 200).
#' @param seed Random seed (default 1).
#'
#' @return A `bayesqm_fit`.
#'
#' @examples
#' fit <- demo_fit()
#' fit
#'
#' @export
demo_fit <- function(N = 8, J = 13, K = 2, draws = 200, seed = 1) {
  distr <- get_distribution(J)
  set.seed(seed)
  L0 <- matrix(0, N, K)
  grp <- rep_len(seq_len(K), N)
  L0[cbind(seq_len(N), grp)] <- 1.2
  F0 <- matrix(rnorm(J * K), J, K)
  U <- L0 %*% t(F0) + matrix(rnorm(N * J), N, J)
  Y <- t(quota_sort_rows(U, distr))
  rownames(Y) <- paste0("S", seq_len(J))
  colnames(Y) <- paste0("P", seq_len(N))

  thin <- 2L
  burn <- 100L
  fit_bayesian(qsort_data(Y, distribution = distr, validate = FALSE),
               K = K, iterations = burn + thin * draws, burn = burn,
               thin = thin, max_iterations = burn + thin * draws,
               seed = seed + 1, rhat_max = Inf, ess_min = 0,
               quiet = TRUE)
}
