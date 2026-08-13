# Continue sampling a fitted chain

Warm-extends the fitted chain by further iterations and re-runs the
convergence gate and the alignment on the grown draw set. The extension
restores the sampler's saved random-number state, so the result is
draw-for-draw identical to having run one longer chain, whatever
happened in the session in between.

## Usage

``` r
extend(fit, iterations = NULL, pivot = NULL, quiet = FALSE)
```

## Arguments

- fit:

  A `bayesqm_fit` created with `keep_raw = TRUE`.

- iterations:

  Additional iterations; `NULL` (the default) doubles the chain. Must be
  a multiple of the fit's `thin`.

- pivot, quiet:

  As in
  [`fit_bayesian()`](https://rdazadda.github.io/bayesqm/reference/fit_bayesian.md).

## Value

The extended `bayesqm_fit`.
