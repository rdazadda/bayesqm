# Posterior predictive check on the correlation-matrix RMSE

Histogram of the replicated correlation-matrix RMSE stored on
`fit$ppc$rmse.r`: per draw, the RMSE between `cor(Y_rep)` and
`cor(Y_obs)`. Rendered in the bayesplot-idiom (filled bars, no border,
suppressed y-axis) with the median and central credible interval marked.

## Usage

``` r
plot_ppc(fit, breaks = 30, ...)
```

## Arguments

- fit:

  A `bayesqm_fit`.

- breaks:

  Passed to [`hist()`](https://rdrr.io/r/graphics/hist.html).

- ...:

  Additional arguments forwarded to
  [`hist()`](https://rdrr.io/r/graphics/hist.html).

## Value

The input, invisibly.
