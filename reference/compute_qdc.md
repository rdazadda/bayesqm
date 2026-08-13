# Distinguishing and consensus verdicts

The statement verdict table. Distinguishing-for-a-factor is the joint
event that every contrast touching that factor exceeds the posterior
critical difference `delta_kl` (computed from the posterior spread of
the score contrasts); consensus is the equivalence event that all scores
sit within one grid column
([`delta_grid()`](https://rdazadda.github.io/bayesqm/reference/delta_grid.md))
of each other. Both families are selected through the posterior
false-discovery rule, and a statement can be distinguishing, consensus,
or indeterminate.

## Usage

``` r
compute_qdc(fit, q = 0.05, cons_floor = 0.95, prob = NULL)
```

## Arguments

- fit:

  A `bayesqm_fit` with `K >= 2`.

- q:

  Posterior expected false-discovery bound (default 0.05).

- cons_floor:

  Minimum consensus probability before a statement can be selected as
  consensus (default 0.95).

- prob:

  Credible-interval probability for the contrast intervals; defaults to
  the fit's. The critical difference itself keeps its z_0.975 definition
  regardless.

## Value

A data frame with one row per statement: per-factor distinguishing
probabilities, `consensus_prob`, and the `verdict`. Attributes:
`delta_kl` and `delta_kl99` (per pair), `delta_grid`, `contrasts` (the
per-pair contrast table with intervals, the probability
`diff_column_prob` that the two viewpoints place the statement in
different grid columns, and `stars`, `*` for selected claims and `**`
for those that also clear the `z_0.995` critical difference at
probability .99), and `expected_false` per family.

## Examples

``` r
compute_qdc(demo_fit())
#>    statement f1_dist_prob f2_dist_prob consensus_prob                 verdict
#> 1         S1        0.300        0.300          0.250           indeterminate
#> 2         S2        0.160        0.160          0.450           indeterminate
#> 3         S3        0.170        0.170          0.445           indeterminate
#> 4         S4        0.940        0.940          0.005 distinguishing (f1, f2)
#> 5         S5        0.060        0.060          0.645           indeterminate
#> 6         S6        0.915        0.915          0.005     distinguishing (f1)
#> 7         S7        0.100        0.100          0.500           indeterminate
#> 8         S8        0.195        0.195          0.315           indeterminate
#> 9         S9        0.135        0.135          0.430           indeterminate
#> 10       S10        0.540        0.540          0.125           indeterminate
#> 11       S11        0.980        0.980          0.000 distinguishing (f1, f2)
#> 12       S12        0.040        0.040          0.630           indeterminate
#> 13       S13        0.370        0.370          0.180           indeterminate
```
