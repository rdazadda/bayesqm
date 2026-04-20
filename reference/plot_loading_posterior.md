# Loading forest with 50 and 95 percent credible intervals

One panel per factor, horizontal dotchart of posterior-median loadings
with nested 50 percent (thick) and 95 percent (thin) credible intervals,
ranked by posterior mean. A dashed vertical rule marks the classical
Brown cut-off `1.96 / sqrt(J)`; when `highlight_flagged = TRUE`,
participants in `fit$flagged` for that factor are drawn as filled
points.

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

  Unused.

## Value

The input, invisibly.
