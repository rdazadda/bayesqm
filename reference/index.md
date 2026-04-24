# Package index

## Model fitting

The main entry points: fit a single Bayesian factor model, or fit across
a range of K under the peak-plus-Sivula protocol.

- [`fit_bayesian()`](https://rdazadda.github.io/bayesqm/reference/fit_bayesian.md)
  : Fit a Bayesian Q-methodology factor model
- [`run_bayes()`](https://rdazadda.github.io/bayesqm/reference/run_bayes.md)
  [`select_k_peak()`](https://rdazadda.github.io/bayesqm/reference/run_bayes.md)
  [`select_k_sivula()`](https://rdazadda.github.io/bayesqm/reference/run_bayes.md)
  : Fit the model across a range of K
- [`matchalign()`](https://rdazadda.github.io/bayesqm/reference/matchalign.md)
  : MatchAlign post-processing for Bayesian factor draws

## Posterior summaries

Tidy summaries of loadings, factor z-scores, and scalar hyperparameters.

- [`compute_loadings()`](https://rdazadda.github.io/bayesqm/reference/compute_loadings.md)
  : Posterior summary of participant factor loadings
- [`compute_zscores()`](https://rdazadda.github.io/bayesqm/reference/compute_zscores.md)
  : Posterior summary of statement factor z-scores
- [`compute_factor_array()`](https://rdazadda.github.io/bayesqm/reference/compute_factor_array.md)
  : Factor arrays on the forced Q-sort distribution
- [`compute_posterior_scalars()`](https://rdazadda.github.io/bayesqm/reference/compute_posterior_scalars.md)
  : Posterior summary of scalar hyperparameters

## Probabilistic factor membership

Posterior probabilities replacing the classical z-score tests and
Brown-threshold flags.

- [`compute_threshold_prob()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-membership.md)
  [`compute_dominant_prob()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-membership.md)
  [`compute_distinguishing_prob()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-membership.md)
  [`compute_consensus_prob()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-membership.md)
  [`classify_membership()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-membership.md)
  : Probabilistic factor-membership summaries

## Plots (base R)

Every view reads a quantity the fit already carries; no new dependencies
required.

- [`plot(`*`<bayesqm_fit>`*`)`](https://rdazadda.github.io/bayesqm/reference/plot.bayesqm_fit.md)
  : Factor-score dotchart for a bayesqm_fit
- [`plot_loading_posterior()`](https://rdazadda.github.io/bayesqm/reference/plot_loading_posterior.md)
  : Loading forest with 50 and 95 percent credible intervals
- [`plot_zscore_posterior()`](https://rdazadda.github.io/bayesqm/reference/plot_zscore_posterior.md)
  : Per-statement factor-score posterior across factors
- [`plot_membership()`](https://rdazadda.github.io/bayesqm/reference/plot_membership.md)
  : Dominant-factor posterior-probability heatmap
- [`plot_elpd()`](https://rdazadda.github.io/bayesqm/reference/plot_elpd.md)
  : ELPD across K with peak and Sivula markers
- [`plot_ppc()`](https://rdazadda.github.io/bayesqm/reference/plot_ppc.md)
  : Posterior predictive check on the correlation-matrix RMSE
- [`plot_tucker()`](https://rdazadda.github.io/bayesqm/reference/plot_tucker.md)
  : MatchAlign Tucker's phi distribution by factor
- [`plot_dist_cons()`](https://rdazadda.github.io/bayesqm/reference/plot_dist_cons.md)
  : Distinguishing-statement posterior-probability heatmap
- [`plot_hyper()`](https://rdazadda.github.io/bayesqm/reference/plot_hyper.md)
  : Hyperparameter posterior densities

## Paper figure renderers (ggplot2)

Direct ports of the three main-text figures in the accompanying paper:
the ELPD curve, the dominant-factor panel, and the PPC ridgeline. Also
reachable through
[`ggplot2::autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html).

- [`make_elpd_diff()`](https://rdazadda.github.io/bayesqm/reference/make_elpd_diff.md)
  : Delta-ELPD plot with Sivula band, peak, and adopted-K annotations
- [`make_dominant_panel()`](https://rdazadda.github.io/bayesqm/reference/make_dominant_panel.md)
  : Probabilistic dominant-factor panel
- [`make_ppc_ridge()`](https://rdazadda.github.io/bayesqm/reference/make_ppc_ridge.md)
  : Posterior predictive RMSE ridgeline across K
- [`autoplot(`*`<bayesqm_fit>`*`)`](https://rdazadda.github.io/bayesqm/reference/autoplot.bayesqm_fit.md)
  : ggplot2 renderings of a bayesqm_fit
- [`autoplot(`*`<bayesqm_run>`*`)`](https://rdazadda.github.io/bayesqm/reference/autoplot.bayesqm_run.md)
  : ggplot2 rendering of the ELPD curve for a bayesqm_run

## Theming and export

Palette control, figure export, and ready-to-paste captions.

- [`bayesqm_colors()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-colors.md)
  [`bayesqm_set_colors()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-colors.md)
  : Get or set the bayesqm colour scheme
- [`save_bayesqm_plot()`](https://rdazadda.github.io/bayesqm/reference/save_bayesqm_plot.md)
  : Save a bayesqm plot to file
- [`caption_bayesqm()`](https://rdazadda.github.io/bayesqm/reference/caption_bayesqm.md)
  : Dynamic figure caption for a bayesqm_fit
- [`rename_factors()`](https://rdazadda.github.io/bayesqm/reference/rename_factors.md)
  : Rename factors consistently across a bayesqm_fit

## Standard accessors for a bayesqm_fit

[`coef()`](https://rdrr.io/r/stats/coef.html),
[`fitted()`](https://rdrr.io/r/stats/fitted.values.html),
[`residuals()`](https://rdrr.io/r/stats/residuals.html), and the
rstantools generics.

- [`coef(`*`<bayesqm_fit>`*`)`](https://rdazadda.github.io/bayesqm/reference/bayesqm-fit-accessors.md)
  [`fitted(`*`<bayesqm_fit>`*`)`](https://rdazadda.github.io/bayesqm/reference/bayesqm-fit-accessors.md)
  [`residuals(`*`<bayesqm_fit>`*`)`](https://rdazadda.github.io/bayesqm/reference/bayesqm-fit-accessors.md)
  [`nobs(`*`<bayesqm_fit>`*`)`](https://rdazadda.github.io/bayesqm/reference/bayesqm-fit-accessors.md)
  [`sigma(`*`<bayesqm_fit>`*`)`](https://rdazadda.github.io/bayesqm/reference/bayesqm-fit-accessors.md)
  [`family(`*`<bayesqm_fit>`*`)`](https://rdazadda.github.io/bayesqm/reference/bayesqm-fit-accessors.md)
  [`print(`*`<bayesqm_family>`*`)`](https://rdazadda.github.io/bayesqm/reference/bayesqm-fit-accessors.md)
  [`as.matrix(`*`<bayesqm_fit>`*`)`](https://rdazadda.github.io/bayesqm/reference/bayesqm-fit-accessors.md)
  [`as.array(`*`<bayesqm_fit>`*`)`](https://rdazadda.github.io/bayesqm/reference/bayesqm-fit-accessors.md)
  [`as.data.frame(`*`<bayesqm_fit>`*`)`](https://rdazadda.github.io/bayesqm/reference/bayesqm-fit-accessors.md)
  [`update(`*`<bayesqm_fit>`*`)`](https://rdazadda.github.io/bayesqm/reference/bayesqm-fit-accessors.md)
  : Standard R accessors for bayesqm_fit
- [`print(`*`<bayesqm_fit>`*`)`](https://rdazadda.github.io/bayesqm/reference/bayesqm-fit-methods.md)
  [`summary(`*`<bayesqm_fit>`*`)`](https://rdazadda.github.io/bayesqm/reference/bayesqm-fit-methods.md)
  [`print(`*`<bayesqm_run>`*`)`](https://rdazadda.github.io/bayesqm/reference/bayesqm-fit-methods.md)
  [`summary(`*`<bayesqm_run>`*`)`](https://rdazadda.github.io/bayesqm/reference/bayesqm-fit-methods.md)
  : Print and summary methods for bayesqm_fit and bayesqm_run
- [`posterior_interval(`*`<bayesqm_fit>`*`)`](https://rdazadda.github.io/bayesqm/reference/posterior_interval.bayesqm_fit.md)
  : Credible intervals for bayesqm_fit parameters
- [`prior_summary(`*`<bayesqm_fit>`*`)`](https://rdazadda.github.io/bayesqm/reference/prior_summary.bayesqm_fit.md)
  [`print(`*`<bayesqm_prior>`*`)`](https://rdazadda.github.io/bayesqm/reference/prior_summary.bayesqm_fit.md)
  : Prior summary for a bayesqm_fit

## Data: import and construction

Readers for CSV/Excel/PQMethod/Ken-Q/KADE/HTMLQ and the `qsort_data`
object.

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

## Simulation helpers

Data-generating functions and assessment utilities used in the paper.

- [`demo_fit()`](https://rdazadda.github.io/bayesqm/reference/demo_fit.md)
  : A synthetic bayesqm_fit for examples and tutorials
- [`demo_run()`](https://rdazadda.github.io/bayesqm/reference/demo_run.md)
  : A synthetic bayesqm_run for examples and tutorials
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
