# Rotate every aligned draw toward a target

Judgmental rotation: each aligned draw's statement scores are rotated
toward an analyst-specified target by Procrustes, and the loadings
receive the same rotation (its inverse transpose when `oblique = TRUE`),
so the latent utilities every draw implies are unchanged. Summaries
computed from the returned fit are summaries of the rotated solution,
with full posterior uncertainty.

## Usage

``` r
rotate_factors(fit, target, oblique = FALSE)
```

## Arguments

- fit:

  A `bayesqm_fit`.

- target:

  A `J x K` numeric matrix of target scores (for example, a hand-edited
  copy of the posterior-mean scores).

- oblique:

  Allow an oblique (non-orthogonal) rotation (default `FALSE`).

## Value

The fit with rotated draws; `fit$align$rotated` records the call.
