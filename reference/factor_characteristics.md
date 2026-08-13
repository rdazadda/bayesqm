# Factor characteristics

The per-factor block of the accompanying paper: modal and mean number of
defining sorts per posterior draw with a credible interval, the selected
flag count, the mean posterior spread of the statement scores, and the
mean replicate reliability `R_i = s_i^2 / (1 + s_i^2)` of the flagged
participants. The statement-score correlations between factors ride
along as an attribute.

## Usage

``` r
factor_characteristics(fit, prob = 0.9, q = 0.05, floor = 0.5)
```

## Arguments

- fit:

  A `bayesqm_fit`.

- prob:

  Credible-interval probability for the defining-sort counts (default
  0.90).

- q, floor:

  The flag rule fixing the flagged set, as in
  [`compute_flags()`](https://rdazadda.github.io/bayesqm/reference/compute_flags.md).

## Value

A data frame with one row per factor: `factor`, `flagged` (selected
flags), `defining_modal`, `defining_mean`, `defining_lower`,
`defining_upper`, `score_spread`, and `reliability`. Attribute
`score_correlations` holds the posterior mean K x K correlation matrix
of the statement scores.

## Examples

``` r
factor_characteristics(demo_fit())
#>   factor flagged defining_modal defining_mean defining_lower defining_upper
#> 1     f1       0              4         3.585              2              5
#> 2     f2       0              2         2.265              1              4
#>   score_spread reliability
#> 1    0.4153759          NA
#> 2    0.5072720          NA
```
