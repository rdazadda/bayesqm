# Posterior summary of scalar hyperparameters

Returns a tidy data frame with one row per scalar parameter and columns
`mean`, `median`, `sd`, `lower`, `upper`.

## Usage

``` r
compute_posterior_scalars(scalar_draws, prob = 0.95)
```

## Arguments

- scalar_draws:

  Named list of draw vectors. For a `bayesqm_fit`, pass
  `fit$hyperparams` directly.

- prob:

  Coverage probability for the credible interval.

## Value

A data frame.
