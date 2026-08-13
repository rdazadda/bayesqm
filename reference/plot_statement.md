# One statement, in depth

The posterior of a single statement's score under each factor, drawn as
full densities with the medians marked, plus the statement's verdict and
its pairwise contrasts in the margin text. The drill-down for the
statement a write-up centers on.

## Usage

``` r
plot_statement(fit, statement, q = 0.05, cons_floor = 0.95)

plot_zscore_posterior(...)
```

## Arguments

- fit:

  A `bayesqm_fit`.

- statement:

  Statement id or index.

- q, cons_floor:

  As in
  [`compute_qdc()`](https://rdazadda.github.io/bayesqm/reference/compute_qdc.md).

- ...:

  Passed on.

## Value

`fit`, invisibly.
