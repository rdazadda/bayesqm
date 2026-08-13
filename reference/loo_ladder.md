# PSIS-LOO across the ladder, as directional corroboration

Person-level GHK log-likelihoods per rung, fed to PSIS-LOO. Reported as
directional corroboration only: with typical Q panels (N well below
100), differences in expected log predictive density between adjacent K
have unreliable standard errors. The GHK seeds are common across rungs,
so comparisons are common-random-number paired.

## Usage

``` r
loo_ladder(ladder, draws = 100, R = 64)
```

## Arguments

- ladder:

  A `bayesqm_ladder`.

- draws, R:

  As in
  [`loglik_person()`](https://rdazadda.github.io/bayesqm/reference/loglik_person.md).

## Value

A data frame: `K`, `elpd_loo`, `se`, `max_pareto_k`.
