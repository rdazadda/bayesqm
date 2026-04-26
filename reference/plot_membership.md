# Dominant-factor posterior-probability heatmap

Tiled heatmap of `P(argmax_k |Lambda[i, k]| = k)` with one row per
participant, one column per factor, rendered on a sequential blue ramp.
A right-side tier strip encodes Strong / Moderate / Weak membership (per
[`classify_membership()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-membership.md)).
A horizontal colourbar under the plot gives the probability scale. Rows
are sorted by dominant factor first, then tier, then probability – so
the block structure a reader wants to see is preserved.

## Usage

``` r
plot_membership(fit, sort = TRUE, ...)
```

## Arguments

- fit:

  A `bayesqm_fit`.

- sort:

  Logical; apply the default ordering.

- ...:

  Additional arguments forwarded to
  [`image()`](https://rdrr.io/r/graphics/image.html).

## Value

The input, invisibly.
