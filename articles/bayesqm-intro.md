# Getting started with bayesqm

This vignette walks through one Q study end to end in **bayesqm**:
import, fit, diagnose, interpret, select K, and export. The structure
mirrors the classical `qmethod` workflow so readers can map every step
onto its Bayesian analogue.

``` r
library(bayesqm)
```

Building this vignette with live output

Stan-fitting chunks are gated on `BAYESQM_BUILD_VIGNETTE`. To rebuild
with real posterior output, set the environment variable and rebuild:

``` r
Sys.setenv(BAYESQM_BUILD_VIGNETTE = "true")
devtools::build_vignettes()
```

On CRAN machines the variable is unset, so the document compiles quickly
without a Stan backend.

## The Q-sort data

A Q study asks each participant to rank-order a set of statements into a
forced distribution. `bayesqm` represents that as a `J × N` numeric
matrix (statements as rows, participants as columns) plus a vector of
forced-distribution counts.

``` r
set.seed(1)
sim <- generate_data(N = 30, J = 33, K = 3, seed = 1)

qdata <- qsort_data(sim$Y, distribution = sim$distribution,
                    source = "simulated")
qdata
```

For real studies,
[`read_qsort()`](https://rdazadda.github.io/bayesqm/reference/read_qsort.md)
auto-detects the file format:

``` r
qdata <- read_qsort("mystudy.csv")          # CSV / Excel / HTMLQ / FlashQ
qdata <- read_qsort("mystudy.DAT")          # PQMethod
qdata <- read_qsort("mystudy.zip")          # KADE project
```

`qmethod` users can use the dotted aliases instead:
[`import.pqmethod()`](https://rdazadda.github.io/bayesqm/reference/import-aliases.md),
[`import.htmlq()`](https://rdazadda.github.io/bayesqm/reference/import-aliases.md),
[`import.kenq()`](https://rdazadda.github.io/bayesqm/reference/import-aliases.md),
[`import.easyhtmlq()`](https://rdazadda.github.io/bayesqm/reference/import-aliases.md).

## Fitting the model

[`fit_bayesian()`](https://rdazadda.github.io/bayesqm/reference/fit_bayesian.md)
samples the posterior of a low-rank factor model with a Student-t
likelihood (by default) and a hierarchical normal prior on the loadings,
then resolves rotational ambiguity with MatchAlign.

``` r
fit <- fit_bayesian(qdata, K = 3, chains = 4, iter = 2000,
                    warmup = 1000, seed = 1)
fit
```

`summary(fit)` adds factor characteristics, the PSIS-LOO ELPD,
distinguishing-statement counts, and the MatchAlign diagnostic.

## Diagnostics

Convergence statistics are stored on pre-alignment draws and printed in
the fit header. They are also available programmatically:

``` r
fit$diagnostics
```

[`plot_tucker()`](https://rdazadda.github.io/bayesqm/reference/plot_tucker.md)
visualises the per-draw Tucker’s phi between each aligned factor column
and the MatchAlign pivot. Values near 1 indicate a stable alignment;
bimodality signals residual label-switching.

``` r
plot_tucker(fit)
```

## Factor loadings

Each participant has a posterior distribution over their loading on
every factor.
[`plot_loading_posterior()`](https://rdazadda.github.io/bayesqm/reference/plot_loading_posterior.md)
draws the canonical loading forest, with nested 50 % and 95 %
credible-interval whiskers and the classical Brown cut-off
`1.96 / sqrt(J)` as a faint reference. Filled points are participants
with `P(factor k dominant) > 0.5`.

``` r
plot_loading_posterior(fit)
```

The same information as a tidy data frame:

``` r
head(compute_loadings(fit$Lambda_draws, prob = 0.95))
```

## Factor z-scores

[`plot()`](https://rdrr.io/r/graphics/plot.default.html) gives a
cross-panel z-score dotchart; rows share an order (by factor 1’s
posterior mean, configurable via `sort_by`) so the reader can scan
horizontally to compare factors.

``` r
plot(fit)
```

For a single statement across all factors,
[`plot_zscore_posterior()`](https://rdazadda.github.io/bayesqm/reference/plot_zscore_posterior.md)
gives the drill-down:

``` r
plot_zscore_posterior(fit, statement = 1)
```

## Choosing K

[`run_bayes()`](https://rdazadda.github.io/bayesqm/reference/run_bayes.md)
fits the model for each K in a range and applies the
**peak-plus-Sivula** protocol: the ELPD peak is the automated choice;
the Sivula (2025) parsimony rule is reported alongside.

``` r
run <- run_bayes(qdata, K_max = 4, seed = 1,
                 chains = 2, iter = 1500, warmup = 800)
```

``` r
run
```

``` r
plot_elpd(run)
```

The `run$case` field labels this relationship. When both methods pick
the same K, the case is `agree` and the data supports that K
unambiguously. When the ELPD peak exceeds the Sivula choice, the case is
`gap`: the richer model fits a bit better on LOO but not decisively, and
the choice between them should turn on substantive evidence. When Sivula
picks a larger K than the peak (`reversed`), something has usually gone
wrong in the ELPD comparison itself; this case is rare in practice and
should not be read as a substantive finding.

## Distinguishing, consensus, and membership

`bayesqm` replaces the classical z-score test with a direct posterior
probability. For every statement and every factor pair,
`P(|f_jk − f_jl| > δ)` answers *how confidently do the factors separate
this statement?* The default `δ = 1` is on the standardised factor-score
scale.

``` r
head(fit$qdc[, 1:4])
```

``` r
plot_dist_cons(fit, delta = 1.0)
```

Participant-level membership is also probabilistic.
[`classify_membership()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-membership.md)
turns posterior dominance into a `Strong / Moderate / Weak` tier:

``` r
head(classify_membership(fit$Lambda_draws))
```

``` r
plot_membership(fit)
```

## Posterior predictive check

[`plot_ppc()`](https://rdazadda.github.io/bayesqm/reference/plot_ppc.md)
shows the posterior distribution of the RMSE between `cor(Y_rep)` and
`cor(Y_obs)`. A well-specified model puts most mass at small RMSE.

``` r
plot_ppc(fit)
```

## Reporting and exporting

[`save_bayesqm_plot()`](https://rdazadda.github.io/bayesqm/reference/save_bayesqm_plot.md)
writes any plot to PDF / SVG / PNG / TIFF / JPEG at journal-appropriate
dimensions:

``` r
save_bayesqm_plot("fig_loadings.pdf", plot_loading_posterior(fit))
save_bayesqm_plot("fig_elpd.pdf",      plot_elpd(run),
                  width = 3.5, height = 3)
```

[`caption_bayesqm()`](https://rdazadda.github.io/bayesqm/reference/caption_bayesqm.md)
returns a ready-to-paste figure caption with model configuration, sample
sizes, interval probability, and convergence diagnostics:

``` r
caption_bayesqm(fit)
```

Standard R accessors work on the fit (`coef`, `fitted`, `residuals`,
`sigma`, `family`, `as.matrix`), and `as.matrix(fit)` returns a `T × P`
Stan-style draws matrix that `posterior` and `bayesplot` consume
natively.

## Renaming factors and theming

Substantive factor labels replace `f1..fK` in every slot:

``` r
fit <- rename_factors(fit, c("tradition", "innovation", "caution"))
plot(fit)
```

Every plot reads its palette through
[`bayesqm_colors()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-colors.md);
switch the scheme once and every subsequent plot follows:

``` r
bayesqm_set_colors("teal")     # or "blue" / "red" / "purple" / "grey"
plot(fit)
bayesqm_set_colors("blue")     # restore default
```

## Where next

- [`?fit_bayesian`](https://rdazadda.github.io/bayesqm/reference/fit_bayesian.md)
  — every prior and sampler option
- [`?run_bayes`](https://rdazadda.github.io/bayesqm/reference/run_bayes.md)
  — peak-plus-Sivula thresholds
- `?bayesqm-membership` — the full set of membership summaries
- [`ggplot2::autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  — ggplot2 / ggdist versions of every view above, when `ggplot2` and
  `ggdist` are installed
