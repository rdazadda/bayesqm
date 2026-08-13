# Package index

## Model fitting

Fit the exact partition-likelihood model, continue a gated chain, and
realign draws.

- [`fit_bayesian()`](https://rdazadda.github.io/bayesqm/reference/fit_bayesian.md)
  : Fit the exact partition-likelihood model to forced Q sorts
- [`extend()`](https://rdazadda.github.io/bayesqm/reference/extend.md) :
  Continue sampling a fitted chain
- [`matchalign()`](https://rdazadda.github.io/bayesqm/reference/matchalign.md)
  : MatchAlign post-processing for partition-model draws
- [`delta_grid()`](https://rdazadda.github.io/bayesqm/reference/delta_grid.md)
  : Grid width on the z scale

## The tables

The familiar Q outputs as posterior summaries, and the one
false-discovery rule behind every claim.

- [`compute_loadings()`](https://rdazadda.github.io/bayesqm/reference/compute_loadings.md)
  : Bounded participant loadings with credible intervals
- [`compute_flags()`](https://rdazadda.github.io/bayesqm/reference/compute_flags.md)
  : Flag probabilities with an explicit unclassified state
- [`compute_zscores()`](https://rdazadda.github.io/bayesqm/reference/compute_zscores.md)
  : Statement scores with credible intervals
- [`compute_factor_array()`](https://rdazadda.github.io/bayesqm/reference/compute_factor_array.md)
  : Quota-respecting factor arrays
- [`compute_qdc()`](https://rdazadda.github.io/bayesqm/reference/compute_qdc.md)
  : Distinguishing and consensus verdicts
- [`factor_characteristics()`](https://rdazadda.github.io/bayesqm/reference/factor_characteristics.md)
  : Factor characteristics
- [`crib_sheet()`](https://rdazadda.github.io/bayesqm/reference/crib_sheet.md)
  : Extreme-placement probabilities per statement and factor
- [`claims()`](https://rdazadda.github.io/bayesqm/reference/claims.md) :
  Selected claims at a common false-discovery level

## Model checking and choice of K

- [`check_fit()`](https://rdazadda.github.io/bayesqm/reference/check_fit.md)
  : Posterior-predictive checks of the fitted model
- [`check_persons()`](https://rdazadda.github.io/bayesqm/reference/check_persons.md)
  : The person check against mixed-replication bands
- [`fit_ladder()`](https://rdazadda.github.io/bayesqm/reference/fit_ladder.md)
  : Fit the model over a ladder of K
- [`select_k()`](https://rdazadda.github.io/bayesqm/reference/select_k.md)
  : Choose K by the two-signal rule
- [`loo_ladder()`](https://rdazadda.github.io/bayesqm/reference/loo_ladder.md)
  : PSIS-LOO across the ladder, as directional corroboration
- [`loglik_person()`](https://rdazadda.github.io/bayesqm/reference/loglik_person.md)
  : Person-level partition log-likelihoods

## Rotation and reporting

- [`rotate_factors()`](https://rdazadda.github.io/bayesqm/reference/rotate_factors.md)
  : Rotate every aligned draw toward a target
- [`flip_factor()`](https://rdazadda.github.io/bayesqm/reference/flip_factor.md)
  : Flip the pole of one factor
- [`rename_factors()`](https://rdazadda.github.io/bayesqm/reference/rename_factors.md)
  : Rename the factors

## Plots

Base-graphics views of the fit;
[`ggplot2::autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
serves the flagship four (loadings, flags, contrasts, array).

- [`plot_loading_posterior()`](https://rdazadda.github.io/bayesqm/reference/plot_loading_posterior.md)
  [`plot(`*`<bayesqm_fit>`*`)`](https://rdazadda.github.io/bayesqm/reference/plot_loading_posterior.md)
  : Bounded loadings with credible intervals
- [`plot_sorts()`](https://rdazadda.github.io/bayesqm/reference/plot_sorts.md)
  : Preview every participant's sort
- [`plot_zscores()`](https://rdazadda.github.io/bayesqm/reference/plot_zscores.md)
  : Statement scores across factors, whole panel
- [`plot_statement()`](https://rdazadda.github.io/bayesqm/reference/plot_statement.md)
  [`plot_zscore_posterior()`](https://rdazadda.github.io/bayesqm/reference/plot_statement.md)
  : One statement, in depth
- [`plot_membership()`](https://rdazadda.github.io/bayesqm/reference/plot_flags.md)
  [`plot_flags()`](https://rdazadda.github.io/bayesqm/reference/plot_flags.md)
  : Flag probabilities with the unclassified state
- [`plot_factor_array()`](https://rdazadda.github.io/bayesqm/reference/plot_factor_array.md)
  : The factor array on its grid
- [`plot_dist_cons()`](https://rdazadda.github.io/bayesqm/reference/plot_contrasts.md)
  [`plot_contrasts()`](https://rdazadda.github.io/bayesqm/reference/plot_contrasts.md)
  : Statement contrasts between two factors
- [`plot_choice_k()`](https://rdazadda.github.io/bayesqm/reference/plot_choice_k.md)
  : The two-signal choice-of-K display
- [`plot_person_check()`](https://rdazadda.github.io/bayesqm/reference/plot_person_check.md)
  : The person check against the mixed bands
- [`plot_tucker()`](https://rdazadda.github.io/bayesqm/reference/plot_convergence.md)
  [`plot_convergence()`](https://rdazadda.github.io/bayesqm/reference/plot_convergence.md)
  : Convergence and alignment view
- [`plot_ppc()`](https://rdazadda.github.io/bayesqm/reference/plot_ppc.md)
  : Posterior-predictive check display

## Theming and export

- [`bayesqm_colors()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-colors.md)
  [`bayesqm_set_colors()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-colors.md)
  : Get or set the bayesqm colour scheme
- [`save_bayesqm_plot()`](https://rdazadda.github.io/bayesqm/reference/save_bayesqm_plot.md)
  : Save a bayesqm plot to file
- [`caption_bayesqm()`](https://rdazadda.github.io/bayesqm/reference/caption_bayesqm.md)
  : Caption text for figures from a fit

## Standard accessors for a bayesqm_fit

- [`coef(`*`<bayesqm_fit>`*`)`](https://rdazadda.github.io/bayesqm/reference/coef.bayesqm_fit.md)
  : Posterior-mean bounded loadings
- [`fitted(`*`<bayesqm_fit>`*`)`](https://rdazadda.github.io/bayesqm/reference/fitted.bayesqm_fit.md)
  : Posterior-mean reconstruction on the utility scale
- [`sigma(`*`<bayesqm_fit>`*`)`](https://rdazadda.github.io/bayesqm/reference/sigma.bayesqm_fit.md)
  : Posterior-mean loading scales
- [`posterior_interval()`](https://rdazadda.github.io/bayesqm/reference/posterior_interval.md)
  : Posterior interval generic
- [`posterior_interval(`*`<bayesqm_fit>`*`)`](https://rdazadda.github.io/bayesqm/reference/posterior_interval.bayesqm_fit.md)
  : Credible intervals for bayesqm_fit parameters
- [`prior_summary()`](https://rdazadda.github.io/bayesqm/reference/prior_summary.md)
  : Prior summary generic
- [`prior_summary(`*`<bayesqm_fit>`*`)`](https://rdazadda.github.io/bayesqm/reference/prior_summary.bayesqm_fit.md)
  : Prior summary for a bayesqm_fit

## Data: import and construction

Readers for CSV/Excel/PQMethod/Ken-Q/KADE/HTMLQ, the `qsort_data`
object, and the shipped example panel.

- [`read_qsort()`](https://rdazadda.github.io/bayesqm/reference/read_qsort.md)
  [`read_qsort_csv()`](https://rdazadda.github.io/bayesqm/reference/read_qsort.md)
  [`read_qsort_excel()`](https://rdazadda.github.io/bayesqm/reference/read_qsort.md)
  [`read_pqmethod()`](https://rdazadda.github.io/bayesqm/reference/read_qsort.md)
  [`read_kenq()`](https://rdazadda.github.io/bayesqm/reference/read_qsort.md)
  [`read_kenq_excel()`](https://rdazadda.github.io/bayesqm/reference/read_qsort.md)
  [`read_kade_zip()`](https://rdazadda.github.io/bayesqm/reference/read_qsort.md)
  [`read_easyhtml_firebase()`](https://rdazadda.github.io/bayesqm/reference/read_qsort.md)
  [`read_statements()`](https://rdazadda.github.io/bayesqm/reference/read_qsort.md)
  : Read Q-sort data from file
- [`import.pqmethod()`](https://rdazadda.github.io/bayesqm/reference/import-aliases.md)
  [`import.htmlq()`](https://rdazadda.github.io/bayesqm/reference/import-aliases.md)
  [`import.kenq()`](https://rdazadda.github.io/bayesqm/reference/import-aliases.md)
  [`import.easyhtmlq()`](https://rdazadda.github.io/bayesqm/reference/import-aliases.md)
  : qmethod-style import aliases
- [`qsort_data()`](https://rdazadda.github.io/bayesqm/reference/qsort_data.md)
  [`validate_qsort()`](https://rdazadda.github.io/bayesqm/reference/qsort_data.md)
  [`check_distribution()`](https://rdazadda.github.io/bayesqm/reference/qsort_data.md)
  [`infer_distribution()`](https://rdazadda.github.io/bayesqm/reference/qsort_data.md)
  [`parse_distribution()`](https://rdazadda.github.io/bayesqm/reference/qsort_data.md)
  : Construct a validated qsort_data object
- [`print(`*`<qsort_data>`*`)`](https://rdazadda.github.io/bayesqm/reference/qsort_data-methods.md)
  [`summary(`*`<qsort_data>`*`)`](https://rdazadda.github.io/bayesqm/reference/qsort_data-methods.md)
  [`as.matrix(`*`<qsort_data>`*`)`](https://rdazadda.github.io/bayesqm/reference/qsort_data-methods.md)
  : Print, summary, and matrix conversion for qsort_data
- [`obesity_sorts`](https://rdazadda.github.io/bayesqm/reference/obesity_sorts.md)
  : Childhood obesity Q sorts
- [`marijuana_sorts`](https://rdazadda.github.io/bayesqm/reference/marijuana_sorts.md)
  : Marijuana legalization Q sorts

## Demonstration and synthetic panels

A fast demonstration fit, synthetic panels with known truth, and
recovery measures for method checks.

- [`demo_fit()`](https://rdazadda.github.io/bayesqm/reference/demo_fit.md)
  : A small demonstration fit
- [`generate_data()`](https://rdazadda.github.io/bayesqm/reference/generate_data.md)
  [`generate_loadings()`](https://rdazadda.github.io/bayesqm/reference/generate_data.md)
  [`generate_noise()`](https://rdazadda.github.io/bayesqm/reference/generate_data.md)
  [`discretize_to_grid()`](https://rdazadda.github.io/bayesqm/reference/generate_data.md)
  [`get_distribution()`](https://rdazadda.github.io/bayesqm/reference/generate_data.md)
  : Simulate Q-sort data
- [`assess_recovery()`](https://rdazadda.github.io/bayesqm/reference/assess_recovery.md)
  [`assess_classification()`](https://rdazadda.github.io/bayesqm/reference/assess_recovery.md)
  : Simulation-study assessment helpers
- [`tucker_congruence()`](https://rdazadda.github.io/bayesqm/reference/tucker_congruence.md)
  [`procrustes_rotation()`](https://rdazadda.github.io/bayesqm/reference/tucker_congruence.md)
  : Tucker's congruence and orthogonal Procrustes rotation

## Defunct

- [`run_bayes()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md)
  [`plot_hyper()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md)
  [`select_k_peak()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md)
  [`select_k_sivula()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md)
  [`compute_dominant_prob()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md)
  [`compute_dominant_sign()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md)
  [`compute_threshold_prob()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md)
  [`classify_membership()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md)
  [`compute_divergence()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md)
  [`critical_delta()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md)
  [`suggest_delta()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md)
  [`compute_posterior_scalars()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md)
  [`demo_run()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md)
  [`plot_elpd()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md)
  [`make_elpd_diff()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md)
  [`make_ppc_ridge()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md)
  [`make_dominant_panel()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md)
  : Defunct 0.1.0 functions
