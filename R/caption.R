# caption.R
# One-line figure caption carrying the fit's provenance.


#' Caption text for figures from a fit
#'
#' @description
#' A single string naming the model, the panel, the draws, and the gate
#' verdict — the provenance a figure caption should carry.
#'
#' @param fit A `bayesqm_fit`.
#' @param include_gate Append the gate report (default `TRUE`).
#'
#' @return A length-one character string.
#'
#' @examples
#' caption_bayesqm(demo_fit())
#'
#' @export
caption_bayesqm <- function(fit, include_gate = TRUE) {
  assert_bayesqm_fit(fit)
  b <- fit$brief; g <- fit$gate
  out <- sprintf(
    "Exact partition (rank-order) likelihood; N = %d, J = %d, K = %d; %d posterior draws.",
    b$N, b$J, b$K, dim(fit$draws$F)[1])
  if (include_gate)
    out <- paste(out, sprintf(
      "Convergence gate %s (max Rhat %.3f, min ESS %.0f).",
      if (g$converged) "passed" else "not met", g$rhat,
      min(g$ess_bulk, g$ess_tail)))
  out
}


# one-release aliases for the 0.1.0 plot names whose concept survived

#' @rdname plot_flags
#' @param ... Passed on.
#' @export
plot_membership <- function(...) {
  .Deprecated("plot_flags", package = "bayesqm")
  plot_flags(...)
}

#' @rdname plot_contrasts
#' @param ... Passed on.
#' @export
plot_dist_cons <- function(...) {
  .Deprecated("plot_contrasts", package = "bayesqm")
  plot_contrasts(...)
}

#' @rdname plot_convergence
#' @param ... Passed on.
#' @export
plot_tucker <- function(...) {
  .Deprecated("plot_convergence", package = "bayesqm")
  plot_convergence(...)
}
