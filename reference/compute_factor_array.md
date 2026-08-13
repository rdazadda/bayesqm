# Quota-respecting factor arrays

The reported array for each factor: statements sorted onto the design
grid by their posterior column probabilities (mean grid column,
tie-broken by posterior-mean score), which is quota-exact by
construction. When the clue package is installed, a footrule assignment
cross-check is computed and its disagreement rate attached.

## Usage

``` r
compute_factor_array(fit, negative = FALSE)
```

## Arguments

- fit:

  A `bayesqm_fit`.

- negative:

  Also return the negative-pole arrays (default `FALSE`); on a symmetric
  grid the mirror is exact.

## Value

A data frame with one row per statement: `statement`, then `f{k}_grid`
per factor (and `f{k}_grid_neg` when `negative = TRUE`).
`attr(, "footrule_disagreement")` gives the share of cells where the
footrule assignment differs (`NA` without clue).

## Examples

``` r
compute_factor_array(demo_fit())
#>    statement f1_grid f2_grid
#> 1         S1       4       1
#> 2         S2       5       6
#> 3         S3       3       3
#> 4         S4       8       3
#> 5         S5       6       6
#> 6         S6       3       8
#> 7         S7       4       5
#> 8         S8       6       4
#> 9         S9       5       7
#> 10       S10       1       5
#> 11       S11       7       2
#> 12       S12       5       5
#> 13       S13       2       4
```
