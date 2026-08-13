# Flag probabilities with an explicit unclassified state

For each participant, the posterior probability that the classical flag
rule fires on each signed factor, with the probability of remaining
unclassified alongside. Selected flags come from all signed candidates
by the posterior false-discovery rule at level `q`.

## Usage

``` r
compute_flags(fit, q = 0.05, floor = 0.5)
```

## Arguments

- fit:

  A `bayesqm_fit`.

- q:

  Posterior expected false-discovery bound (default 0.05).

- floor:

  Minimum flag probability a candidate needs before it can be selected
  (default 0.5, so at most one signed flag per participant).

## Value

A data frame with one row per participant: modal signed candidate
(`factor`, `sign`), its probability `flag_prob`, `unclassified_prob`,
and `selected`. The full probability matrix is attached as
`attr(, "phi")` and the expected number of false selected flags as
`attr(, "expected_false")`.

## Examples

``` r
compute_flags(demo_fit())
#>   participant factor sign flag_prob unclassified_prob selected
#> 1          P1     f1    1     0.840             0.120    FALSE
#> 2          P2     f2    1     0.795             0.195    FALSE
#> 3          P3     f1    1     0.875             0.120    FALSE
#> 4          P4     f2    1     0.750             0.250    FALSE
#> 5          P5     f1    1     0.895             0.105    FALSE
#> 6          P6     f2    1     0.325             0.520    FALSE
#> 7          P7     f1    1     0.785             0.195    FALSE
#> 8          P8     f2    1     0.330             0.645    FALSE
```
