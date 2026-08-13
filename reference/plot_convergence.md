# Convergence and alignment view

Traces of the invariant person spreads `s_i` for the persons with the
lowest effective sample size — the series the convergence gate reads —
plus the per-draw congruence of the aligned draws to the pivot, with the
gate report in the margin. A congruence histogram hugging 1 says the
alignment found one common orientation; a long left tail says some draws
sit far from it.

## Usage

``` r
plot_tucker(...)

plot_convergence(fit, n_series = 3)
```

## Arguments

- ...:

  Passed on.

- fit:

  A `bayesqm_fit`.

- n_series:

  How many worst-ESS persons to trace (default 3).

## Value

`fit`, invisibly.
