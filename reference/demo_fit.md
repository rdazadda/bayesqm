# A small demonstration fit

Runs the partition-model sampler on a small synthetic forced-sort
dataset with a fixed seed and the convergence gate disabled. It exists
so examples and tests have a complete `bayesqm_fit` in about a second;
it is no substitute for
[`fit_bayesian()`](https://rdazadda.github.io/bayesqm/reference/fit_bayesian.md)
at its defaults on real data.

## Usage

``` r
demo_fit(N = 8, J = 13, K = 2, draws = 200, seed = 1)
```

## Arguments

- N, J, K:

  Panel size, statement count, factors (defaults 8, 13, 2).

- draws:

  Kept posterior draws (default 200).

- seed:

  Random seed (default 1).

## Value

A `bayesqm_fit`.

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
