# Distinguishing-statement posterior-probability heatmap

Heatmap of `P(|F[j, k] - F[j, l]| > delta)` for every statement and
every factor pair, rendered on a sequential blue ramp. Rows are ordered
so the most discriminating statements are at the top. A vertical colour
bar in the right margin gives the probability scale.

## Usage

``` r
plot_dist_cons(fit, delta = 1, ...)
```

## Arguments

- fit:

  A `bayesqm_fit`.

- delta:

  Minimum z-score separation (default 1.0).

- ...:

  Additional arguments forwarded to
  [`image()`](https://rdrr.io/r/graphics/image.html).

## Value

The input, invisibly.
