# bayesqm 0.2.0

The model changed. 0.1.0 scored the grid positions and fit a Student-t
factor model through Stan. 0.2.0 models the forced Q sort as an
ordered partition of the statements, computes the probability of the
observed sorting event exactly, and fits it with a Gibbs sampler
written in R. Stan is no longer used. Scripts written against 0.1.0
need the changes below.

## Breaking changes

* `fit_bayesian()` fits the new model. The Stan-era arguments give
  migration errors that name their replacements.
* Functions keeping their names now return the new model's
  quantities. `compute_loadings()` gives bounded loadings with
  credible intervals, `compute_zscores()` scores with intervals from
  the aligned draws, `compute_factor_array()` a quota-exact array
  built from posterior column probabilities, and `matchalign()` takes
  and returns a whole fit.
* Removed with the score-scale model, each erroring with a pointer to
  its successor: `run_bayes()`, `select_k_peak()`, `select_k_sivula()`,
  `compute_dominant_prob()`, `compute_dominant_sign()`,
  `compute_threshold_prob()`, `classify_membership()`,
  `compute_divergence()`, `critical_delta()`,
  `compute_posterior_scalars()`, `demo_run()`, and `plot_hyper()`.
  `suggest_delta()` is replaced by `delta_grid()`, and `residuals()`
  on a fit errors because a rank likelihood has no residual scale.
* The fit object was rebuilt. The 0.1.0 slots are gone, and every
  table now comes from its own function.

## New

* One rule behind every claim. `claims()` selects the reported flags,
  distinguishing statements, consensus statements, and pairwise stars
  at a posterior false-discovery level and gives the expected number
  of false claims.
* A two-part choice of the number of factors. `fit_ladder()` fits the
  candidate models and `select_k()` checks each for adequacy and for
  per-factor support, refusing to select when no K passes both.
  `loo_ladder()` adds PSIS-LOO as directional corroboration.
* Model checks. `check_fit()` runs the posterior-predictive checks
  and `check_persons()` separates sorts the model spans from shared
  viewpoints it does not. Every fit passes a convergence check before
  it returns, and `extend()` continues a chain draw for draw.
* The tables. `compute_flags()` reports flag probabilities with an
  explicit unclassified state, `compute_qdc()` judges statements
  against a posterior critical difference and the one-grid-column
  consensus region with two-level stars, and
  `factor_characteristics()` gives the per-factor summary block.
* Alignment ends in a stabilized orientation, so the delivered
  rotation does not inherit one draw's sampling noise.
* `obesity_sorts` ships with the package, the childhood obesity panel
  of Akhtar-Danesh (2023). Thirty-three participants, forty-two
  statements, a nine-column grid.
* Plots rebuilt in one style, from `plot_sorts()`, which previews
  every participant's completed sort before any model runs, to
  `plot_choice_k()`, which draws the whole choice-of-K decision with
  its verdict written on the rows. `plot_zscores()`,
  `plot_statement()`, `plot_factor_array()`, `plot_contrasts()`,
  `plot_flags()`, `plot_loading_posterior()`, `plot_person_check()`,
  `plot_convergence()`, and `plot_ppc()` cover the remaining views,
  with `ggplot2::autoplot()` methods for loadings, flags, contrasts,
  and the array.
* `rotate_factors()` applies judgmental rotation to every draw,
  `flip_factor()` reverses a pole, and `rename_factors()` relabels
  every table at once.
* Data import is unchanged, and grids with any distinct printed
  labels are accepted as they are.

## Dependencies

Stan is gone. rstantools, cmdstanr, rstan, GPArotation, and lpSolve
are no longer used, `posterior` moved to Imports, and `clue` joined
Suggests.

# bayesqm 0.1.0

First CRAN release. A Student-t factor model for Q sorts fitted
through Stan, with MatchAlign post-processing, membership
probabilities, and PSIS-LOO factor enumeration.
