# Rename factors consistently across a bayesqm_fit

Replaces the default `f1..fK` factor labels everywhere they appear on
the fit: posterior-mean and credible-interval loading matrices, the
factor-score matrices, the factor-characteristics table, the correlation
matrix, the flagged matrix, the distinguishing / consensus table column
names, and the factor dimension of the raw `Lambda_draws` / `F_draws`
arrays.

## Usage

``` r
rename_factors(fit, new_names)
```

## Arguments

- fit:

  A `bayesqm_fit` object.

- new_names:

  Character vector of length `K` with the new factor labels.

## Value

The input fit with every factor label replaced.

## Examples

``` r
if (FALSE) { # \dontrun{
fit <- fit_bayesian(Y, K = 3)
fit <- rename_factors(fit, c("tradition", "innovation", "caution"))
} # }
```
