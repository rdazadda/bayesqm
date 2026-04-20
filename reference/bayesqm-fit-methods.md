# Print and summary methods for bayesqm_fit and bayesqm_run

[`print()`](https://rdrr.io/r/base/print.html) shows a compact,
brms-style header with convergence and the first few loadings.
[`summary()`](https://rdrr.io/r/base/summary.html) expands with factor
characteristics, the PSIS-LOO estimate, the distinguishing/consensus
count, and the MatchAlign Tucker-phi diagnostic. Both methods exist for
`bayesqm_fit` (returned by
[`fit_bayesian()`](https://rdazadda.github.io/bayesqm/reference/fit_bayesian.md))
and `bayesqm_run` (returned by
[`run_bayes()`](https://rdazadda.github.io/bayesqm/reference/run_bayes.md)).

## Usage

``` r
# S3 method for class 'bayesqm_fit'
print(x, digits = 2, length = 10, ...)

# S3 method for class 'bayesqm_fit'
summary(object, digits = 3, ...)

# S3 method for class 'bayesqm_run'
print(x, digits = 2, ...)

# S3 method for class 'bayesqm_run'
summary(object, ...)
```

## Arguments

- x, object:

  A `bayesqm_fit` or `bayesqm_run` object.

- digits:

  Number of digits to print.

- length:

  Maximum number of participant rows to show in the compact loading
  table.

- ...:

  Unused.

## Value

The input, invisibly.
