# zscores.R
# Bayesian posterior summary of statement factor z-scores: posterior mean
# and central credible interval, per factor. Returned as a wide data frame
# with one row per statement. Input draws should be MatchAlign-aligned.


#' Posterior summary of statement factor z-scores
#'
#' @description
#' Posterior mean and central credible-interval bounds for each
#' statement-factor z-score, returned as a tidy data frame with one row
#' per statement and three columns per factor.
#'
#' @param F_draws Array of shape `[T, J, K]` of MatchAlign-aligned
#'   factor-score draws (e.g. `fit$F_draws`).
#' @param prob Coverage probability for the credible interval.
#'
#' @return A data frame with columns `statement`, and three numeric
#'   columns per factor: `fk_zsc` (posterior mean), `fk_lower`, and
#'   `fk_upper`, for `k = 1..K`.
#'
#' @export
compute_zscores <- function(F_draws, prob = 0.95) {
  J <- dim(F_draws)[2]
  K <- dim(F_draws)[3]

  rn <- dimnames(F_draws)[[2]]
  if (is.null(rn)) rn <- paste0("S", seq_len(J))

  alpha <- 1 - prob
  qlo <- alpha / 2
  qhi <- 1 - qlo

  dm <- dim(F_draws)[2:3]
  mean_mat  <- apply(F_draws, c(2, 3), mean);  dim(mean_mat)  <- dm
  lower_mat <- apply(F_draws, c(2, 3),
                     function(v) quantile(v, probs = qlo, names = FALSE))
  dim(lower_mat) <- dm
  upper_mat <- apply(F_draws, c(2, 3),
                     function(v) quantile(v, probs = qhi, names = FALSE))
  dim(upper_mat) <- dm

  out <- data.frame(statement = rn, stringsAsFactors = FALSE)
  for (k in seq_len(K)) {
    fk <- paste0("f", k)
    out[[paste0(fk, "_zsc")]]   <- mean_mat[, k]
    out[[paste0(fk, "_lower")]] <- lower_mat[, k]
    out[[paste0(fk, "_upper")]] <- upper_mat[, k]
  }
  rownames(out) <- NULL
  out
}
