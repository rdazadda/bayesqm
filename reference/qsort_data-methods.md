# Print, summary, and matrix conversion for qsort_data

## Usage

``` r
# S3 method for class 'qsort_data'
print(x, ...)

# S3 method for class 'qsort_data'
summary(object, ...)

# S3 method for class 'qsort_data'
as.matrix(x, ...)
```

## Arguments

- x, object:

  A `qsort_data` object.

- ...:

  Unused.

## Value

[`print()`](https://rdrr.io/r/base/print.html) and
[`summary()`](https://rdrr.io/r/base/summary.html) return the input
invisibly; [`as.matrix()`](https://rdrr.io/r/base/matrix.html) returns
the `J x N` Q-sort matrix.
