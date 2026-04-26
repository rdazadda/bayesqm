# ggplot2 renderings of a bayesqm_run

Generic
[`ggplot2::autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
method for `bayesqm_run`. Dispatches to
[`make_elpd_diff()`](https://rdazadda.github.io/bayesqm/reference/make_elpd_diff.md)
when `type = "elpd"` (default) and
[`make_ppc_ridge()`](https://rdazadda.github.io/bayesqm/reference/make_ppc_ridge.md)
when `type = "ppc"`.

## Usage

``` r
autoplot.bayesqm_run(object, type = c("elpd", "ppc"), ...)
```

## Arguments

- object:

  A `bayesqm_run`.

- type:

  One of `"elpd"` or `"ppc"`.

- ...:

  Passed to the underlying figure function (e.g. `adopted`, `title`).

## Value

A `ggplot` object.
