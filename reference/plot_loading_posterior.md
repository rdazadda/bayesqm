# Loading forest with 50 and 95 percent credible intervals

Horizontal dotchart of every participant's loading, one panel per
factor, ranked by posterior mean. Each loading is drawn as a median
point with nested 50 percent (thick) and 95 percent (thin)
credible-interval whiskers. A faint grey vertical rule marks Brown's
descriptive cut-off `+/- 1.96 / sqrt(J)`. When
`highlight_flagged = TRUE`, participants in `fit$flagged[, k]` are drawn
as filled points in the accent colour.

## Usage

``` r
plot_loading_posterior(fit, factors = NULL, highlight_flagged = TRUE, ...)
```

## Arguments

- fit:

  A `bayesqm_fit`.

- factors:

  Optional subset of factors to show (integer or name).

- highlight_flagged:

  Logical; fill flagged participants.

- ...:

  Additional arguments forwarded to
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html).

## Value

The input, invisibly.
