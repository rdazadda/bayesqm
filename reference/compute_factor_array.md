# Factor arrays on the forced Q-sort distribution

Posterior-mean factor z-scores ranked onto the study's forced
distribution. The result is a tidy data frame with one row per statement
and per-factor integer grid scores. For the continuous z-scores with
credible intervals, use
[`compute_zscores()`](https://rdazadda.github.io/bayesqm/reference/compute_zscores.md).

## Usage

``` r
compute_factor_array(F_draws, Y)
```

## Arguments

- F_draws:

  Array of shape `[T, J, K]` of factor-score draws.

- Y:

  The Q-sort matrix whose first column supplies the forced distribution
  (as in the original study's grid).

## Value

A data frame with columns `statement` and
`f1_grid, f2_grid, ..., fK_grid`.
