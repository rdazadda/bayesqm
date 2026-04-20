# factor_array.R
# Bayesian factor arrays: posterior-mean factor z-scores ranked onto the
# study's forced Q-sort distribution. For the continuous z-scores and their
# credible intervals, see compute_zscores().


#' Factor arrays on the forced Q-sort distribution
#'
#' @description
#' Posterior-mean factor z-scores ranked onto the study's forced
#' distribution. The result is a tidy data frame with one row per
#' statement and per-factor integer grid scores. For the continuous
#' z-scores with credible intervals, use [compute_zscores()].
#'
#' @param F_draws Array of shape `[T, J, K]` of factor-score draws.
#' @param Y The Q-sort matrix whose first column supplies the forced
#'   distribution (as in the original study's grid).
#'
#' @return A data frame with columns `statement` and `f1_grid,
#'   f2_grid, ..., fK_grid`.
#'
#' @export
compute_factor_array <- function(F_draws, Y) {
  J <- dim(F_draws)[2]
  K <- dim(F_draws)[3]

  sn <- dimnames(F_draws)[[2]]
  if (is.null(sn)) sn <- paste0("S", seq_len(J))

  F_hat <- apply(F_draws, c(2, 3), mean)
  dim(F_hat) <- dim(F_draws)[2:3]

  # Recover the study's forced distribution from the observed data. Assumes
  # every participant used the same grid (true for forced Q-sort designs).
  grid_vals <- sort(unique(Y[, 1]))
  counts <- tabulate(match(Y[, 1], grid_vals), nbins = length(grid_vals))
  forced_dist <- rep(grid_vals, times = counts)

  out <- data.frame(statement = sn, stringsAsFactors = FALSE)
  for (k in seq_len(K)) {
    rnk <- rank(F_hat[, k], ties.method = "first")
    out[[paste0("f", k, "_grid")]] <- forced_dist[rnk]
  }
  rownames(out) <- NULL
  out
}
