# Posterior predictive check on the correlation-matrix RMSE

Histogram of the replicated correlation-matrix RMSE stored on the fit
(`fit$ppc$rmse.r`): for each posterior draw, the RMSE between the
between-participant correlation matrix under the replicated data and
under the observed data. Lower is better; the median and central
credible-interval bounds are marked.

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

  Passed to [`hist()`](https://rdrr.io/r/graphics/hist.html).

## Value

The input, invisibly.
