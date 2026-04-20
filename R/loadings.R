# loadings.R
# Bayesian posterior summary of participant factor loadings: posterior mean
# and central credible interval, per factor. Returned as a wide data frame
# with one row per participant. Input draws should be MatchAlign-aligned.


#' Posterior summary of participant factor loadings
#'
#' @description
#' Posterior mean and central credible-interval bounds for each
#' participant-factor loading, returned as a tidy data frame with one
#' row per participant and three columns per factor.
#'
#' @param Lambda_draws Array of shape `[T, N, K]` of MatchAlign-aligned
#'   loading draws (e.g. `fit$Lambda_draws`).
#' @param prob Coverage probability for the credible interval
#'   (default 0.95).
#'
#' @return A data frame with columns `participant`, and three numeric
#'   columns per factor: `fk_loa` (posterior mean), `fk_lower`, and
#'   `fk_upper`, for `k = 1..K`.
#'
#' @export
compute_loadings <- function(Lambda_draws, prob = 0.95) {
  N <- dim(Lambda_draws)[2]
  K <- dim(Lambda_draws)[3]

  rn <- dimnames(Lambda_draws)[[2]]
  if (is.null(rn)) rn <- paste0("P", seq_len(N))

  alpha <- 1 - prob
  qlo <- alpha / 2
  qhi <- 1 - qlo

  dm <- dim(Lambda_draws)[2:3]
  mean_mat  <- apply(Lambda_draws, c(2, 3), mean);  dim(mean_mat)  <- dm
  lower_mat <- apply(Lambda_draws, c(2, 3),
                     function(v) quantile(v, probs = qlo, names = FALSE))
  dim(lower_mat) <- dm
  upper_mat <- apply(Lambda_draws, c(2, 3),
                     function(v) quantile(v, probs = qhi, names = FALSE))
  dim(upper_mat) <- dm

  out <- data.frame(participant = rn, stringsAsFactors = FALSE)
  for (k in seq_len(K)) {
    fk <- paste0("f", k)
    out[[paste0(fk, "_loa")]]   <- mean_mat[, k]
    out[[paste0(fk, "_lower")]] <- lower_mat[, k]
    out[[paste0(fk, "_upper")]] <- upper_mat[, k]
  }
  rownames(out) <- NULL
  out
}
