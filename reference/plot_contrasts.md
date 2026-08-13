# Statement contrasts between two factors

Per statement, the posterior contrast interval for one factor pair, the
posterior critical difference `delta_kl` (dashed), and the grid-width
consensus region
([`delta_grid()`](https://rdazadda.github.io/bayesqm/reference/delta_grid.md),
shaded). Verdict colours: selected distinguishing listings, consensus
statements, indeterminate.

## Usage

``` r
plot_dist_cons(...)

plot_contrasts(fit, pair = 1, q = 0.05, cons_floor = 0.95)
```

## Arguments

- ...:

  Passed on.

- fit:

  A `bayesqm_fit` with `K >= 2`.

- pair:

  Which factor pair to draw (index into the pair list or `"f1-f2"`-style
  name; default 1).

- q, cons_floor:

  As in
  [`compute_qdc()`](https://rdazadda.github.io/bayesqm/reference/compute_qdc.md).

## Value

`fit`, invisibly.
