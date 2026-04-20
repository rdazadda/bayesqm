# Hyperparameter posterior densities

One panel per scalar hyperparameter (default `nu`, `sigma`, `tau`)
showing a two-tone kernel density: the full posterior in the light
shade, the central credible interval re-shaded in the mid shade, and the
posterior median marked by a short tick at the baseline. Coverage
defaults to `fit$brief$prob`. When a parameter's support spans more than
one order of magnitude (`max / min > 20`, all positive), the x-axis is
automatically rendered on a log scale so the density shape is not
crushed against the lower bound.

## Usage

``` r
plot_hyper(fit, pars = c("nu", "sigma", "tau"), log = NULL, ...)
```

## Arguments

- fit:

  A `bayesqm_fit`.

- pars:

  Character vector of hyperparameter names to show.

- log:

  `NULL` (default) auto-detects per parameter; set to `"x"` to force
  log, or `""` to force linear.

- ...:

  Additional arguments forwarded to
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html).

## Value

The input, invisibly.
