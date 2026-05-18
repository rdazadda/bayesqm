# Bayesian reliability-adjusted critical difference (default `delta`)

The default separation for the distinguishing and consensus
probabilities: a Bayesian reliability-adjusted critical difference
(Brown 1980; Zabala & Pascual 2016). With `p_f` the number of
participants whose posterior dominant factor is `f`,
`r_f = p_f r0 / (1 + (p_f - 1) r0)` and `SE_f = sqrt(1 - r_f)`,
`delta = z * mean_{k < l} sqrt(SE_k^2 + SE_l^2)`. The reliability is the
stable population reliability of the design, not the posterior
estimation spread.

## Usage

``` r
critical_delta(Lambda_draws, level = 0.05, r0 = 0.8)
```

## Arguments

- Lambda_draws:

  Array of shape `[T, N, K]` of aligned loading draws.

- level:

  Two-sided level for the critical value, `z = qnorm(1 - level/2)`.
  `0.05` (default) gives `z = 1.96`; `0.01` gives `z = 2.58`. Report
  sensitivity over `level`.

- r0:

  Conventional single-sort reliability (default `0.80`; Brown 1980).

## Value

A single numeric value, the critical-difference `delta`.

## Examples

``` r
critical_delta(array(rnorm(200 * 8 * 3), c(200, 8, 3)))
#> [1] 1.57724
```
