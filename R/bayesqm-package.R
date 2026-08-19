#' @keywords internal
#' @aliases bayesqm-package
"_PACKAGE"

#' bayesqm: Bayesian Q Methodology
#'
#' @description
#' A Bayesian analysis for Q methodology, alongside the classical one. The
#' forced Q sort is modeled as an ordered partition of the statements
#' through an exact rank-order likelihood: the design quotas fix the
#' partition margins, so the probability of the observed sorting event is
#' the full observed-data likelihood. The posterior is sampled by a
#' parameter-expanded Gibbs sampler in R with no compiled code, gated on rotation-invariant
#' convergence diagnostics, aligned by MatchAlign, and returned as the
#' familiar Q tables with uncertainty attached.
#'
#' @details
#' The typical workflow:
#'
#' \enumerate{
#'   \item **Import data.** [read_qsort()] auto-detects CSV, Excel,
#'     PQMethod `.DAT`, Ken-Q JSON / multi-sheet Excel, KADE ZIP, or
#'     Easy-HTMLQ Firebase JSON. [qsort_data()] constructs the object
#'     directly from a matrix. The exact likelihood needs forced sorts:
#'     every participant must match the design grid.
#'   \item **Fit.** [fit_bayesian()] returns a `bayesqm_fit`; [extend()]
#'     warm-continues a chain the convergence gate flagged.
#'   \item **Read the tables.** [compute_loadings()] (bounded loadings
#'     with credible intervals), [compute_flags()] (flag probabilities
#'     with an unclassified state), [compute_zscores()],
#'     [compute_factor_array()] (quota-exact arrays),
#'     [compute_qdc()] (distinguishing / consensus / indeterminate),
#'     [crib_sheet()], and [claims()] — one posterior false-discovery
#'     rule selecting every claim.
#'   \item **Check the model.** [check_fit()] (agreement, extra-factor,
#'     and paired-comparison checks) and [check_persons()] (the person check,
#'     against mixed-replication bands).
#'   \item **Choose K.** [fit_ladder()] and [select_k()] run the
#'     two-signal workflow; [loo_ladder()] adds directional
#'     corroboration.
#'   \item **Report.** The `plot_*` views, [rotate_factors()] for
#'     judgmental rotation, [rename_factors()], and the standard R
#'     accessors (`coef()`, `fitted()`, `as_draws_df()`,
#'     [posterior_interval()], [prior_summary()]).
#' }
#'
#' @section Relationship to classical Q analysis:
#' The questions and the reporting conventions are Q's own; what the
#' Bayesian account adds is a probability behind each familiar verdict.
#' Vocabulary carries over: flags, factor arrays, defining sorts,
#' distinguishing and consensus statements. Two deliberate differences in
#' the tables:
#'
#' - Factor characteristics do not print eigenvalues or explained
#'   variance, which have no counterpart in a generative model; report
#'   the defining-sort counts from [claims()] and the extra-factor check
#'   of [check_fit()] in their place.
#' - Consensus is a positive finding (an equivalence region of one grid
#'   column, [delta_grid()]), not the complement of distinguishing, so a
#'   statement can be distinguishing, consensus, or neither.
#'
#' @references
#' Poworoznek, E., Anceschi, N., Ferrari, F., & Dunson, D. (2025).
#'   Efficiently Resolving Rotational Ambiguity in Bayesian Matrix
#'   Sampling with Matching. *Bayesian Analysis*.
#'
#' Vehtari, A., Gelman, A., Simpson, D., Carpenter, B., & Bürkner, P.-C.
#'   (2021). Rank-Normalization, Folding, and Localization: An Improved
#'   R-hat for Assessing Convergence of MCMC. *Bayesian Analysis*, 16(2),
#'   667-718.
#'
#' @name bayesqm-package
NULL
