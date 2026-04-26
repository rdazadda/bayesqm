# MatchAlign Tucker's phi distribution by factor

Boxplot of the per-draw Tucker's phi between each aligned loading column
and the MatchAlign pivot, stored on `fit$align_info$congruence`. A
semi-transparent strip of the individual draws is overlaid so bimodality
– the visible signature of residual label-switching – is not hidden by
the box. A dashed rule at 0.95 marks the conventional near-identity
threshold.

## Usage

``` r
plot_tucker(fit, ...)
```

## Arguments

- fit:

  A `bayesqm_fit`.

- ...:

  Additional arguments forwarded to
  [`boxplot()`](https://rdrr.io/r/graphics/boxplot.html).

## Value

The input, invisibly.
