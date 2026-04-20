# MatchAlign Tucker's phi distribution by factor

Boxplot of the per-draw Tucker's phi between each aligned loading column
and its pivot, stored in `fit$align_info$congruence`. A dashed reference
line is drawn at 0.95 (a common near-identity threshold for rotational
agreement).

## Usage

``` r
plot_tucker(fit, ...)
```

## Arguments

- fit:

  A `bayesqm_fit`.

- ...:

  Passed to [`boxplot()`](https://rdrr.io/r/graphics/boxplot.html).

## Value

The input, invisibly.
