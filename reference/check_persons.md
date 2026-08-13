# The person check against mixed-replication bands

For each participant, the model-agreement statistic `m` (mean over draws
of the best absolute Spearman agreement with any factor array) and the
person-agreement statistic `w` (best absolute agreement with any other
sort), each located against bands from mixed replicates (fresh persons
drawn from the fitted model). Verdicts: `fits`, `no_shared` (below the
model band, inside the person band), `unspanned` (below the model band
but above the person band, a shared viewpoint the fitted factors do not
span), and `atypical`. Unspanned persons name their nearest partner.

## Usage

``` r
check_persons(fit, draws = 60, mixes = 150)
```

## Arguments

- fit:

  A `bayesqm_fit`.

- draws:

  Draw grid for the arrays (default 60).

- mixes:

  Mixed replicates for the bands (default 150).

## Value

A `bayesqm_persons` data frame: `participant`, `m`, `w`, `partner`,
`verdict`, with the band limits attached as attributes.

## Examples

``` r
check_persons(demo_fit(), draws = 20, mixes = 40)
#> Person check: fits 8, no_shared 0, unspanned 0, atypical 0 
#>  participant    m    w partner partner_index verdict
#>           P1 0.76 0.67      P3             3    fits
#>           P2 0.73 0.71      P4             4    fits
#>           P3 0.79 0.71      P5             5    fits
#>           P4 0.70 0.71      P2             2    fits
#>           P5 0.80 0.71      P3             3    fits
#>           P6 0.47 0.62      P5             5    fits
#>           P7 0.73 0.67      P5             5    fits
#>           P8 0.39 0.39      P6             6    fits
```
