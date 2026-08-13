# Caption text for figures from a fit

A single string naming the model, the panel, the draws, and the gate
verdict — the provenance a figure caption should carry.

## Usage

``` r
caption_bayesqm(fit, include_gate = TRUE)
```

## Arguments

- fit:

  A `bayesqm_fit`.

- include_gate:

  Append the gate report (default `TRUE`).

## Value

A length-one character string.

## Examples

``` r
caption_bayesqm(demo_fit())
#> [1] "Exact partition (rank-order) likelihood; N = 8, J = 13, K = 2; 200 posterior draws. Convergence gate passed (max Rhat 1.053, min ESS 36)."
```
