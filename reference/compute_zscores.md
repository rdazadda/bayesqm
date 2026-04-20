# Posterior summary of statement factor z-scores

Posterior mean and central credible-interval bounds for each
statement-factor z-score, returned as a tidy data frame with one row per
statement and three columns per factor.

## Usage

``` r
compute_zscores(F_draws, prob = 0.95)
```

## Arguments

- F_draws:

  Array of shape `[T, J, K]` of MatchAlign-aligned factor-score draws
  (e.g. `fit$F_draws`).

- prob:

  Coverage probability for the credible interval.

## Value

A data frame with columns `statement`, and three numeric columns per
factor: `fk_zsc` (posterior mean), `fk_lower`, and `fk_upper`, for
`k = 1..K`.
