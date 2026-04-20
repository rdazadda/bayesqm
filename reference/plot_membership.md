# Dominant-factor posterior-probability heatmap

Tiled heatmap of `P(argmax_k |Lambda[i, k]| = k)` with one row per
participant and one column per factor, annotated by a right-side tier
strip (Strong / Moderate / Weak following
[`classify_membership()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-membership.md)).
Rows are sorted by tier and then by dominant factor.

## Usage

``` r
plot_membership(fit, sort = TRUE, ...)
```

## Arguments

- fit:

  A `bayesqm_fit`.

- sort:

  Logical; reorder participants by tier and dominant factor.

- ...:

  Passed to [`image()`](https://rdrr.io/r/graphics/image.html).

## Value

The input, invisibly.
