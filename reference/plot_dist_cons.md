# Distinguishing-statement posterior-probability heatmap

Heatmap of `P(|F_jk - F_jl| > delta)` with rows = statements and columns
= factor pairs. High probability (dark) indicates that the statement
reliably distinguishes that factor pair. Statements are ordered by their
maximum distinguishing probability so the most discriminating statements
cluster at the top.

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

  Passed to [`image()`](https://rdrr.io/r/graphics/image.html).

## Value

The input, invisibly.
