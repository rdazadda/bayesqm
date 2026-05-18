# Suggested separation `delta` from the forced distribution

Returns the standardized-scale width of one forced-distribution
category, `1 / sd(forced positions)`. This is an alternative separation
to the package default, the reliability-adjusted critical difference of
[`critical_delta()`](https://rdazadda.github.io/bayesqm/reference/critical_delta.md).

## Usage

``` r
suggest_delta(distribution)
```

## Arguments

- distribution:

  Integer vector of forced-distribution counts (the number of statements
  allowed in each grid column).

## Value

A single numeric value: the standardized width of one
forced-distribution category.

## Examples

``` r
suggest_delta(c(2, 3, 4, 6, 8, 6, 4, 3, 2))
#> [1] 0.477907
```
