# ggplot2 renderings of a bayesqm_fit

Generic
[`ggplot2::autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
method for `bayesqm_fit`. Unlike the base-R
[`plot.bayesqm_fit()`](https://rdazadda.github.io/bayesqm/reference/plot.bayesqm_fit.md),
these renderings use
[`ggdist::stat_pointinterval`](https://mjskay.github.io/ggdist/reference/stat_pointinterval.html)
and
[`ggdist::stat_halfeye`](https://mjskay.github.io/ggdist/reference/stat_halfeye.html)
for publication-grade posterior summaries.

## Usage

``` r
# S3 method for class 'bayesqm_fit'
autoplot(
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

  Ignored.

## Value

A `ggplot` object.
