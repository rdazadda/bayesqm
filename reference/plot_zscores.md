# Statement scores across factors, whole panel

Every statement's score under every factor, with nested 50% and 95%
credible intervals — the classic Q z-score chart carrying its
uncertainty. Statements are ordered by how strongly the factors diverge
on them, so the top of the chart is where the viewpoints disagree and
the bottom is where they concur; the left margin marks each statement's
verdict.

## Usage

``` r
plot_zscores(
  fit,
  order_by = c("divergence", "score"),
  q = 0.05,
  cons_floor = 0.95
)
```

## Arguments

- fit:

  A `bayesqm_fit`.

- order_by:

  `"divergence"` (default; by the largest median pairwise contrast) or
  `"score"` (by the first factor's median score).

- q, cons_floor:

  As in
  [`compute_qdc()`](https://rdazadda.github.io/bayesqm/reference/compute_qdc.md)
  (used for the verdict marks when `K >= 2`).

## Value

`fit`, invisibly.
