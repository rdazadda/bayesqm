# Demo fit constructor: a reproducible synthetic bayesqm_fit that runs
# everything downstream (summaries, plots, accessors) without needing a
# Stan backend. Use it in examples, tutorials, and the package vignette;
# it is NOT a substitute for fit_bayesian() on real data.


#' A synthetic bayesqm_fit for examples and tutorials
#'
#' @description
#' Returns a `bayesqm_fit` object built from pre-generated posterior
#' draws, so every summary and plot function can run without a Stan
#' backend. Use it for demonstrations, teaching materials, and the
#' package vignette. It is not a substitute for [fit_bayesian()] on
#' real data.
#'
#' @param N Number of participants.
#' @param J Number of statements.
#' @param K Number of factors.
#' @param Td Number of posterior draws.
#' @param seed Integer seed for reproducibility.
#'
#' @return A `bayesqm_fit`.
#'
#' @examples
#' fit <- demo_fit(N = 12, J = 15, K = 2)
#' plot(fit)
#' summary(fit)
#'
#' @export
demo_fit <- function(N = 20, J = 22, K = 2, Td = 400, seed = 1L) {
  set.seed(seed)

  Lambda_draws <- array(rnorm(Td * N * K, sd = 0.35), c(Td, N, K))
  for (i in seq_len(N)) {
    k_dom <- ((i - 1L) %% K) + 1L
    Lambda_draws[, i, k_dom] <- Lambda_draws[, i, k_dom] + 0.85
  }
  F_draws <- array(rnorm(Td * J * K), c(Td, J, K))

  distribution <- get_distribution(J)
  L_mean <- apply(Lambda_draws, c(2, 3), mean); dim(L_mean) <- c(N, K)
  F_mean <- apply(F_draws,      c(2, 3), mean); dim(F_mean) <- c(J, K)
  Y_cont <- F_mean %*% t(L_mean) + matrix(rnorm(J * N, 0, 0.3), J, N)
  Y      <- discretize_to_grid(Y_cont, distribution)
  rownames(Y) <- paste0("S", seq_len(J))
  colnames(Y) <- paste0("P", seq_len(N))

  dm    <- c(N, K)
  Lhat  <- apply(Lambda_draws, c(2, 3), mean);   dim(Lhat) <- dm
  Lmed  <- apply(Lambda_draws, c(2, 3), median); dim(Lmed) <- dm
  ci_lo <- apply(Lambda_draws, c(2, 3), quantile, probs = 0.025, names = FALSE)
  ci_hi <- apply(Lambda_draws, c(2, 3), quantile, probs = 0.975, names = FALSE)
  dim(ci_lo) <- dm; dim(ci_hi) <- dm

  priors <- list(
    loading_scale   = 1.0,
    sigma_scale     = 1.0,
    nu_alpha        = 2.0,
    nu_beta         = 0.1,
    use_half_cauchy = FALSE
  )

  new_bayesqm_fit(
    call         = quote(fit_bayesian(Y, K = K)),
    Y            = Y,
    K            = K,
    distribution = distribution,
    prob         = 0.95,
    robust       = TRUE,
    nu           = "estimate",
    chains       = 4,
    iter         = 2000,
    warmup       = 1000,
    backend      = "demo",
    priors       = priors,
    Lhat         = Lhat,
    Lmed         = Lmed,
    ci_lo        = ci_lo,
    ci_hi        = ci_hi,
    Lambda_draws = Lambda_draws,
    F_draws      = F_draws,
    align_info   = list(congruence = matrix(0.96, Td, K), pivot = 1L),
    hyperparams  = list(
      nu    = abs(rnorm(Td, 20, 4)),
      sigma = abs(rnorm(Td, 0.5, 0.08)),
      tau   = abs(rnorm(Td, 0.5, 0.08))
    ),
    loo_el = NULL,
    loo_ps = NULL,
    diag   = list(rhat_max = 1.01, ess_bulk = 820L,
                  ess_tail = 950L, divergences = 0L),
    ppc    = list(rmse.r = abs(rnorm(Td, 0.18, 0.03)))
  )
}
