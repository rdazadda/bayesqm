# Credible intervals for bayesqm_fit parameters

Posterior credible intervals for any subset of parameters in a
`bayesqm_fit`. Method for
[`rstantools::posterior_interval()`](https://mc-stan.org/rstantools/reference/posterior_interval.html).

## Usage

``` r
# S3 method for class 'bayesqm_fit'
posterior_interval(object, prob = 0.95, pars = NULL, regex_pars = NULL, ...)
```

## Arguments

- object:

  A `bayesqm_fit`.

- prob:

  Coverage probability (default 0.95).

- pars:

  Optional character vector of exact parameter names.

- regex_pars:

  Optional regex; matching parameter names are included in addition to
  those named in `pars`.

- ...:

  Unused.

## Value

A matrix with one row per parameter and two columns for the lower and
upper interval bounds (as percent strings).
