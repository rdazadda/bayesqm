# Getting started with bayesqm

This vignette walks through one Q study end to end in **bayesqm**:
import, fit, diagnose, interpret, select K, and export. The running
example is a 33-participant, 42-statement Q-sort generated with the
package’s data simulator so the vignette is reproducible without network
access or extra data files.

``` r
library(bayesqm)
library(ggplot2)
```

## The Q-sort data

A Q study asks each participant to rank-order a set of statements into a
forced distribution. `bayesqm` represents that as a `J × N` numeric
matrix (statements as rows, participants as columns) plus a vector of
forced-distribution counts.
[`read_qsort()`](https://rdazadda.github.io/bayesqm/reference/read_qsort.md)
auto-detects the file format:

``` r
qdata <- read_qsort("mystudy.csv")   # CSV / Excel / HTMLQ / FlashQ
qdata <- read_qsort("mystudy.DAT")   # PQMethod
qdata <- read_qsort("mystudy.zip")   # KADE project
```

For this vignette we generate a Q-sort dataset of 33 participants
ranking 42 statements:

``` r
sim   <- generate_data(N = 33, J = 42, K = 3, seed = 1)
qdata <- qsort_data(sim$Y, distribution = sim$distribution)
qdata
#> Q-sort data
#>   statements  : 42   participants : 33 
#>   distribution: 2 3 4 5 7 7 5 4 3 2   (sum = 42 )
#>   value range : [-5, 5]
#>   source      : manual
```

## Fitting the model

[`fit_bayesian()`](https://rdazadda.github.io/bayesqm/reference/fit_bayesian.md)
samples the posterior of a low-rank factor model with a Student-t
likelihood (by default) and a hierarchical normal prior on the loadings,
then resolves rotational ambiguity with MatchAlign:

``` r
fit <- fit_bayesian(qdata, K = 3, chains = 4, iter = 2000,
                    warmup = 1000, seed = 1)
```

``` r
fit <- demo_fit(N = 33, J = 42, K = 3, seed = 1)
fit
#> Bayesian Q-methodology factor model
#>   Call:      fit_bayesian(Y, K = K)
#>   Family:    Student-t (nu = estimated)
#>   Factors:   K = 3
#>   Data:      N = 33 persons, J = 42 statements
#>   Draws:     4 chains x 1000 post-warmup = 4000 total
#>   Backend:   demo
#>   Fitted:    2026-04-26 08:40:38
#>   Max Rhat:  1.010
#>   Min ESS:   bulk 820 / tail 950
#>   Divergent: 0
#> 
#> Factor loadings (posterior median [95% CI], first 10 of 33 persons):
#>     f1                  f2                  f3                 
#> P1  0.82 [0.66, 0.97]   -0.04 [-0.21, 0.12] 0.02 [-0.15, 0.19] 
#> P2  -0.09 [-0.24, 0.07] 0.74 [0.58, 0.91]   0.13 [-0.03, 0.29] 
#> P3  0.04 [-0.13, 0.19]  -0.12 [-0.30, 0.04] 0.60 [0.44, 0.77]  
#> P4  0.69 [0.53, 0.86]   -0.03 [-0.20, 0.12] 0.08 [-0.06, 0.24] 
#> P5  0.06 [-0.08, 0.21]  0.78 [0.63, 0.94]   -0.04 [-0.19, 0.11]
#> P6  0.13 [-0.02, 0.32]  -0.08 [-0.26, 0.08] 0.59 [0.42, 0.71]  
#> P7  0.67 [0.50, 0.82]   -0.04 [-0.19, 0.13] -0.15 [-0.32, 0.01]
#> P8  0.11 [-0.03, 0.25]  0.74 [0.59, 0.89]   -0.00 [-0.16, 0.15]
#> P9  -0.01 [-0.15, 0.12] -0.10 [-0.25, 0.04] 0.75 [0.60, 0.90]  
#> P10 0.68 [0.51, 0.83]   -0.12 [-0.27, 0.04] 0.06 [-0.08, 0.22] 
#>   ... (23 more; see fit$loa_median / fit$ci_lower / fit$ci_upper)
#> 
#> Hyperparameters:
#>  parameter mean median    sd lower upper
#>         nu 20.0   20.1 3.818 12.41 26.89
#>      sigma  0.5    0.5 0.083  0.34  0.67
#>        tau  0.5    0.5 0.082  0.34  0.66
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
#>   participant      f1_loa    f1_lower   f1_upper      f2_loa   f2_lower
#> 1          P1  0.82218583  0.65967029 0.97347665 -0.04267266 -0.2145922
#> 2          P2 -0.08886156 -0.24309784 0.07209832  0.74522036  0.5791526
#> 3          P3  0.03940137 -0.12972350 0.19405389 -0.12287342 -0.2986770
#> 4          P4  0.69365900  0.53025182 0.85839822 -0.03571152 -0.1965369
#> 5          P5  0.05989579 -0.07856949 0.21054518  0.78202658  0.6258714
#> 6          P6  0.12982142 -0.02363006 0.31509987 -0.08730420 -0.2556340
#>     f2_upper      f3_loa    f3_lower  f3_upper
#> 1 0.12335192  0.01982447 -0.14521623 0.1878235
#> 2 0.91064671  0.13579980 -0.02821464 0.2948461
#> 3 0.03507329  0.60443673  0.44105818 0.7671924
#> 4 0.12328690  0.08182326 -0.06409235 0.2354870
#> 5 0.93757307 -0.03495072 -0.19214191 0.1134495
#> 6 0.07939546  0.58198954  0.41551318 0.7077884
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

``` r
run <- demo_run(K_max = 5, k_peak = 3, k_sivula = 1, case = "gap")
run
#> Bayesian Q-methodology: multi-K comparison
#>   K range:      1..5
#>   ELPD peak:    K = 3  (automated adoption)
#>   Sivula rule:  K = 1  (parsimony diagnostic)
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
#> Case 'gap': k_peak is adopted; Sivula is reported as a parsimony diagnostic only.
```

``` r
make_elpd_diff(run)
```

![Delta-ELPD vs K = 1 with the Sivula rejection band at \|Delta-ELPD\|
\< 4. Red triangle marks the Sivula K, blue square marks the ELPD peak
(the adopted K).](bayesqm-intro_files/figure-html/elpd-1.png)

Delta-ELPD vs K = 1 with the Sivula rejection band at \|Delta-ELPD\| \<
4. Red triangle marks the Sivula K, blue square marks the ELPD peak (the
adopted K).

The ELPD peak is always the adopted K. Sivula is a pure diagnostic: a
number reported alongside the peak so readers can see how confidently
the data discriminate between adjacent models. The `run$case` field
labels the relationship between the two. When Sivula lands on the same K
as the peak, the case is `agree`. When Sivula points to a smaller K than
the peak, the case is `gap`. When Sivula exceeds the peak, the case is
`reversed` and usually indicates numerical instability in the comparison
itself. In every case the adopted K is the ELPD peak.

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
#> 3          P3               3             f3        1 Strong
#> 4          P4               1             f1        1 Strong
#> 5          P5               2             f2        1 Strong
#> 6          P6               3             f3        1 Strong
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
#> [1] "Bayesian Q-methodology factor model (K = 3, N = 33, J = 42); fitted with a Student-t likelihood via demo (4 chains, 4,000 post-warmup draws); intervals shown at 95% posterior coverage; max Rhat = 1.010, min bulk ESS = 820, 0 divergent transitions. Fitted with the bayesqm R package."
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

- [`?fit_bayesian`](https://rdazadda.github.io/bayesqm/reference/fit_bayesian.md):
  every prior and sampler option
- [`?run_bayes`](https://rdazadda.github.io/bayesqm/reference/run_bayes.md):
  peak-plus-Sivula thresholds
- `?bayesqm-membership`: the full set of membership summaries
- [`?rename_factors`](https://rdazadda.github.io/bayesqm/reference/rename_factors.md):
  relabel `f1..fK` with substantive factor names
- [`ggplot2::autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html):
  ggplot2 / ggdist versions of every view above, when `ggplot2` and
  `ggdist` are installed
