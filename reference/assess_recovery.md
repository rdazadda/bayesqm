# Simulation-study assessment helpers

`assess_recovery()` compares a point estimate and optional posterior
draws to a known loading truth, returning RMSE, per-factor RMSE, bias,
Tucker's congruence, credible-interval coverage, width, and
Gneiting-Raftery interval score. `assess_classification()` compares a
logical flag matrix to the true factor assignments using optimal
permutation matching.

## Usage

``` r
assess_recovery(Lambda_hat, Lambda_true, Lambda_draws = NULL, prob = 0.95)

assess_classification(flags, Lambda_true)
```

## Arguments

- Lambda_hat:

  Estimated loading matrix (N x K).

- Lambda_true:

  True loading matrix.

- Lambda_draws:

  Optional array of shape `[T, N, K]` of posterior draws, used for
  coverage / interval metrics.

- prob:

  Credible-interval probability.

- flags:

  Logical matrix of factor assignments.

## Value

`assess_recovery()` returns a list of metrics; `assess_classification()`
returns a list with `accuracy` and `per_factor`.
