# Getting started with bayesqm

This vignette walks through one Q study end to end in **bayesqm**:
import, fit, diagnose, interpret, select K, and export. The structure
mirrors the classical `qmethod` workflow so readers can map every step
onto its Bayesian analogue.

On your own machine, you would fit a real model with
[`fit_bayesian()`](https://rdazadda.github.io/bayesqm/reference/fit_bayesian.md)
via a Stan backend. For this document we work from a synthetic fit
produced by
[`demo_fit()`](https://rdazadda.github.io/bayesqm/reference/demo_fit.md)
so every plot and summary below renders without requiring Stan.

``` r
library(bayesqm)
library(ggplot2)
```

## The Q-sort data

A Q study asks each participant to rank-order a set of statements into a
forced distribution. `bayesqm` represents that as a `J × N` numeric
matrix (statements as rows, participants as columns) plus a vector of
forced-distribution counts. For a real study,
[`read_qsort()`](https://rdazadda.github.io/bayesqm/reference/read_qsort.md)
auto-detects the file format:

``` r
qdata <- read_qsort("mystudy.csv")   # CSV / Excel / HTMLQ / FlashQ
qdata <- read_qsort("mystudy.DAT")   # PQMethod
qdata <- read_qsort("mystudy.zip")   # KADE project
```

`qmethod` users can use the dotted aliases instead:
[`import.pqmethod()`](https://rdazadda.github.io/bayesqm/reference/import-aliases.md),
[`import.htmlq()`](https://rdazadda.github.io/bayesqm/reference/import-aliases.md),
[`import.kenq()`](https://rdazadda.github.io/bayesqm/reference/import-aliases.md),
[`import.easyhtmlq()`](https://rdazadda.github.io/bayesqm/reference/import-aliases.md).

For this vignette we simulate a dataset with
[`generate_data()`](https://rdazadda.github.io/bayesqm/reference/generate_data.md)
and wrap it with
[`qsort_data()`](https://rdazadda.github.io/bayesqm/reference/qsort_data.md):

``` r
set.seed(1)
sim   <- generate_data(N = 20, J = 22, K = 2, seed = 1)
qdata <- qsort_data(sim$Y, distribution = sim$distribution,
                    source = "simulated")
qdata
#> Q-sort data
#>   statements  : 22   participants : 20 
#>   distribution: 1 2 3 10 3 2 1   (sum = 22 )
#>   value range : [-3, 3]
#>   source      : simulated
```

## Fitting the model

On real data you would call
[`fit_bayesian()`](https://rdazadda.github.io/bayesqm/reference/fit_bayesian.md):

``` r
fit <- fit_bayesian(qdata, K = 2, chains = 4, iter = 2000,
                    warmup = 1000, seed = 1)
```

The function samples the posterior of a low-rank factor model with a
Student-t likelihood (by default) and a hierarchical normal prior on the
loadings, then resolves rotational ambiguity with MatchAlign. For this
vignette, we use the synthetic fit helper:

``` r
fit <- demo_fit(N = 20, J = 22, K = 2, seed = 1)
fit
#> Bayesian Q-methodology factor model
#>   Call:      fit_bayesian(Y, K = K)
#>   Family:    Student-t (nu = estimated)
#>   Factors:   K = 2
#>   Data:      N = 20 persons, J = 22 statements
#>   Draws:     4 chains x 1000 post-warmup = 4000 total
#>   Backend:   demo
#>   Fitted:    2026-04-24 22:21:54
#>   Max Rhat:  1.010
#>   Min ESS:   bulk 820 / tail 950
#>   Divergent: 0
#> 
#> Factor loadings (posterior median [95% CI], first 10 of 20 persons):
#>     f1                  f2                 
#> P1  0.72 [0.57, 0.87]   -0.04 [-0.22, 0.12]
#> P2  0.12 [-0.04, 0.29]  0.82 [0.67, 0.98]  
#> P3  0.73 [0.57, 0.91]   0.04 [-0.11, 0.21] 
#> P4  -0.13 [-0.30, 0.01] 0.61 [0.44, 0.77]  
#> P5  0.78 [0.62, 0.95]   -0.04 [-0.21, 0.11]
#> P6  0.00 [-0.16, 0.16]  0.85 [0.70, 1.00]  
#> P7  0.82 [0.69, 0.98]   0.08 [-0.07, 0.24] 
#> P8  -0.09 [-0.25, 0.07] 0.58 [0.43, 0.77]  
#> P9  0.56 [0.40, 0.72]   -0.04 [-0.21, 0.09]
#> P10 -0.03 [-0.21, 0.11] 0.65 [0.50, 0.82]  
#>   ... (10 more; see fit$loa_median / fit$ci_lower / fit$ci_upper)
#> 
#> Hyperparameters:
#>  parameter mean median    sd lower upper
#>         nu 19.7  19.68 3.709 12.24 26.49
#>      sigma  0.5   0.51 0.078  0.36  0.65
#>        tau  0.5   0.50 0.080  0.35  0.66
#> 
#> Use summary() for factor characteristics, distinguishing/consensus tables, and LOO.
```

`summary(fit)` adds factor characteristics, the PSIS-LOO ELPD (when
available), distinguishing-statement counts, and the MatchAlign
diagnostic.

## Diagnostics

Convergence statistics live in `fit$diagnostics`:

``` r
fit$diagnostics
#> $rhat_max
#> [1] 1.01
#> 
#> $ess_bulk
#> [1] 820
#> 
#> $ess_tail
#> [1] 950
#> 
#> $divergences
#> [1] 0
```

[`plot_tucker()`](https://rdazadda.github.io/bayesqm/reference/plot_tucker.md)
visualises the per-draw Tucker’s phi between each aligned factor column
and the MatchAlign pivot. Values near 1 indicate a stable alignment;
bimodality signals residual label-switching.

``` r
plot_tucker(fit)
```

![MatchAlign alignment quality by
factor.](bayesqm-intro_files/figure-html/tucker-1.png)

MatchAlign alignment quality by factor.

## Factor loadings

Each participant has a posterior distribution over their loading on
every factor.
[`plot_loading_posterior()`](https://rdazadda.github.io/bayesqm/reference/plot_loading_posterior.md)
draws the loading forest, with nested 50 percent and 95 percent
credible-interval whiskers and the classical Brown cut-off as a faint
reference. Filled points are participants with
`P(factor k dominant) > 0.5`.

``` r
plot_loading_posterior(fit)
```

![Loadings with nested 50% and 95% credible
intervals.](bayesqm-intro_files/figure-html/loadings-1.png)

Loadings with nested 50% and 95% credible intervals.

The same information as a tidy data frame:

``` r
head(compute_loadings(fit$Lambda_draws, prob = 0.95))
#>   participant       f1_loa   f1_lower   f1_upper      f2_loa   f2_lower
#> 1          P1  0.724465890  0.5694408 0.87365976 -0.04467776 -0.2181482
#> 2          P2  0.121618928 -0.0448359 0.28842984  0.82020002  0.6659145
#> 3          P3  0.735303416  0.5696475 0.90862653  0.04951714 -0.1133779
#> 4          P4 -0.131067733 -0.2999218 0.01401073  0.61150829  0.4357542
#> 5          P5  0.783273983  0.6190436 0.94517785 -0.04072197 -0.2082932
#> 6          P6 -0.001107792 -0.1624583 0.16479837  0.84841154  0.6952639
#>    f2_upper
#> 1 0.1218140
#> 2 0.9811106
#> 3 0.2096828
#> 4 0.7695044
#> 5 0.1125100
#> 6 1.0021064
```

## Factor z-scores

[`plot()`](https://rdrr.io/r/graphics/plot.default.html) gives a
cross-panel z-score dotchart; rows share an order (by factor 1’s
posterior mean, configurable via `sort_by`) so the reader can scan
horizontally to compare factors.

``` r
plot(fit)
```

![Posterior z-scores across factors with 50 / 95
CrIs.](bayesqm-intro_files/figure-html/zscores-1.png)

Posterior z-scores across factors with 50 / 95 CrIs.

For a single statement across factors,
[`plot_zscore_posterior()`](https://rdazadda.github.io/bayesqm/reference/plot_zscore_posterior.md)
gives the drill-down:

``` r
plot_zscore_posterior(fit, statement = 1)
```

![Posterior z-score for a single statement across
factors.](bayesqm-intro_files/figure-html/zscore-one-1.png)

Posterior z-score for a single statement across factors.

## Choosing K

[`run_bayes()`](https://rdazadda.github.io/bayesqm/reference/run_bayes.md)
fits the model for each K in a range and applies the
**peak-plus-Sivula** protocol: the ELPD peak is the automated choice;
the Sivula (2025) parsimony rule is reported alongside.

On real data you would call:

``` r
run <- run_bayes(qdata, K_max = 4, seed = 1,
                 chains = 2, iter = 1500, warmup = 800)
```

For this vignette we use a synthetic run produced by
[`demo_run()`](https://rdazadda.github.io/bayesqm/reference/demo_run.md):

``` r
run <- demo_run(K_max = 5, k_peak = 3, k_sivula = 2, case = "gap")
run
#> Bayesian Q-methodology: multi-K comparison
#>   K range:      1..5
#>   ELPD peak:    K = 3  (automated adoption)
#>   Sivula rule:  K = 2  (parsimony diagnostic)
#>   Case:         gap  (ELPD peak > Sivula (weak discrimination between adjacent models))
#> 
#> LOO comparison:
#>  K    elpd   se delta_elpd se_delta ratio
#>  1 -180.09 8.00                          
#>  2 -170.91 7.25      -9.18     3.00  3.06
#>  3 -165.42 6.50      -5.49     3.00  1.83
#>  4 -170.20 5.75       4.78     3.00  1.59
#>  5 -179.61 5.00       9.41     3.00  3.14
#> 
#> Case 'gap': adopt k_peak if corroborated by external evidence, else fall back to k_sivula for parsimony.
```

``` r
make_elpd_diff(run, adopted = 3)
```

![ΔELPD vs K = 1 with the Sivula rejection band (\|ΔELPD\| \< 4). Red
triangle marks the Sivula K, blue square the ELPD peak, orange diamond
the K adopted by the
analyst.](bayesqm-intro_files/figure-html/elpd-1.png)

ΔELPD vs K = 1 with the Sivula rejection band (\|ΔELPD\| \< 4). Red
triangle marks the Sivula K, blue square the ELPD peak, orange diamond
the K adopted by the analyst.

The ELPD peak is always the adopted K; Sivula is reported alongside so
readers can see how confidently the data discriminate between adjacent
models. The `run$case` field labels the relationship between the two.
When Sivula lands on the same K as the peak, the case is `agree` and the
decision is unambiguous. When Sivula points to a smaller K than the
peak, the case is `gap` — the peak is still adopted, but Sivula is
flagging that the marginal evidence for the extra factor is not
decisive, and that gap itself is worth reporting. The `reversed` case,
in which Sivula exceeds the peak, is rare and usually indicates
numerical instability in the ELPD comparison rather than a substantive
finding.

## Distinguishing, consensus, and membership

`bayesqm` replaces the classical z-score test with a direct posterior
probability. For every statement and every factor pair,
`P(|f_jk − f_jl| > δ)` answers *how confidently do the factors separate
this statement?* The default `δ = 1` is on the standardised factor-score
scale.

``` r
plot_dist_cons(fit, delta = 1.0)
```

![Distinguishing-statement probability. Rows sorted so the most
discriminating statements are at the
top.](bayesqm-intro_files/figure-html/dist-cons-1.png)

Distinguishing-statement probability. Rows sorted so the most
discriminating statements are at the top.

Participant-level membership is probabilistic too.
[`classify_membership()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-membership.md)
turns posterior dominance into a `Strong / Moderate / Weak` tier:

``` r
head(classify_membership(fit$Lambda_draws))
#>   participant dominant_factor dominant_label max_prob   tier
#> 1          P1               1             f1        1 Strong
#> 2          P2               2             f2        1 Strong
#> 3          P3               1             f1        1 Strong
#> 4          P4               2             f2        1 Strong
#> 5          P5               1             f1        1 Strong
#> 6          P6               2             f2        1 Strong
```

``` r
make_dominant_panel(fit)
```

![Blue tiles = posterior probability that each factor is dominant for a
given participant (values printed in each cell). The right column shows
the overall assignment verdict on an orange-red
scale.](bayesqm-intro_files/figure-html/membership-1.png)

Blue tiles = posterior probability that each factor is dominant for a
given participant (values printed in each cell). The right column shows
the overall assignment verdict on an orange-red scale.

## Posterior predictive check

[`plot_ppc()`](https://rdazadda.github.io/bayesqm/reference/plot_ppc.md)
shows the posterior distribution of the RMSE between `cor(Y_rep)` and
`cor(Y_obs)`. A well-specified model puts most mass at small RMSE.

``` r
plot_ppc(fit)
```

![PPC on the correlation
matrix.](bayesqm-intro_files/figure-html/ppc-1.png)

PPC on the correlation matrix.

## Hyperparameters

``` r
plot_hyper(fit)
```

![Posterior densities of nu, sigma, and
tau.](bayesqm-intro_files/figure-html/hyper-1.png)

Posterior densities of nu, sigma, and tau.

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
#> [1] "Bayesian Q-methodology factor model (K = 2, N = 20, J = 22); fitted with a Student-t likelihood via demo (4 chains, 4,000 post-warmup draws); intervals shown at 95% posterior coverage; max Rhat = 1.010, min bulk ESS = 820, 0 divergent transitions. Fitted with the bayesqm R package (Dacosta Azadda, 2026)."
```

Standard R accessors work on the fit (`coef`, `fitted`, `residuals`,
`sigma`, `family`, `as.matrix`), and `as.matrix(fit)` returns a
Stan-style draws matrix that `posterior` and `bayesplot` consume
natively.

## Theming

Every plot reads its palette through
[`bayesqm_colors()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-colors.md).
Switch the scheme once and every subsequent base-R plot follows:

``` r
bayesqm_set_colors("teal")   # "blue" (default), "red", "purple", "grey"
plot(fit)
bayesqm_set_colors("blue")
```

## Where next

- [`?fit_bayesian`](https://rdazadda.github.io/bayesqm/reference/fit_bayesian.md)
  — every prior and sampler option
- [`?run_bayes`](https://rdazadda.github.io/bayesqm/reference/run_bayes.md)
  — peak-plus-Sivula thresholds
- `?bayesqm-membership` — the full set of membership summaries
- [`?rename_factors`](https://rdazadda.github.io/bayesqm/reference/rename_factors.md)
  — relabel `f1..fK` with substantive factor names
- [`ggplot2::autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  — ggplot2 / ggdist versions of every view above, when `ggplot2` and
  `ggdist` are installed
