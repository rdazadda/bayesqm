# membership.R
# Posterior summaries of factor membership and statement interpretation.
# Input draws must be MatchAlign-aligned or these summaries are meaningless.


#' Probabilistic factor-membership summaries
#'
#' @description
#' The paper's Section 6 summaries, each computed entirely from posterior
#' draws:
#'
#' - `compute_threshold_prob()` returns the `N x K` posterior
#'   probability that `|lambda_ik| > threshold`, i.e. the Bayesian
#'   version of the Brown (1980) flagging rule.
#' - `compute_dominant_prob()` returns the `N x K` posterior
#'   probability that factor `k` is the dominant factor for participant
#'   `i`.
#' - `compute_distinguishing_prob()` returns `P(|f_jk - f_jl| > delta)`
#'   for every pair of factors.
#' - `compute_consensus_prob()` returns the joint probability that
#'   *every* factor pair's separation stays below `delta`.
#' - `classify_membership()` turns dominant probabilities into a
#'   per-participant tier verdict (Strong / Moderate / Weak).
#'
#' @param Lambda_draws Array of shape `[T, N, K]` of aligned loading
#'   draws.
#' @param F_draws Array of shape `[T, J, K]` of aligned factor-score
#'   draws.
#' @param threshold Numeric threshold; a natural default is
#'   `1.96 / sqrt(J)` for the Brown rule.
#' @param delta Minimum separation on the standardized factor-score
#'   scale (default `1.0`).
#' @param strong,moderate Tier cutoffs on `max P(dominant)` (defaults
#'   0.80 and 0.60 following the paper).
#'
#' @return `compute_threshold_prob()`, `compute_dominant_prob()` return
#'   `N x K` matrices. `compute_distinguishing_prob()` returns a
#'   `J x choose(K, 2)` matrix. `compute_consensus_prob()` returns a
#'   length-`J` named vector. `classify_membership()` returns a data
#'   frame.
#'
#' @name bayesqm-membership
#' @aliases compute_threshold_prob compute_dominant_prob compute_distinguishing_prob compute_consensus_prob classify_membership
#' @export
compute_threshold_prob <- function(Lambda_draws, threshold) {
  N <- dim(Lambda_draws)[2]
  K <- dim(Lambda_draws)[3]

  prob <- apply(abs(Lambda_draws) > threshold, c(2, 3), mean)
  dim(prob) <- dim(Lambda_draws)[2:3]

  rn <- dimnames(Lambda_draws)[[2]]
  cn <- dimnames(Lambda_draws)[[3]]
  if (is.null(rn)) rn <- paste0("P", seq_len(N))
  if (is.null(cn)) cn <- paste0("f", seq_len(K))
  dimnames(prob) <- list(rn, cn)
  prob
}


#' @rdname bayesqm-membership
#' @export
compute_dominant_prob <- function(Lambda_draws) {
  Td <- dim(Lambda_draws)[1]
  N  <- dim(Lambda_draws)[2]
  K  <- dim(Lambda_draws)[3]

  argmax <- apply(Lambda_draws, c(1, 2), function(v) which.max(abs(v)))

  prob <- matrix(0, N, K)
  for (i in seq_len(N))
    prob[i, ] <- tabulate(argmax[, i], nbins = K) / Td

  rn <- dimnames(Lambda_draws)[[2]]
  cn <- dimnames(Lambda_draws)[[3]]
  if (is.null(rn)) rn <- paste0("P", seq_len(N))
  if (is.null(cn)) cn <- paste0("f", seq_len(K))
  dimnames(prob) <- list(rn, cn)
  prob
}


#' @rdname bayesqm-membership
#' @export
compute_distinguishing_prob <- function(F_draws, delta = 1.0) {
  Td <- dim(F_draws)[1]
  J  <- dim(F_draws)[2]
  K  <- dim(F_draws)[3]
  if (K < 2) stop("compute_distinguishing_prob requires K >= 2.")

  pairs <- combn(K, 2)
  n_pairs <- ncol(pairs)

  out <- matrix(0, J, n_pairs)
  pair_names <- character(n_pairs)
  for (p in seq_len(n_pairs)) {
    k <- pairs[1, p]; ell <- pairs[2, p]
    pair_names[p] <- paste0("f", k, "-f", ell)
    dif <- matrix(F_draws[, , k] - F_draws[, , ell], nrow = Td, ncol = J)
    out[, p] <- colMeans(abs(dif) > delta)
  }

  sn <- dimnames(F_draws)[[2]]
  if (is.null(sn)) sn <- paste0("S", seq_len(J))
  dimnames(out) <- list(sn, pair_names)
  out
}


#' @rdname bayesqm-membership
#' @export
compute_consensus_prob <- function(F_draws, delta = 1.0) {
  Td <- dim(F_draws)[1]
  J  <- dim(F_draws)[2]
  K  <- dim(F_draws)[3]
  if (K < 2) return(setNames(rep(1, J), dimnames(F_draws)[[2]]))

  pairs <- combn(K, 2)
  max_diff <- matrix(0, Td, J)
  for (p in seq_len(ncol(pairs))) {
    k <- pairs[1, p]; ell <- pairs[2, p]
    dif <- matrix(F_draws[, , k] - F_draws[, , ell], nrow = Td, ncol = J)
    max_diff <- pmax(max_diff, abs(dif))
  }

  out <- colMeans(max_diff < delta)
  sn <- dimnames(F_draws)[[2]]
  names(out) <- if (is.null(sn)) paste0("S", seq_len(J)) else sn
  out
}


#' @rdname bayesqm-membership
#' @export
classify_membership <- function(Lambda_draws, strong = 0.80, moderate = 0.60) {
  prob <- compute_dominant_prob(Lambda_draws)
  max_prob   <- apply(prob, 1, max)
  dom_factor <- apply(prob, 1, which.max)

  tier <- ifelse(max_prob >  strong,   "Strong",
          ifelse(max_prob >  moderate, "Moderate", "Weak"))

  data.frame(
    participant     = rownames(prob),
    dominant_factor = dom_factor,
    dominant_label  = colnames(prob)[dom_factor],
    max_prob        = max_prob,
    tier            = factor(tier, levels = c("Strong", "Moderate", "Weak")),
    row.names       = NULL,
    stringsAsFactors = FALSE
  )
}
