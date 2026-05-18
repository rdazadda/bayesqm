# membership.R
# Posterior summaries of factor membership and statement interpretation.
# Input draws must be MatchAlign-aligned for these summaries to be valid.


#' Probabilistic factor-membership and divergence summaries
#'
#' @description
#' Posterior summaries of factor membership and statement
#' interpretation, each computed entirely from posterior draws:
#'
#' - `compute_threshold_prob()` returns the `N x K` posterior
#'   probability that `|lambda_ik| > threshold`, i.e. the Bayesian
#'   version of the Brown (1980) flagging rule.
#' - `compute_dominant_prob()` returns the `N x K` posterior
#'   probability that factor `k` is the dominant factor for participant
#'   `i`.
#' - `compute_dominant_sign()` returns the length-`N` posterior
#'   probability that the dominant loading is positive; participants
#'   with probability below 0.5 are negative exemplars.
#' - `compute_divergence()` returns the posterior of the viewpoint
#'   divergence `D_j` for every statement, together with the
#'   distinguishing and consensus probabilities it implies.
#' - `classify_membership()` turns dominant probabilities into a
#'   per-participant descriptive tier (Strong / Moderate / Weak).
#'
#' @param Lambda_draws Array of shape `[T, N, K]` of aligned loading
#'   draws.
#' @param F_draws Array of shape `[T, J, K]` of aligned factor-score
#'   draws.
#' @param threshold Numeric threshold; a natural default is
#'   `1.96 / sqrt(J)` for the Brown rule.
#' @param delta Substantive separation for the distinguishing and
#'   consensus probabilities. The fit pipeline supplies the default,
#'   the reliability-adjusted critical difference of [critical_delta()];
#'   [suggest_delta()] is an alternative. If `NULL` the `D_j` posterior
#'   (median, 95% CrI, `g_jk`) is still returned but the
#'   distinguishing/consensus probabilities are `NA`.
#' @param delta_grid Optional numeric vector of `delta` values for a
#'   sensitivity sweep.
#' @param strong,moderate Tier cutoffs on `max P(dominant)` (defaults
#'   0.80 and 0.60).
#'
#' @details
#' For statement `j` with standardized viewpoint scores
#' `f_{j1}, ..., f_{jK}`, the divergence estimand is the mean absolute
#' pairwise difference
#' `D_j = 2 / (K (K - 1)) * sum_{k < l} |f_jk - f_jl|`.
#' The mean is used rather than the maximum, which is an order
#' statistic over the `K (K - 1) / 2` contrasts and is inflated when
#' the posterior is diffuse. `compute_divergence()` reports the
#' posterior median and central 95% credible interval of `D_j`,
#' `pi_D = P(D_j > delta | Y)` (distinguishing) and
#' `pi_C = P(D_j < delta | Y) = 1 - pi_D` (consensus), and the
#' per-viewpoint departure `g_jk = f_jk - mean_{l != k} f_jl` with its
#' dominant viewpoint, sign, and `P(|g_jk| > delta | Y)`. The
#' probabilities are the reported quantities; no fixed probability
#' cutoff defines a distinguishing or consensus statement.
#'
#' @return `compute_threshold_prob()` and `compute_dominant_prob()`
#'   return `N x K` matrices. `compute_dominant_sign()` returns a
#'   length-`N` named vector. `compute_divergence()` returns a list
#'   (see Details). `classify_membership()` returns a data frame.
#'
#' @name bayesqm-membership
#' @aliases compute_threshold_prob compute_dominant_prob compute_dominant_sign compute_divergence classify_membership
#' @export
compute_threshold_prob <- function(Lambda_draws, threshold) {
  N <- dim(Lambda_draws)[2]
  K <- dim(Lambda_draws)[3]

  prob <- .summarize_draws(abs(Lambda_draws) > threshold, mean)

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
compute_dominant_sign <- function(Lambda_draws) {
  Td <- dim(Lambda_draws)[1]
  N  <- dim(Lambda_draws)[2]

  argmax <- apply(Lambda_draws, c(1, 2), function(v) which.max(abs(v)))

  pos <- numeric(N)
  for (i in seq_len(N))
    pos[i] <- mean(Lambda_draws[cbind(seq_len(Td), i, argmax[, i])] > 0)

  rn <- dimnames(Lambda_draws)[[2]]
  if (is.null(rn)) rn <- paste0("P", seq_len(N))
  names(pos) <- rn
  pos
}


#' @rdname bayesqm-membership
#' @export
compute_divergence <- function(F_draws, delta = NULL, delta_grid = NULL) {
  Td <- dim(F_draws)[1]
  J  <- dim(F_draws)[2]
  K  <- dim(F_draws)[3]
  if (K < 2) stop("compute_divergence requires K >= 2.")

  prs <- combn(K, 2)
  P   <- ncol(prs)
  Dmat <- Reduce(`+`, lapply(seq_len(P), function(c)
            abs(matrix(F_draws[, , prs[1, c]], Td, J) -
                matrix(F_draws[, , prs[2, c]], Td, J)))) / P

  D_med <- apply(Dmat, 2, stats::median)
  D_lo  <- apply(Dmat, 2, stats::quantile, 0.025, names = FALSE)
  D_hi  <- apply(Dmat, 2, stats::quantile, 0.975, names = FALSE)
  if (!is.null(delta) && (!is.numeric(delta) || length(delta) != 1L))
    stop("delta must be a single numeric value or NULL.")
  pi_D  <- if (is.null(delta)) rep(NA_real_, J) else colMeans(Dmat > delta)
  pi_C  <- 1 - pi_D

  G <- lapply(seq_len(K), function(k) {
    others <- setdiff(seq_len(K), k)
    matrix(F_draws[, , k], Td, J) -
      Reduce(`+`, lapply(others, function(l)
        matrix(F_draws[, , l], Td, J))) / length(others)
  })
  g_mean <- matrix(sapply(seq_len(K), function(k) colMeans(G[[k]])), J, K)
  p_g    <- if (is.null(delta)) matrix(NA_real_, J, K)
            else matrix(sapply(seq_len(K),
                               function(k) colMeans(abs(G[[k]]) > delta)), J, K)
  kstar  <- apply(abs(g_mean), 1, which.max)
  gsign  <- sign(g_mean[cbind(seq_len(J), kstar)])
  p_gstar <- p_g[cbind(seq_len(J), kstar)]

  sens <- NULL
  if (!is.null(delta_grid)) {
    sens <- sapply(delta_grid, function(dl) {
      pD <- colMeans(Dmat > dl)
      c(mean_pi_D = mean(pD), mean_pi_C = mean(1 - pD))
    })
    colnames(sens) <- sprintf("d=%.2f", delta_grid)
  }

  sn <- dimnames(F_draws)[[2]]
  if (is.null(sn)) sn <- paste0("S", seq_len(J))
  list(
    delta    = delta,
    D_median = setNames(D_med, sn),
    D_lower  = setNames(D_lo, sn),
    D_upper  = setNames(D_hi, sn),
    pi_D     = setNames(pi_D, sn),
    pi_C     = setNames(pi_C, sn),
    g_mean   = g_mean,
    p_g      = p_g,
    kstar    = setNames(kstar, sn),
    gsign    = setNames(gsign, sn),
    p_gstar  = setNames(p_gstar, sn),
    sensitivity = sens
  )
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


#' Suggested separation \code{delta} from the forced distribution
#'
#' @description
#' Returns the standardized-scale width of one forced-distribution
#' category, `1 / sd(forced positions)`. This is an alternative
#' separation to the package default, the reliability-adjusted critical
#' difference of [critical_delta()].
#'
#' @param distribution Integer vector of forced-distribution counts (the
#'   number of statements allowed in each grid column).
#'
#' @return A single numeric value: the standardized width of one
#'   forced-distribution category.
#'
#' @examples
#' suggest_delta(c(2, 3, 4, 6, 8, 6, 4, 3, 2))
#'
#' @export
suggest_delta <- function(distribution) {
  if (!is.numeric(distribution) || length(distribution) < 2L ||
      any(distribution < 0) || any(distribution != round(distribution)))
    stop("distribution must be a vector of non-negative integer counts.")
  n_pos <- length(distribution)
  if (n_pos %% 2 == 1) {
    half <- (n_pos - 1) / 2
    grid_vals <- seq(-half, half)
  } else {
    half <- n_pos / 2
    grid_vals <- c(seq(-half, -1), seq(1, half))
  }
  forced <- rep(grid_vals, times = distribution)
  1 / stats::sd(forced)
}


#' Reliability-adjusted critical difference (default \code{delta})
#'
#' @description
#' The default separation for the distinguishing and consensus
#' probabilities: the reliability-adjusted critical difference used to
#' flag distinguishing statements in classical Q analysis (Brown 1980;
#' Zabala & Pascual 2016), here generalized by computing it from the
#' posterior dominant-factor counts. With `p_f` the number of
#' participants whose posterior dominant factor is `f`,
#' `r_f = p_f r0 / (1 + (p_f - 1) r0)` and `SE_f = sqrt(1 - r_f)`,
#' `delta = z * mean_{k < l} sqrt(SE_k^2 + SE_l^2)`. The reliability is
#' the stable population reliability of the design, not the posterior
#' estimation spread.
#'
#' @param Lambda_draws Array of shape `[T, N, K]` of aligned loading
#'   draws.
#' @param level Two-sided level for the critical value, `z = qnorm(1 -
#'   level/2)`. `0.05` (default) gives `z = 1.96`; `0.01` gives
#'   `z = 2.58`. Report sensitivity over `level`.
#' @param r0 Conventional single-sort reliability (default `0.80`;
#'   Brown 1980).
#'
#' @return A single numeric value, the critical-difference `delta`.
#'
#' @examples
#' critical_delta(array(rnorm(200 * 8 * 3), c(200, 8, 3)))
#'
#' @export
critical_delta <- function(Lambda_draws, level = 0.05, r0 = 0.80) {
  prob <- compute_dominant_prob(Lambda_draws)
  K    <- ncol(prob)
  if (K < 2) stop("critical_delta requires K >= 2.")
  p   <- tabulate(apply(prob, 1, which.max), nbins = K)
  rel <- (p * r0) / (1 + (p - 1) * r0)
  se  <- sqrt(pmax(0, 1 - rel))
  prs <- combn(K, 2)
  z   <- stats::qnorm(1 - level / 2)
  z * mean(apply(prs, 2, function(c) sqrt(se[c[1]]^2 + se[c[2]]^2)))
}
