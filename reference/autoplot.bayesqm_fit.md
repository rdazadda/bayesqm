# ggplot2 renderings of a bayesqm_fit

Generic
[`ggplot2::autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
method for `bayesqm_fit`. Dispatches to
[`make_dominant_panel()`](https://rdazadda.github.io/bayesqm/reference/make_dominant_panel.md)
when `type = "membership"`; uses
[`ggdist::stat_pointinterval`](https://mjskay.github.io/ggdist/reference/stat_pointinterval.html)
/ `stat_halfeye` for the remaining views.

## Usage

``` r
autoplot.bayesqm_fit(
  object,
  type = c("loadings", "zscores", "membership", "hyper", "zscore_posterior"),
  statement = NULL,
  ...
)
```

## Arguments

- object:

  A `bayesqm_fit`.

- type:

  One of `"loadings"`, `"zscores"`, `"membership"`, `"hyper"`, or
  `"zscore_posterior"`.

- statement:

  For `type = "zscore_posterior"`, an integer index or statement name.

- ...:

  Passed to the underlying figure function (e.g. `title`, `anonymize`
  for membership).

## Value

A `ggplot` object.
