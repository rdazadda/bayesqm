# Per-statement factor-score posterior across factors

For a single statement, draws the posterior median z-score per factor
with nested 50 percent (thick) and 95 percent (thin) credible-interval
whiskers, stacked vertically. The x-axis is symmetric around zero so the
zero reference is centred.

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

  Additional arguments forwarded to
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html).

## Value

The input, invisibly.
