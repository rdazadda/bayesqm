# Demo constructors for bayesqm_fit and bayesqm_run. Produce reproducible
# synthetic objects with realistic Q-methodology structure: participants
# load predominantly on one factor, statements partition into polarising,
# consensus, neutral, and partial groups, and posterior spread is tight
# enough for credible intervals to separate from zero.


#' A synthetic bayesqm_fit for examples and tutorials
#'
#' @description
#' Returns a `bayesqm_fit` with realistic Q-methodology structure:
#' every participant has a dominant factor, roughly 40 percent of the
#' statements polarise the factor pair, 10 percent are consensus, and
#' the remainder are weakly partial. Use it for documentation,
#' teaching materials, and the package vignette; it is not a
#' substitute for [fit_bayesian()] on real data.
#'
#' @param N Number of participants.
#' @param J Number of statements.
#' @param K Number of factors.
#' @param Td Number of posterior draws.
#' @param seed Integer seed for reproducibility; `NULL` leaves the
#'   random number generator untouched.
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
  if (!is.null(seed)) set.seed(seed)

  # Loadings: each participant gets a primary factor with a clear
  # positive loading, small random cross-loadings on the others.
  Lambda_mean  <- matrix(0, N, K)
  primary      <- ((seq_len(N) - 1L) %% K) + 1L
  for (i in seq_len(N)) {
    Lambda_mean[i, ]          <- runif(K, -0.15, 0.15)
    Lambda_mean[i, primary[i]] <- runif(1, 0.55, 0.85)
  }
  Lambda_draws <- array(0, c(Td, N, K))
  for (i in seq_len(N)) for (k in seq_len(K)) {
    Lambda_draws[, i, k] <- rnorm(Td, mean = Lambda_mean[i, k], sd = 0.08)
  }

  # Factor scores: mix of polarising, consensus, neutral, and partial
  # statements so the distinguishing / consensus plots have signal.
  F_mean <- matrix(0, J, K)
  n_pole   <- max(round(0.40 * J), K)
  n_cons   <- max(round(0.10 * J), 1L)
  n_neut   <- max(round(0.10 * J), 1L)
  n_part   <- J - n_pole - n_cons - n_neut

  # Polarising: strongly positive on one factor, strongly negative on
  # the others, cycled across the statements.
  for (j in seq_len(n_pole)) {
    kp <- ((j - 1L) %% K) + 1L
    F_mean[j, ]   <- -1.3
    F_mean[j, kp] <-  1.5
  }
  # Consensus: every factor agrees (roughly half positive, half negative).
  for (j in seq_len(n_cons)) {
    row <- n_pole + j
    F_mean[row, ] <- if (j %% 2 == 0) 1.1 else -1.1
  }
  # Neutral: around zero on every factor.
  for (j in seq_len(n_neut)) {
    F_mean[n_pole + n_cons + j, ] <- runif(K, -0.25, 0.25)
  }
  # Partial: non-trivial differences but not extreme.
  if (n_part > 0L) for (j in seq_len(n_part)) {
    row <- n_pole + n_cons + n_neut + j
    F_mean[row, ] <- runif(K, -0.9, 0.9)
  }
  # Shuffle so the plot rows are not artificially ordered by type.
  stmt_ord        <- sample.int(J)
  F_mean          <- F_mean[stmt_ord, , drop = FALSE]

  F_draws <- array(0, c(Td, J, K))
  for (j in seq_len(J)) for (k in seq_len(K)) {
    F_draws[, j, k] <- rnorm(Td, mean = F_mean[j, k], sd = 0.22)
  }

  distribution <- get_distribution(J)
  L_hat <- apply(Lambda_draws, c(2, 3), mean); dim(L_hat) <- c(N, K)
  F_hat <- apply(F_draws,      c(2, 3), mean); dim(F_hat) <- c(J, K)
  Y_cont <- F_hat %*% t(L_hat) + matrix(rnorm(J * N, 0, 0.25), J, N)
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
    align_info   = list(congruence = matrix(rbeta(Td * K, 85, 5),
                                            Td, K),
                        pivot = 1L),
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


#' A synthetic bayesqm_run for examples and tutorials
#'
#' @description
#' Returns a `bayesqm_run` object carrying a plausible ELPD trajectory
#' across K = 1..K_max, with user-chosen peak K, Sivula K, and case
#' label. Use it to demonstrate [run_bayes()] output and
#' [plot_elpd()] without a Stan backend; it is not a substitute for
#' `run_bayes()` on real data.
#'
#' @param K_max Largest K in the comparison (default 4).
#' @param k_peak K value where ELPD peaks (default 3).
#' @param k_sivula K chosen by the Sivula parsimony rule (default 2).
#' @param case Case label: `"agree"`, `"gap"`, or `"reversed"`.
#' @param seed Integer seed for reproducibility; `NULL` leaves the
#'   random number generator untouched.
#'
#' @return A `bayesqm_run`.
#'
#' @examples
#' run <- demo_run()
#' run
#' plot_elpd(run)
#'
#' @export
demo_run <- function(K_max = 4L, k_peak = 3L, k_sivula = 2L,
                     case = c("gap", "agree", "reversed"),
                     seed = 1L) {
  case <- match.arg(case)
  if (!is.null(seed)) set.seed(seed)

  K    <- seq_len(K_max)
  elpd <- -abs(K - k_peak) ^ 1.3 * 6 - 165 + rnorm(K_max, 0, 0.5)
  se   <- seq(8, 5, length.out = K_max)

  delta_elpd <- c(NA_real_, diff(-elpd))
  se_delta   <- c(NA_real_, rep(3, K_max - 1L))
  ratio      <- abs(delta_elpd) / se_delta

  tab <- data.frame(K = K,
                    elpd = elpd, se = se,
                    delta_elpd = delta_elpd,
                    se_delta   = se_delta,
                    ratio      = ratio)

  structure(
    list(
      call     = quote(run_bayes(qdata, K_max = K_max)),
      fits     = vector("list", K_max),
      tab      = tab,
      loo_list = vector("list", K_max),
      k_peak   = as.integer(k_peak),
      k_sivula = as.integer(k_sivula),
      case     = case
    ),
    class = "bayesqm_run")
}
