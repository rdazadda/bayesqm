#' @keywords internal
#' @aliases bayesqm-package
"_PACKAGE"

#' bayesqm: Bayesian Q-Methodology Factor Analysis
#'
#' @description
#' A Bayesian factor-analytic framework for Q methodology. Fits a low-rank
#' factor model to Q-sort data with a Student-t likelihood and a hierarchical
#' normal prior on loadings, samples the posterior with Stan, resolves
#' rotational ambiguity via MatchAlign post-processing, and returns
#' posterior summaries including credible intervals for loadings and factor
#' scores, probabilistic dominant-factor membership, distinguishing and
#' consensus statements, and PSIS-LOO-based factor enumeration.
#'
#' @details
#' The typical workflow is:
#'
#' \enumerate{
#'   \item **Import data.** [read_qsort()] auto-detects CSV, Excel,
#'     PQMethod `.DAT`, Ken-Q JSON / multi-sheet Excel, KADE ZIP, or
#'     Easy-HTMLQ Firebase JSON. [qsort_data()] constructs the object
#'     directly from a matrix.
#'   \item **Fit the model.** [fit_bayesian()] returns a `bayesqm_fit`
#'     object. [run_bayes()] fits the model for a range of K and returns
#'     a `bayesqm_run` object carrying the ELPD comparison table and the
#'     peak-plus-Sivula protocol verdict.
#'   \item **Summarise the posterior.** [compute_loadings()],
#'     [compute_zscores()], [compute_factor_array()],
#'     [compute_dominant_prob()], [compute_threshold_prob()],
#'     [compute_divergence()], [classify_membership()], and
#'     [compute_posterior_scalars()].
#'   \item **Use standard R accessors.** `coef()`, `fitted()`,
#'     `residuals()`, `sigma()`, `family()`, `nobs()`, `as.matrix()`,
#'     `as.array()`, `as.data.frame()`, `update()`, plus
#'     [rstantools::posterior_interval()] and
#'     [rstantools::prior_summary()] work directly on the fit.
#' }
#'
#' Draws extraction works with the `posterior` package (`as_draws_df()`,
#' `as_draws_matrix()`, `as_draws_array()`), which in turn makes the fit
#' usable with `bayesplot` and `tidybayes` through their standard
#' conventions.
#'
#' @section Relationship to the qmethod package:
#' The `bayesqm_fit` object parallels `qmethod::qmethod` output where that
#' is meaningful, so scripts written against `qmethod` largely keep
#' working:
#'
#' - Slot names match: `$dataset`, `$loa`, `$zsc`, `$zsc_n`, `$f_char`,
#'   `$qdc`, `$flagged`.
#' - The `$qdc$dist.and.cons` vocabulary matches exactly
#'   (`"Distinguishes all"`, `"Consensus"`, `"Distinguishes f1, f3"`,
#'   `""`).
#' - Dotted reader aliases ([import.pqmethod()], [import.htmlq()],
#'   [import.kenq()], [import.easyhtmlq()]) forward to the `read_*`
#'   readers.
#'
#' Intentional Bayesian divergences:
#'
#' - `$f_char$characteristics` omits the classical test-theory columns
#'   (`av_rel_coef`, `reliability`, `se_fscores`, `sd_dif`). Factor-score
#'   uncertainty is already quantified by the posterior credible
#'   intervals in `$ci_lower` and `$ci_upper`, so Spearman-Brown
#'   composite reliability is not the right construct.
#' - `$flagged` is a logical `N x K` matrix defined as
#'   `P(argmax_k |Lambda[i, k]| = k) > 0.5` rather than Brown's (1980)
#'   significance-based rule. The posterior probability makes the
#'   Bayesian analogue direct.
#' - `$brief` uses `K`, `N`, `J` (not `nfactors`, `nqsort`, `nstat`) and
#'   includes Bayesian-specific fields (`family`, `prob`, `priors`,
#'   `backend`).
#'
#' @references
#' Poworoznek, E., Anceschi, N., Ferrari, F., & Dunson, D. (2025). Efficiently
#'   Resolving Rotational Ambiguity in Bayesian Matrix Sampling with
#'   Matching. *Bayesian Analysis*.
#'
#' Sivula, T., Magnusson, M., Matamoros, A. A., & Vehtari, A. (2025).
#'   Uncertainty in Bayesian Leave-One-Out Cross-Validation Based Model
#'   Comparison. *Bayesian Analysis*.
#'
#' Vehtari, A., Gelman, A., & Gabry, J. (2017). Practical Bayesian model
#'   evaluation using leave-one-out cross-validation and WAIC. *Statistics
#'   and Computing*, 27(5), 1413-1432.
#'
#' @name bayesqm-package
NULL
