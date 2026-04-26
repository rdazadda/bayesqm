# ELPD across K with peak and Sivula annotations

ELPD against K with +/- 1.96 SE whiskers, a solid vertical rule at the
ELPD peak, and a dashed rule at the Sivula (parsimony) K. Both rules are
drawn in the primary blue, distinguished by line type and by text
annotations at the top of the axis. The title reports the
peak-plus-Sivula case (`agree`, `gap`, `reversed`).

## Usage

``` r
plot_elpd(run, ...)
```

## Arguments

- run:

  A `bayesqm_run`.

- ...:

  Additional arguments forwarded to
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html).

## Value

The input, invisibly.
