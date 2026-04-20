# Prior summary for a bayesqm_fit

Returns the priors actually used when the model was fit, as a printable
`bayesqm_prior` object. Method for
[`rstantools::prior_summary()`](https://mc-stan.org/rstantools/reference/prior_summary.html).

## Usage

``` r
# S3 method for class 'bayesqm_fit'
prior_summary(object, ...)

# S3 method for class 'bayesqm_prior'
print(x, ...)
```

## Arguments

- object:

  A `bayesqm_fit`.

- ...:

  Unused.

- x:

  A `bayesqm_prior` object.

## Value

A `bayesqm_prior` data frame with columns `parameter` and `prior`.
