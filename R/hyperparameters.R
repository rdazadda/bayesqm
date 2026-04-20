# hyperparameters.R
# Posterior summary of scalar hyperparameters (typically nu, sigma, tau).
# Returns one row per parameter with mean, median, SD, and credible interval.
# Input is a named list of draw vectors -- for a fit_bayesian() result,
# pass fit$hyperparams directly.


#' Posterior summary of scalar hyperparameters
#'
#' @description
#' Returns a tidy data frame with one row per scalar parameter and
#' columns `mean`, `median`, `sd`, `lower`, `upper`.
#'
#' @param scalar_draws Named list of draw vectors. For a
#'   `bayesqm_fit`, pass `fit$hyperparams` directly.
#' @param prob Coverage probability for the credible interval.
#'
#' @return A data frame.
#'
#' @export
compute_posterior_scalars <- function(scalar_draws, prob = 0.95) {
  stopifnot(is.list(scalar_draws), !is.null(names(scalar_draws)))

  alpha <- 1 - prob
  qlo <- alpha / 2
  qhi <- 1 - qlo

  rows <- list()
  for (nm in names(scalar_draws)) {
    v <- scalar_draws[[nm]]
    v <- v[!is.na(v)]
    if (length(v) == 0) next
    rows[[nm]] <- data.frame(
      parameter = nm,
      mean   = mean(v),
      median = median(v),
      sd     = sd(v),
      lower  = quantile(v, probs = qlo, names = FALSE),
      upper  = quantile(v, probs = qhi, names = FALSE),
      stringsAsFactors = FALSE
    )
  }

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}
