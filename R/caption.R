# caption.R
# A single-function helper that returns a ready-to-paste figure caption
# drawn from whatever the fit already knows about itself. Reviewers
# always ask for N, K, chains, and convergence diagnostics; rather than
# have every user reconstruct that sentence each time, fetch it from
# $brief and $diagnostics.


#' Dynamic figure caption for a bayesqm_fit
#'
#' @description
#' Returns a human-readable caption string summarising the model
#' configuration (`K`, `N`, `J`, family), the sampler (backend, chains,
#' post-warmup draws), the interval probability, and convergence
#' diagnostics (max Rhat, divergent transitions). Optionally appends a
#' citation to the accompanying Psychometrika paper.
#'
#' @param fit A `bayesqm_fit`.
#' @param include_ref Logical; append the paper citation.
#' @param include_diag Logical; append the convergence-diagnostic line.
#'
#' @return A length-1 character string.
#'
#' @examples
#' \dontrun{
#' cat(caption_bayesqm(fit))
#' }
#'
#' @export
caption_bayesqm <- function(fit, include_ref = TRUE, include_diag = TRUE) {
  stopifnot(inherits(fit, "bayesqm_fit"))
  b <- fit$brief
  d <- if (is.null(fit$diagnostics)) list() else fit$diagnostics

  parts <- c(
    sprintf("Bayesian Q-methodology factor model (K = %d, N = %d, J = %d)",
            b$K, b$N, b$J),
    sprintf("fitted with a %s likelihood via %s (%d chain%s, %s post-warmup draws)",
            b$family, b$backend, b$chains,
            if (b$chains == 1L) "" else "s",
            format(b$post_warmup, big.mark = ",", scientific = FALSE)),
    sprintf("intervals shown at %d%% posterior coverage",
            round(100 * b$prob))
  )

  if (isTRUE(include_diag)) {
    rhat_s <- if (is.null(d$rhat_max) || !is.finite(d$rhat_max))
      "NA" else sprintf("%.3f", d$rhat_max)
    ess_s  <- if (is.null(d$ess_bulk) || !is.finite(d$ess_bulk))
      "NA" else format(round(d$ess_bulk), big.mark = ",")
    div_s  <- if (is.null(d$divergences) || !is.finite(d$divergences))
      "NA" else as.character(d$divergences)
    parts <- c(parts,
               sprintf("max Rhat = %s, min bulk ESS = %s, %s divergent transition%s",
                       rhat_s, ess_s, div_s,
                       if (identical(div_s, "1")) "" else "s"))
  }

  out <- paste0(paste(parts, collapse = "; "), ".")

  if (isTRUE(include_ref))
    out <- paste(out,
                 "Fitted with the bayesqm R package (Dacosta Azadda, 2026).")

  out
}
