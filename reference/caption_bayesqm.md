# Dynamic figure caption for a bayesqm_fit

Returns a human-readable caption string summarising the model
configuration (`K`, `N`, `J`, family), the sampler (backend, chains,
post-warmup draws), the interval probability, and convergence
diagnostics (max Rhat, divergent transitions).

## Usage

``` r
caption_bayesqm(fit, include_ref = TRUE, include_diag = TRUE)
```

## Arguments

- fit:

  A `bayesqm_fit`.

- include_ref:

  Logical; append a brief package-attribution line.

- include_diag:

  Logical; append the convergence-diagnostic line.

## Value

A length-1 character string.

## Examples

``` r
fit <- demo_fit(N = 6, J = 10, K = 2, Td = 50, seed = 1)
cat(caption_bayesqm(fit))
#> Bayesian Q-methodology factor model (K = 2, N = 6, J = 10); fitted with a Student-t likelihood via demo (4 chains, 4,000 post-warmup draws); intervals shown at 95% posterior coverage; max Rhat = 1.010, min bulk ESS = 820, 0 divergent transitions. Fitted with the bayesqm R package.
```
