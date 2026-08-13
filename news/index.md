# Changelog

## bayesqm 0.2.0

The model changed. 0.1.0 scored the grid positions and fit a Student-t
factor model through Stan. 0.2.0 models the forced Q sort as an ordered
partition of the statements, computes the probability of the observed
sorting event exactly, and fits it with a Gibbs sampler written in R.
Stan is no longer used. Scripts written against 0.1.0 need the changes
below.

### Changes from 0.1.0

- [`fit_bayesian()`](https://rdazadda.github.io/bayesqm/reference/fit_bayesian.md)
  fits the new model. The Stan-era arguments give migration errors that
  name their replacements.
- Functions keeping their names now return the new model’s quantities.
  [`compute_loadings()`](https://rdazadda.github.io/bayesqm/reference/compute_loadings.md)
  gives bounded loadings with credible intervals,
  [`compute_zscores()`](https://rdazadda.github.io/bayesqm/reference/compute_zscores.md)
  scores with intervals from the aligned draws,
  [`compute_factor_array()`](https://rdazadda.github.io/bayesqm/reference/compute_factor_array.md)
  a quota-exact array built from posterior column probabilities, and
  [`matchalign()`](https://rdazadda.github.io/bayesqm/reference/matchalign.md)
  takes and returns a whole fit.
- Removed with the score-scale model, each erroring with a pointer to
  its successor:
  [`run_bayes()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md),
  [`select_k_peak()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md),
  [`select_k_sivula()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md),
  [`compute_dominant_prob()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md),
  [`compute_dominant_sign()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md),
  [`compute_threshold_prob()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md),
  [`classify_membership()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md),
  [`compute_divergence()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md),
  [`critical_delta()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md),
  [`compute_posterior_scalars()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md),
  [`demo_run()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md),
  and
  [`plot_hyper()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md).
  [`suggest_delta()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-defunct.md)
  is replaced by
  [`delta_grid()`](https://rdazadda.github.io/bayesqm/reference/delta_grid.md),
  and [`residuals()`](https://rdrr.io/r/stats/residuals.html) on a fit
  errors because a rank likelihood has no residual scale.
- The fit object was rebuilt. The 0.1.0 slots are gone, and every table
  now comes from its own function.

### New

- One rule behind every claim.
  [`claims()`](https://rdazadda.github.io/bayesqm/reference/claims.md)
  selects the reported flags, distinguishing statements, consensus
  statements, and pairwise stars at a posterior false-discovery level
  and gives the expected number of false claims.
- A two-part choice of the number of factors.
  [`fit_ladder()`](https://rdazadda.github.io/bayesqm/reference/fit_ladder.md)
  fits the candidate models and
  [`select_k()`](https://rdazadda.github.io/bayesqm/reference/select_k.md)
  checks each for adequacy and for per-factor support, refusing to
  select when no K passes both.
  [`loo_ladder()`](https://rdazadda.github.io/bayesqm/reference/loo_ladder.md)
  adds PSIS-LOO as directional corroboration.
- Model checks.
  [`check_fit()`](https://rdazadda.github.io/bayesqm/reference/check_fit.md)
  runs the posterior-predictive checks and
  [`check_persons()`](https://rdazadda.github.io/bayesqm/reference/check_persons.md)
  separates sorts the model spans from shared viewpoints it does not.
  Every fit passes a convergence check before it returns, and
  [`extend()`](https://rdazadda.github.io/bayesqm/reference/extend.md)
  continues a chain draw for draw.
- The tables.
  [`compute_flags()`](https://rdazadda.github.io/bayesqm/reference/compute_flags.md)
  reports flag probabilities with an explicit unclassified state,
  [`compute_qdc()`](https://rdazadda.github.io/bayesqm/reference/compute_qdc.md)
  judges statements against a posterior critical difference and the
  one-grid-column consensus region with two-level stars, and
  [`factor_characteristics()`](https://rdazadda.github.io/bayesqm/reference/factor_characteristics.md)
  gives the per-factor summary block.
- Alignment ends in a stabilized orientation, so the delivered rotation
  does not inherit one draw’s sampling noise.
- Two real panels ship with the package, both from Akhtar-Danesh (2023).
  `obesity_sorts` is the childhood obesity panel, 33 participants
  sorting 42 statements on a nine-column grid, and `marijuana_sorts` the
  marijuana legalization panel, 40 participants sorting 19 statements on
  a seven-column grid.
- Plots rebuilt in one style, from
  [`plot_sorts()`](https://rdazadda.github.io/bayesqm/reference/plot_sorts.md),
  which previews every participant’s completed sort before any model
  runs, to
  [`plot_choice_k()`](https://rdazadda.github.io/bayesqm/reference/plot_choice_k.md),
  which draws the whole choice-of-K decision with its verdict written on
  the rows.
  [`plot_zscores()`](https://rdazadda.github.io/bayesqm/reference/plot_zscores.md),
  [`plot_statement()`](https://rdazadda.github.io/bayesqm/reference/plot_statement.md),
  [`plot_factor_array()`](https://rdazadda.github.io/bayesqm/reference/plot_factor_array.md),
  [`plot_contrasts()`](https://rdazadda.github.io/bayesqm/reference/plot_contrasts.md),
  [`plot_flags()`](https://rdazadda.github.io/bayesqm/reference/plot_flags.md),
  [`plot_loading_posterior()`](https://rdazadda.github.io/bayesqm/reference/plot_loading_posterior.md),
  [`plot_person_check()`](https://rdazadda.github.io/bayesqm/reference/plot_person_check.md),
  [`plot_convergence()`](https://rdazadda.github.io/bayesqm/reference/plot_convergence.md),
  and
  [`plot_ppc()`](https://rdazadda.github.io/bayesqm/reference/plot_ppc.md)
  cover the remaining views, with
  [`ggplot2::autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  methods for loadings, flags, contrasts, and the array.
- [`rotate_factors()`](https://rdazadda.github.io/bayesqm/reference/rotate_factors.md)
  applies judgmental rotation to every draw,
  [`flip_factor()`](https://rdazadda.github.io/bayesqm/reference/flip_factor.md)
  reverses a pole, and
  [`rename_factors()`](https://rdazadda.github.io/bayesqm/reference/rename_factors.md)
  relabels every table at once.
- Data import is unchanged, and grids with any distinct printed labels
  are accepted as they are.
- A second vignette, the output codebook, defines every column of every
  reported table, and the website gains three articles, the validation
  checks, the decision rules, and a start-to-finish walkthrough of the
  obesity panel.

### Dependencies

Stan is gone. rstantools, cmdstanr, rstan, GPArotation, and lpSolve are
no longer used, `posterior` moved to Imports, and `clue` joined
Suggests.

## bayesqm 0.1.0

CRAN release: 2026-06-17

First CRAN release. A Student-t factor model for Q sorts fitted through
Stan, with MatchAlign post-processing, membership probabilities, and
PSIS-LOO factor enumeration.
