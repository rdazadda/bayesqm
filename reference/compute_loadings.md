# Posterior summary of participant factor loadings

Posterior mean and central credible-interval bounds for each
participant-factor loading, returned as a tidy data frame with one row
per participant and three columns per factor.

## Usage

``` r
compute_loadings(Lambda_draws, prob = 0.95)
```

## Arguments

- Lambda_draws:

  Array of shape `[T, N, K]` of MatchAlign-aligned loading draws (e.g.
  `fit$Lambda_draws`).

- prob:

  Coverage probability for the credible interval (default 0.95).

## Value

A data frame with columns `participant`, and three numeric columns per
factor: `fk_loa` (posterior mean), `fk_lower`, and `fk_upper`, for
`k = 1..K`.
