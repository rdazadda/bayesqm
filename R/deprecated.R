# deprecated.R
# Defunct 0.1.0 entry points. Every function here computed a quantity of
# the removed score-scale model that has no honest counterpart under the
# partition likelihood, so each errors with a pointer instead of silently
# returning different numbers under an old name. Scheduled for deletion at
# 0.3.0.

#' @keywords internal
#' @noRd
.defunct_020 <- function(what, instead) {
  .bq_abort(paste0(
    "%s was removed with the 0.1.0 score-scale model; the partition ",
    "likelihood of bayesqm 0.2.0 computes its answer differently. %s."),
    what, instead, call = sys.call(-2L))
}

#' Defunct 0.1.0 functions
#'
#' @description
#' These 0.1.0 entry points belonged to the removed Student-t score-scale
#' model and now signal an error naming their 0.2.0 replacement:
#' flag probabilities and signs come from `compute_flags()`,
#' distinguishing/consensus verdicts from `compute_qdc()`, the critical
#' difference from the posterior itself, factor enumeration from
#' `fit_ladder()` and `select_k()`, and scalar summaries from
#' `as_draws_df()`.
#'
#' @param ... Ignored.
#' @return Always signals an error.
#' @name bayesqm-defunct
#' @keywords internal
NULL

#' @rdname bayesqm-defunct
#' @export
run_bayes <- function(...)
  .defunct_020("run_bayes()", "Use fit_ladder() and select_k()")

#' @rdname bayesqm-defunct
#' @export
plot_hyper <- function(...)
  .defunct_020("plot_hyper()",
               "Factor scale summaries live in factor_characteristics()")

#' @rdname bayesqm-defunct
#' @export
select_k_peak <- function(...)
  .defunct_020("select_k_peak()",
               "The two-signal workflow in select_k() replaces ELPD-peak selection")

#' @rdname bayesqm-defunct
#' @export
select_k_sivula <- function(...)
  .defunct_020("select_k_sivula()",
               "The two-signal workflow in select_k() replaces ELPD-based selection; loo_ladder() keeps PSIS-LOO as directional corroboration")

#' @rdname bayesqm-defunct
#' @export
compute_dominant_prob <- function(...)
  .defunct_020("compute_dominant_prob()",
               "Flag probabilities with an explicit unclassified state come from compute_flags()")

#' @rdname bayesqm-defunct
#' @export
compute_dominant_sign <- function(...)
  .defunct_020("compute_dominant_sign()", "compute_flags() reports flag signs")

#' @rdname bayesqm-defunct
#' @export
compute_threshold_prob <- function(...)
  .defunct_020("compute_threshold_prob()",
               "compute_flags() applies the exceedance condition inside the flag rule")

#' @rdname bayesqm-defunct
#' @export
classify_membership <- function(...)
  .defunct_020("classify_membership()",
               "compute_flags() reports flag probabilities and the unclassified state")

#' @rdname bayesqm-defunct
#' @export
compute_divergence <- function(...)
  .defunct_020("compute_divergence()",
               "compute_qdc() gives distinguishing, consensus, and indeterminate verdicts")

#' @rdname bayesqm-defunct
#' @export
critical_delta <- function(...)
  .defunct_020("critical_delta()",
               "compute_qdc() computes the critical difference from the posterior contrast spread")

#' @rdname bayesqm-defunct
#' @export
suggest_delta <- function(...)
  .defunct_020("suggest_delta()",
               "delta_grid() is the grid-width equivalence region (population-sd definition; values differ slightly from 0.1.0)")

#' @rdname bayesqm-defunct
#' @export
compute_posterior_scalars <- function(...)
  .defunct_020("compute_posterior_scalars()",
               "Use as_draws_df() with posterior::summarise_draws()")

#' @rdname bayesqm-defunct
#' @export
demo_run <- function(...)
  .defunct_020("demo_run()", "Use demo_fit(); a ladder demo returns with fit_ladder()")

#' @rdname bayesqm-defunct
#' @export
plot_elpd <- function(...)
  .defunct_020("plot_elpd()",
               "PSIS-LOO is directional corroboration only; loo_ladder() prints the table, and plot_choice_k() shows the two-signal decision")

#' @rdname bayesqm-defunct
#' @export
make_elpd_diff <- function(...)
  .defunct_020("make_elpd_diff()",
               "PSIS-LOO is directional corroboration only; see loo_ladder() and plot_choice_k()")

#' @rdname bayesqm-defunct
#' @export
make_ppc_ridge <- function(...)
  .defunct_020("make_ppc_ridge()",
               "Per-rung posterior-predictive evidence lives in select_k() and plot_choice_k(); plot_ppc() shows a single fit's checks")

#' @rdname bayesqm-defunct
#' @export
make_dominant_panel <- function(...)
  .defunct_020("make_dominant_panel()",
               "plot_flags() shows the flag probabilities with the unclassified state")
