# Standard R accessors for bayesqm_fit

S3 methods that make a `bayesqm_fit` behave like a standard R modelling
object: [`coef()`](https://rdrr.io/r/stats/coef.html) returns the
posterior-mean loadings,
[`fitted()`](https://rdrr.io/r/stats/fitted.values.html) the
posterior-mean fitted Y on the original Q-sort scale,
[`residuals()`](https://rdrr.io/r/stats/residuals.html) is
`Y - fitted(fit)`, [`sigma()`](https://rdrr.io/r/stats/sigma.html) is
the posterior-mean residual scale,
[`nobs()`](https://rdrr.io/r/stats/nobs.html) is the number of
participants, and [`family()`](https://rdrr.io/r/stats/family.html)
returns a small `bayesqm_family` list with `$family`, `$link`, and
`$nu`. [`as.matrix()`](https://rdrr.io/r/base/matrix.html),
[`as.array()`](https://rdrr.io/r/base/array.html), and
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) return
the posterior draws in Stan-style parameter naming (`Lambda[i,k]`,
`F[j,k]`, `nu`, `sigma`, `tau`), which the posterior, bayesplot, and
tidybayes packages consume natively.

[`update()`](https://rdrr.io/r/stats/update.html) re-fits the model with
modified arguments; the original call and stored data are reused.

## Usage

``` r
# S3 method for class 'bayesqm_fit'
coef(object, ...)

# S3 method for class 'bayesqm_fit'
fitted(object, ...)

# S3 method for class 'bayesqm_fit'
residuals(object, ...)

# S3 method for class 'bayesqm_fit'
nobs(object, ...)

# S3 method for class 'bayesqm_fit'
sigma(object, ...)

# S3 method for class 'bayesqm_fit'
family(object, ...)

# S3 method for class 'bayesqm_family'
print(x, ...)

# S3 method for class 'bayesqm_fit'
as.matrix(x, ...)

# S3 method for class 'bayesqm_fit'
as.array(x, ...)

# S3 method for class 'bayesqm_fit'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)

# S3 method for class 'bayesqm_fit'
update(object, ..., evaluate = TRUE)
```

## Arguments

- object, x:

  A `bayesqm_fit` object.

- ...:

  Further arguments (e.g. arguments for
  [`update()`](https://rdrr.io/r/stats/update.html)).

- row.names, optional:

  Passed to
  [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html).

- evaluate:

  If `FALSE`, [`update()`](https://rdrr.io/r/stats/update.html) returns
  the modified call without evaluating it.

## Value

Depends on the method; see Description.
