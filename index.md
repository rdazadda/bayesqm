# bayesqm

A Bayesian implementation of Q-methodology factor analysis for R. The
factor model is sampled with Stan, rotational and sign ambiguity is
resolved by MatchAlign post-processing, and every quantity the analysis
produces (loadings, factor z-scores, distinguishing statements, factor
membership) is reported with posterior credible intervals. The number of
factors is chosen by PSIS-LOO, under a peak-plus-Sivula protocol that
reports both the ELPD-optimal K and the more conservative parsimony
choice.

## Installation

You need a Stan backend first, either `cmdstanr` or `rstan`. Then:

``` r
# install.packages("remotes")
remotes::install_github("rdazadda/bayesqm")
```

## Using it

The basic workflow is three calls:

``` r
library(bayesqm)
qdata <- read_qsort("mystudy.csv")
fit   <- fit_bayesian(qdata, K = 3)
```

[`read_qsort()`](https://rdazadda.github.io/bayesqm/reference/read_qsort.md)
handles the common Q-software file formats: CSV and Excel (including
HTMLQ, FlashQ, and tablet exports), PQMethod `.DAT`, Ken-Q JSON and
multi-sheet Excel, KADE ZIP, and Easy-HTMLQ Firebase JSON.

[`fit_bayesian()`](https://rdazadda.github.io/bayesqm/reference/fit_bayesian.md)
returns an object of class `bayesqm_fit` that behaves like any other
modelling object in R: `print`, `summary`, `coef`, `fitted`,
`residuals`, `sigma`, `as.matrix`, and `plot` all work as you would
expect.

To choose the number of factors, fit across a range of K:

``` r
run <- run_bayes(qdata, K_max = 5)
plot_elpd(run)
```

The `bayesqm_run` object reports both the peak K (the ELPD-optimal
choice) and the Sivula K (the parsimony choice). When they agree, the
data supports that K unambiguously. When they disagree, the gap itself
is informative, and
[`run_bayes()`](https://rdazadda.github.io/bayesqm/reference/run_bayes.md)
labels the case `agree`, `gap`, or `reversed` in the summary.

The richer visual views for a single fit are:

``` r
plot_loading_posterior(fit)   # loadings with 50 and 95 percent intervals
plot_membership(fit)          # dominant-factor probability heatmap
plot_dist_cons(fit)           # distinguishing-statement probability
plot_ppc(fit)                 # posterior predictive check
plot_tucker(fit)              # MatchAlign alignment quality
plot_hyper(fit)               # hyperparameter posteriors
```

These are all base-R plots; the package has no hard dependency on
ggplot2. If you have `ggplot2` and `ggdist` installed, an `autoplot()`
method is registered that renders the same views using
`stat_pointinterval` and `stat_halfeye`.

For figure export,
[`save_bayesqm_plot()`](https://rdazadda.github.io/bayesqm/reference/save_bayesqm_plot.md)
opens the right device from the file extension, and
[`caption_bayesqm()`](https://rdazadda.github.io/bayesqm/reference/caption_bayesqm.md)
returns a ready-to-paste figure caption that reports K, N, J, chains,
coverage probability, and convergence diagnostics.

## Relationship to qmethod

The output object deliberately parallels `qmethod`’s. The slot names
(`$loa`, `$zsc`, `$zsc_n`, `$qdc`, `$f_char`, `$flagged`) are identical,
as is the `$qdc$dist.and.cons` vocabulary (“Distinguishes all”,
“Consensus”, “Distinguishes f1, f3”). Dotted import aliases
([`import.pqmethod()`](https://rdazadda.github.io/bayesqm/reference/import-aliases.md),
[`import.htmlq()`](https://rdazadda.github.io/bayesqm/reference/import-aliases.md),
[`import.kenq()`](https://rdazadda.github.io/bayesqm/reference/import-aliases.md),
[`import.easyhtmlq()`](https://rdazadda.github.io/bayesqm/reference/import-aliases.md))
forward to the same-named readers. Scripts written against `qmethod` can
usually be ported by changing one or two function calls.

The methodology is different where it has to be. `qmethod` does centroid
or PCA extraction, varimax rotation, Brown’s significance threshold for
flagging, a z-score test for distinguishing statements, and scree or
parallel analysis for choosing K. `bayesqm` replaces each of those with
its Bayesian analogue: a factor model sampled with Stan, MatchAlign for
rotational alignment, posterior dominance probability for flagging,
`P(|f_jk - f_jl| > δ)` for distinguishing, and peak-plus-Sivula ELPD for
K selection. Where the output shapes can be kept compatible, they are.

## Where to look next

- [`vignette("bayesqm-intro")`](https://rdazadda.github.io/bayesqm/articles/bayesqm-intro.md)
  walks the full workflow on a simulated dataset.
- [`?fit_bayesian`](https://rdazadda.github.io/bayesqm/reference/fit_bayesian.md)
  documents every prior and sampler option.
- [`?run_bayes`](https://rdazadda.github.io/bayesqm/reference/run_bayes.md)
  covers the peak-plus-Sivula thresholds.
- Issues and feature requests:
  <https://github.com/rdazadda/bayesqm/issues>.

## License

Copyright © 2026 Raymond Dacosta Azadda. Released under the MIT license;
see [LICENSE](https://rdazadda.github.io/bayesqm/LICENSE) for the full
text.
