# Fit the exact partition-likelihood model to forced Q sorts

Models each completed sort as a forced ordered partition of the
statements and samples the posterior of the latent factor model by a
parameter-expanded Gibbs sampler. Convergence is gated on
rotation-invariant person spreads (rank-normalized split-R-hat and
bulk/tail effective sample size); a chain failing the gate is
warm-extended at successive doublings up to `max_iterations`. Draws are
aligned by MatchAlign with a polarity canon, so defining sorts load
positively.

## Usage

``` r
fit_bayesian(
  Y,
  K,
  iterations = 12000,
  burn = 2000,
  thin = 5,
  max_iterations = 48000,
  seed = NULL,
  sigma_scale = 1,
  rhat_max = 1.01,
  ess_min = 400,
  prob = 0.95,
  keep_raw = TRUE,
  pivot = NULL,
  quiet = FALSE,
  ...
)
```

## Arguments

- Y:

  A `qsort_data` object, or a `J x N` numeric matrix of grid positions
  with statements as rows and participants as columns. Every sort must
  obey the forced distribution exactly.

- K:

  Integer number of factors.

- iterations:

  First-check chain length (default 12000, the settings frozen in the
  accompanying paper).

- burn:

  Burn-in iterations (default 2000), paid once; extensions continue the
  chain.

- thin:

  Keep every `thin`-th post-burn draw (default 5).

- max_iterations:

  Total-iteration cap for the gated extension ladder (default 48000).

- seed:

  Optional integer seed; fits are exactly reproducible given the seed.

- sigma_scale:

  Half-normal prior scale for the per-factor loading scales (default 1).

- rhat_max, ess_min:

  Gate thresholds (defaults 1.01 and 400).

- prob:

  Credible-interval probability stored on the fit (default 0.95).

- keep_raw:

  Keep the pre-alignment draws on the fit (default `TRUE`); required by
  [`extend()`](https://rdazadda.github.io/bayesqm/reference/extend.md)
  and by realignment under a different pivot.

- pivot:

  Optional draw index for the alignment pivot; `NULL` (the default) uses
  the median-condition-number rule.

- quiet:

  Suppress progress messages (default `FALSE`).

- ...:

  Unused; supplying a removed 0.1.0 argument gives a migration error.

## Value

A `bayesqm_fit` carrying aligned draws, the gate report, the alignment
record, and (when `keep_raw = TRUE`) the raw draws and sampler state.

## Examples

``` r
fit <- demo_fit()
fit
#> bayesqm fit: exact partition (rank-order) likelihood, PX-Gibbs
#>   8 participants, 13 statements, 2 factors; grid 1-1-2-2-3-2-1-1
#>   draws: 200 kept (500 iterations, burn 100, thin 2)
#>   gate: passed (max Rhat 1.053; min ESS 36 bulk / 98 tail)
#>   alignment: pivot draw 33, mean congruence 0.78
#>   tables: compute_loadings(), compute_flags(), compute_factor_array(),
#>           compute_qdc(), claims()
```
