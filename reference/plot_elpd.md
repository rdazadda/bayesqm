# ELPD across K with peak and Sivula markers

Plots the ELPD across the K values enumerated by
[`run_bayes()`](https://rdazadda.github.io/bayesqm/reference/run_bayes.md),
with +/- 1.96 SE bars, a dashed vertical rule at the Sivula K and a
solid vertical rule at the ELPD-peak K. The plot title reports the
peak-plus-Sivula case (`agree`, `gap`, `reversed`).

## Usage

``` r
plot_elpd(run, ...)
```

## Arguments

- run:

  A `bayesqm_run` object.

- ...:

  Passed to [`plot()`](https://rdrr.io/r/graphics/plot.default.html).

## Value

The input, invisibly.
