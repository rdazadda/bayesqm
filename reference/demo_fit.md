# A synthetic bayesqm_fit for examples and tutorials

Returns a `bayesqm_fit` object built from pre-generated posterior draws,
so every summary and plot function can run without a Stan backend. Use
it for demonstrations, teaching materials, and the package vignette. It
is not a substitute for
[`fit_bayesian()`](https://rdazadda.github.io/bayesqm/reference/fit_bayesian.md)
on real data.

## Usage

``` r
demo_fit(N = 20, J = 22, K = 2, Td = 400, seed = 1L)
```

## Arguments

- N:

  Number of participants.

- J:

  Number of statements.

- K:

  Number of factors.

- Td:

  Number of posterior draws.

- seed:

  Integer seed for reproducibility.

## Value

A `bayesqm_fit`.

## Examples

``` r
fit <- demo_fit(N = 12, J = 15, K = 2)
plot(fit)

summary(fit)
#> Bayesian Q-methodology factor model
#>   Call:      fit_bayesian(Y, K = K)
#>   Family:    Student-t (nu = estimated)
#>   Factors:   K = 2
#>   Data:      N = 12 persons, J = 15 statements
#>   Draws:     4 chains x 1000 post-warmup = 4000 total
#>   Backend:   demo
#>   Fitted:    2026-04-24 21:09:42
#>   Max Rhat:  1.010
#>   Min ESS:   bulk 820 / tail 950
#>   Divergent: 0
#> 
#> Factor characteristics:
#>    nload eigenvals expl_var
#> f1     6     4.349    36.24
#> f2     6     4.212    35.10
#> 
#> Hyperparameters (posterior summary):
#>  parameter   mean median     sd  lower  upper
#>         nu 19.784 19.926 3.7919 11.789 26.876
#>      sigma  0.499  0.502 0.0804  0.340  0.655
#>        tau  0.505  0.505 0.0828  0.343  0.665
#> 
#> Distinguishing / consensus statements (delta = 1.0, p > 0.95):
#> 
#> MatchAlign diagnostics (mean Tucker phi per factor):
#>   f1 = 0.960  f2 = 0.960  
```
