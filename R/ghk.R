# ghk.R
# GHK evaluation of the partition likelihood, for person-level
# log-likelihoods and the PSIS-LOO bridge. The draw follows ascending
# category order with a running lower bound: that is exactly the cone
# event the quotas define.

#' @keywords internal
#' @noRd
ghk_loglik <- function(y, m, distr, R = 512, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  J <- length(y)
  ord <- order(y)
  cat_of <- y[ord]; mu <- m[ord]
  L <- rep(-Inf, R); cmax <- rep(-Inf, R); lw <- numeric(R)
  cur <- cat_of[1]
  for (idx in seq_len(J)) {
    if (cat_of[idx] != cur) { L <- cmax; cmax <- rep(-Inf, R); cur <- cat_of[idx] }
    plo <- pnorm(L - mu[idx])
    p <- 1 - plo
    lw <- lw + log(pmax(p, 1e-300))
    u <- mu[idx] + qnorm(pmin(pmax(plo + runif(R) * p, 1e-15), 1 - 1e-15))
    cmax <- pmax(cmax, pmax(u, L))
  }
  M <- max(lw)
  M + log(mean(exp(lw - M)))
}


#' Person-level partition log-likelihoods
#'
#' @description
#' GHK-simulated log-likelihood of each participant's sort under each
#' kept posterior draw (thinned to `draws`), the input PSIS-LOO needs.
#' The GHK seed depends only on the draw index and the person, never on
#' `K`, so log-likelihoods are common-random-number comparable across a
#' ladder of fits.
#'
#' @param fit A `bayesqm_fit`.
#' @param draws Posterior draws to evaluate (default 100, thinned evenly).
#' @param R GHK replications per evaluation (default 64).
#' @param seed Base seed for the GHK draws (default 1).
#'
#' @return A `draws x N` matrix of log-likelihoods.
#'
#' @export
loglik_person <- function(fit, draws = 100, R = 64, seed = 1) {
  assert_bayesqm_fit(fit)
  # the GHK seeds are deterministic; leave the caller's RNG stream untouched
  if (exists(".Random.seed", envir = globalenv())) {
    old_rng <- get(".Random.seed", envir = globalenv())
    on.exit(assign(".Random.seed", old_rng, envir = globalenv()), add = TRUE)
  }
  d <- fit$draws
  T_ <- dim(d$F)[1]; N <- fit$brief$N; J <- fit$brief$J; K <- fit$brief$K
  Y <- t(fit$dataset)
  td <- unique(round(seq(1, T_, length.out = min(draws, T_))))
  ll <- matrix(NA_real_, length(td), N)
  for (ti in seq_along(td)) {
    t <- td[ti]
    Eta <- matrix(d$Lambda[t, , ], N, K) %*% t(matrix(d$F[t, , ], J, K))
    ll[ti, ] <- vapply(seq_len(N), function(i)
      ghk_loglik(Y[i, ], Eta[i, ], fit$distribution, R = R,
                 seed = seed + 1000L * ti + i), numeric(1))
  }
  colnames(ll) <- dimnames(d$Lambda)[[2]]
  ll
}
