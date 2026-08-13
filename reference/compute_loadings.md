# Bounded participant loadings with credible intervals

The correlation-scale loading of the accompanying paper,
`rho = (S lambda)_k / sqrt(s^2 + 1)`, summarized per participant and
factor, with the posterior-mean person spread `s_i` alongside.

## Usage

``` r
compute_loadings(fit, prob = NULL)
```

## Arguments

- fit:

  A `bayesqm_fit`.

- prob:

  Credible-interval probability; defaults to the fit's.

## Value

A data frame with one row per participant: `participant`, then
`f{k}_loading`, `f{k}_lower`, `f{k}_upper` per factor, then `spread`
(posterior-mean `s_i`).

## Examples

``` r
compute_loadings(demo_fit())
#>   participant  f1_loading   f1_lower  f1_upper  f2_loading   f2_lower
#> 1          P1  0.69758061  0.3510298 0.8852994 -0.35029454 -0.6733120
#> 2          P2 -0.11857555 -0.4985179 0.2018393  0.67754437  0.1103558
#> 3          P3  0.71649641  0.4107087 0.9122487  0.15110204 -0.3070454
#> 4          P4 -0.06232255 -0.4502353 0.3744591  0.64745185  0.1622277
#> 5          P5  0.74401521  0.3315242 0.9250481  0.02104403 -0.3902214
#> 6          P6  0.32643262 -0.1344789 0.6793355  0.40741163 -0.1900813
#> 7          P7  0.66747888  0.3087604 0.8881110 -0.21967080 -0.5550783
#> 8          P8 -0.10723455 -0.5472559 0.3336800  0.41395008 -0.1431438
#>     f2_upper    spread
#> 1 0.06053878 1.5259877
#> 2 0.93709993 1.2808817
#> 3 0.51003980 1.3814252
#> 4 0.89838180 1.1044914
#> 5 0.42913354 1.4169065
#> 6 0.78570220 0.8629496
#> 7 0.15162069 1.1991796
#> 8 0.84841646 0.6776481
```
