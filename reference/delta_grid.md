# Grid width on the z scale

The width of one grid column on the standardized score scale,
`1 / sd(forced positions)` with the population standard deviation. This
is the equivalence-region half-width used for consensus verdicts: a
score contrast smaller than one grid column is not expressible in a
completed sort.

## Usage

``` r
delta_grid(distribution)
```

## Arguments

- distribution:

  Integer vector of forced-distribution counts (the number of statements
  allowed in each grid column).

## Value

A single numeric value.

## Examples

``` r
delta_grid(c(2, 3, 4, 5, 7, 7, 5, 4, 3, 2))
#> [1] 0.4268637
```
