# Fit the model over a ladder of K

Fits
[`fit_bayesian()`](https://rdazadda.github.io/bayesqm/reference/fit_bayesian.md)
at each K in the ladder and stores, per rung, the fit together with the
adequacy and support evidence that
[`select_k()`](https://rdazadda.github.io/bayesqm/reference/select_k.md)
consumes. Expect roughly one full fit's runtime per rung; a message up
front says how many rungs are coming.

## Usage

``` r
fit_ladder(
  Y,
  K_max = NULL,
  K_min = 2,
  q = 0.05,
  screen_draws = 30,
  screen_mixes = 60,
  quiet = FALSE,
  ...
)
```

## Arguments

- Y:

  As in
  [`fit_bayesian()`](https://rdazadda.github.io/bayesqm/reference/fit_bayesian.md).

- K_max:

  Largest K to fit. `NULL` (default) uses `min(6, floor(N / 3))`, capped
  at 3 when `N <= 12` — with a dozen sorts or fewer, the data cannot
  formally discriminate adjacent K.

- K_min:

  Smallest K to fit (default 2).

- q:

  False-discovery level for the support evidence stored on each rung
  (default 0.05);
  [`select_k()`](https://rdazadda.github.io/bayesqm/reference/select_k.md)
  can re-select at another q.

- screen_draws, screen_mixes:

  Budget for the per-rung person check (defaults 30 and 60; the cluster
  signal needs no more).

- quiet:

  Suppress per-rung messages (default `FALSE`).

- ...:

  Passed to
  [`fit_bayesian()`](https://rdazadda.github.io/bayesqm/reference/fit_bayesian.md)
  (iterations, seed, ...).

## Value

A `bayesqm_ladder`: the per-rung fits and evidence.
