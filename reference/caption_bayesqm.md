# Dynamic figure caption for a bayesqm_fit

Returns a human-readable caption string summarising the model
configuration (`K`, `N`, `J`, family), the sampler (backend, chains,
post-warmup draws), the interval probability, and convergence
diagnostics (max Rhat, divergent transitions). Optionally appends a
citation to the accompanying Psychometrika paper.

## Usage

``` r
caption_bayesqm(fit, include_ref = TRUE, include_diag = TRUE)
```

## Arguments

- fit:

  A `bayesqm_fit`.

- include_ref:

  Logical; append the paper citation.

- include_diag:

  Logical; append the convergence-diagnostic line.

## Value

A length-1 character string.

## Examples

``` r
if (FALSE) { # \dontrun{
cat(caption_bayesqm(fit))
} # }
```
