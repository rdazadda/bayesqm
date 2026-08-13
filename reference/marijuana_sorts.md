# Marijuana legalization Q sorts

The marijuana legalization Q dataset from Akhtar-Danesh (2023): 40
participants each force-sorted 19 statements about marijuana
legalization onto a seven-column grid (quotas 1-2-4-5-4-2-1, printed
values -3 to +3). A real, published panel with a small statement set,
used in the package documentation.

## Usage

``` r
marijuana_sorts
```

## Format

A
[qsort_data](https://rdazadda.github.io/bayesqm/reference/qsort_data.md)
object: the 19 x 40 integer matrix of printed grid values with statement
and participant ids, and the forced distribution.

## Source

Akhtar-Danesh, N. (2023). Impact of factor rotation on Q-methodology
analysis. *PLOS ONE*, 18(9), e0290728.
[doi:10.1371/journal.pone.0290728](https://doi.org/10.1371/journal.pone.0290728)

## Examples

``` r
marijuana_sorts
#> Q-sort data
#>   statements  : 19   participants : 40 
#>   distribution: 1 2 4 5 4 2 1   (sum = 19 )
#>   value range : [-3, 3]
#>   source      : excel:Marijuana legalization dataset.xlsx 
plot(marijuana_sorts, participants = 1:4)
```
