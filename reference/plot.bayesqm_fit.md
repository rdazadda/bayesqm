# Factor-score dotchart for a bayesqm_fit

One panel per factor: horizontal dotchart of every statement's posterior
median z-score with nested 50 percent (thick) and `prob`-coverage (thin)
credible-interval whiskers. Statements are sorted once – by default, by
the first factor's posterior mean – and that ordering is reused across
panels so the reader can scan horizontally to compare factors. For a
loadings-only view, see
[`plot_loading_posterior()`](https://rdazadda.github.io/bayesqm/reference/plot_loading_posterior.md);
for a single statement across factors, see
[`plot_zscore_posterior()`](https://rdazadda.github.io/bayesqm/reference/plot_zscore_posterior.md).

## Usage

``` r
# S3 method for class 'bayesqm_fit'
plot(x, sort_by = 1L, prob = NULL, cex.lab = 0.7, ...)
```

## Arguments

- x:

  A `bayesqm_fit`.

- sort_by:

  Integer factor index whose posterior mean is used to sort rows
  (default 1).

- prob:

  Outer-interval coverage probability; defaults to `fit$brief$prob`.

- cex.lab:

  Axis-label text size.

- ...:

  Additional arguments forwarded to
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html).

## Value

The input, invisibly.
