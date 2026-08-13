# Bounded loadings with credible intervals

One row per participant, one interval per factor on the bounded loading
scale, with selected flags marked. The dotted rules sit at the classical
descriptive cut-off `1.96 / sqrt(J)` (reference).

## Usage

``` r
plot_loading_posterior(fit, q = 0.05)

# S3 method for class 'bayesqm_fit'
plot(x, ...)
```

## Arguments

- fit:

  A `bayesqm_fit`.

- q:

  False-discovery level for the flag marks (default 0.05).

- x, ...:

  A `bayesqm_fit` and arguments passed on.

## Value

`fit`, invisibly.
