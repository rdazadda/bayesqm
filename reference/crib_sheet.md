# Extreme-placement probabilities per statement and factor

The crib sheet: for each statement and factor, the posterior probability
of landing in the top or bottom grid column of that factor's array, and
of carrying the highest or lowest score across factors.

## Usage

``` r
crib_sheet(fit)
```

## Arguments

- fit:

  A `bayesqm_fit`.

## Value

A long data frame: `statement`, `factor`, `p_top`, `p_bottom`,
`p_highest`, `p_lowest`.

## Examples

``` r
head(crib_sheet(demo_fit()))
#>   statement factor p_top p_bottom p_highest p_lowest
#> 1        S1     f1 0.000    0.065     0.930    0.070
#> 2        S2     f1 0.005    0.000     0.230    0.770
#> 3        S3     f1 0.000    0.120     0.200    0.800
#> 4        S4     f1 0.740    0.000     1.000    0.000
#> 5        S5     f1 0.080    0.000     0.645    0.355
#> 6        S6     f1 0.000    0.135     0.005    0.995
```
