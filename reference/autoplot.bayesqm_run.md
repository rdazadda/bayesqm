# ggplot2 rendering of the ELPD curve for a bayesqm_run

[`ggplot2::autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
method for a `bayesqm_run`. Draws ELPD against K with +/- 1.96 SE
whiskers and peak / Sivula markers.

## Usage

``` r
# S3 method for class 'bayesqm_run'
autoplot(object, ...)
```

## Arguments

- object:

  A `bayesqm_run`.

- ...:

  Ignored.

## Value

A `ggplot` object.
