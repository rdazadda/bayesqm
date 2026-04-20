# Per-statement factor-score posterior across factors

For a single statement, draws the posterior median z-score with 50
percent (thick) and 95 percent (thin) credible-interval bars for each
factor, stacked vertically. Reveals, per statement, which factors place
it above zero and whether the factors actually distinguish it.

## Usage

``` r
plot_zscore_posterior(fit, statement, ...)
```

## Arguments

- fit:

  A `bayesqm_fit`.

- statement:

  Integer index or statement name.

- ...:

  Unused.

## Value

The input, invisibly.
