# Distinguishing/consensus divergence forest

Horizontal dot-and-whisker plot of the posterior viewpoint divergence
`D_j` for every statement: posterior median with a 95% credible-interval
whisker, statements ordered by the distinguishing probability
`P(D_j > delta | Y)`. A dashed rule marks the substantive separation
`delta` and each point is shaded by `P(D_j > delta | Y)`. By default the
divergence summary stored on the fit is used (computed at the fit's
`delta`); pass `delta` to recompute at a different separation without
refitting.

## Usage

``` r
plot_dist_cons(fit, delta = NULL, ...)
```

## Arguments

- fit:

  A `bayesqm_fit`.

- delta:

  Optional separation override. If `NULL` (default) the fit's stored
  summary (`fit$qdc`, at `fit$brief$delta`) is used; that default is the
  Bayesian reliability-adjusted critical difference
  ([`critical_delta()`](https://rdazadda.github.io/bayesqm/reference/critical_delta.md)).
  Pass a numeric value to recompute the divergence summary at a
  different separation.

- ...:

  Additional arguments forwarded to
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html).

## Value

The input, invisibly.
