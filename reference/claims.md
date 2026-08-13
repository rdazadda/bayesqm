# Selected claims at a common false-discovery level

Selects every claim — participant flags, distinguishing listings,
consensus statements, and pairwise stars — by the one posterior
false-discovery rule at level `q`, and reports the expected number of
false claims per family alongside. The same code path produces the
`selected` columns of
[`compute_flags()`](https://rdazadda.github.io/bayesqm/reference/compute_flags.md)
and
[`compute_qdc()`](https://rdazadda.github.io/bayesqm/reference/compute_qdc.md),
so the tables and this object always agree.

## Usage

``` r
claims(fit, q = 0.05, flag_floor = 0.5, cons_floor = 0.95)
```

## Arguments

- fit:

  A `bayesqm_fit`.

- q:

  Posterior expected false-discovery bound (default 0.05).

- flag_floor, cons_floor:

  Selection floors for flags (0.5) and consensus statements (0.95).

## Value

A `bayesqm_claims` object: selected-only tables `flags`,
`distinguishing`, `consensus`, and `stars`, each with its
`expected_false` count, plus the level `q`.

## Examples

``` r
claims(demo_fit())
#> Selected claims at q = 0.05 (posterior expected FDR):
#>   flags             0 participants selected (expected false 0.00)
#>   distinguishing    5 listings selected (expected false 0.25)
#>   consensus         0 statements selected (expected false 0.00)
#>   stars             2 pairwise selected (expected false 0.08)
```
