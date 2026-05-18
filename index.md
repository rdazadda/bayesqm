# bayesqm

**Bayesian Q methodology: probabilistic factor analysis for the study of
subjective opinions.**

`bayesqm` is the first fully Bayesian framework for Q-methodology factor
analysis. Since Stephenson (1935), Q analysis has relied on frequentist
factor extraction with the standard error rule of Brown (1980), which
returns participant-to-factor assignments as binary flagged / unflagged
decisions and offers no measure of uncertainty about them. `bayesqm`
replaces that with posterior credible intervals for every loading,
probabilistic factor membership P(dominant_i = k \| Y) that makes
cross-loading visible and quantifiable, and a principled K-selection
protocol built on element-wise PSIS-LOO. The model uses a Student-t
likelihood for robustness to idiosyncratic Q-sorts and resolves
rotational, sign, and label-permutation ambiguity through the MatchAlign
post-processing of Poworoznek et al. (2025). Posterior sampling is via
Stan (cmdstanr or rstan).

## What the package gives you

For each Q-sort dataset, `bayesqm` returns three things classical Q
analysis cannot:

1.  **Posterior credible intervals for every participant loading**,
    replacing the binary flagged / unflagged classification of Brown
    1980. with a continuous measure of assignment certainty.
2.  **Probabilistic factor membership**, P(dominant_i = k \| Y), making
    cross-loading visible and quantifiable rather than forcing each
    participant onto a single factor.
3.  **A peak-plus-Sivula protocol for choosing K**, pairing the ELPD
    peak with the conservative parsimony diagnostic of Sivula et al.
    2025. and surfacing the gap between them as informative about how
          strongly the data discriminate adjacent models.

## Installation

``` r

# install.packages("remotes")
remotes::install_github("rdazadda/bayesqm")
```

### Stan backend

`bayesqm` fits models with Stan and needs a working backend: `cmdstanr`
(recommended) or `rstan`.

`cmdstanr` is not on CRAN and is installed from the Stan R-universe.
CmdStan itself must then be installed separately:

``` r

install.packages("cmdstanr", repos = c("https://stan-dev.r-universe.dev", getOption("repos")))
cmdstanr::check_cmdstan_toolchain(fix = TRUE)
cmdstanr::install_cmdstan()
cmdstanr::cmdstan_version()   # verify
```

On Windows you also need Rtools; on macOS, the Xcode command-line tools
(`xcode-select --install`). See the Getting Started vignette for the
full setup walkthrough and the `rstan` alternative.

## Minimal workflow

``` r

library(bayesqm)
qdata <- read_qsort("mystudy.csv")
fit   <- fit_bayesian(qdata, K = 3)
fit
```

[`read_qsort()`](https://rdazadda.github.io/bayesqm/reference/read_qsort.md)
auto-detects CSV, Excel (including HTMLQ, FlashQ, and tablet-export
variants), PQMethod `.DAT`, Ken-Q JSON or multi-sheet Excel, KADE ZIP,
and Easy-HTMLQ Firebase JSON.

[`fit_bayesian()`](https://rdazadda.github.io/bayesqm/reference/fit_bayesian.md)
returns an object of class `bayesqm_fit`. Standard R accessors work as
expected: [`coef()`](https://rdrr.io/r/stats/coef.html),
[`fitted()`](https://rdrr.io/r/stats/fitted.values.html),
[`residuals()`](https://rdrr.io/r/stats/residuals.html),
[`sigma()`](https://rdrr.io/r/stats/sigma.html),
[`nobs()`](https://rdrr.io/r/stats/nobs.html),
[`family()`](https://rdrr.io/r/stats/family.html),
[`as.matrix()`](https://rdrr.io/r/base/matrix.html),
[`summary()`](https://rdrr.io/r/base/summary.html),
[`plot()`](https://rdrr.io/r/graphics/plot.default.html), plus
`posterior_interval()` and `prior_summary()` from the `rstantools` API.

## Choosing K

``` r

run <- run_bayes(qdata, K_max = 5)
plot_elpd(run)
```

[`run_bayes()`](https://rdazadda.github.io/bayesqm/reference/run_bayes.md)
fits the model for K = 1..K_max and reports two summaries:

- The **ELPD peak**: argmax of the expected log pointwise predictive
  density via element-wise PSIS-LOO (Vehtari, Gelman, & Gabry, 2017).
- The **Sivula parsimony diagnostic** (Sivula et al., 2025): a
  sequential rule that accepts a more complex K only when ΔELPD \> 4 and
  \|ΔELPD\| / SE(Δ) \> 2.

The `$case` field labels their relationship as `agree`, `gap`, or
`reversed`. The ELPD peak is always the adopted K; the case label
indicates how confidently the data discriminate between adjacent models,
and a gap between the two is itself diagnostic information.

## Probabilistic factor membership

Rather than dichotomizing each loading into flagged or unflagged,
`bayesqm` reports the posterior probability that factor k is participant
i’s dominant factor, P(dominant_i = k \| Y).
[`compute_dominant_sign()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-membership.md)
adds the posterior probability that the dominant loading is positive, so
negative exemplars (a viewpoint held by opposition) stay distinct.
[`classify_membership()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-membership.md)
turns the probabilities into a descriptive Strong / Moderate / Weak
tier:

``` r

compute_dominant_prob(fit$Lambda_draws)
compute_dominant_sign(fit$Lambda_draws)
classify_membership(fit$Lambda_draws)
plot_membership(fit)
```

Distinguishing and consensus statements come from the posterior of an
explicit viewpoint-divergence measure `D_j`, with the probabilities
`P(D_j > delta | Y)` and `P(D_j < delta | Y)` it implies. `delta` is
computed by default as the Bayesian reliability-adjusted critical
difference
([`critical_delta()`](https://rdazadda.github.io/bayesqm/reference/critical_delta.md));
[`suggest_delta()`](https://rdazadda.github.io/bayesqm/reference/suggest_delta.md)
(one forced-distribution category) is an alternative:

``` r

d <- critical_delta(fit$Lambda_draws)   # default separation (computed)
compute_divergence(fit$F_draws, delta = d)
plot_dist_cons(fit)                 # uses the fit's stored divergence summary
```

## Plotting

The package provides nine base-R plots and matching
[`ggplot2::autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
methods (registered when `ggplot2` and `ggdist` are installed). All read
their palette through
[`bayesqm_colors()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-colors.md)
and restore [`par()`](https://rdrr.io/r/graphics/par.html) on exit:

``` r

plot(fit)                       # cross-panel z-score dotchart
plot_loading_posterior(fit)     # loadings with 50% / 95% intervals
plot_membership(fit)            # dominant-factor probability heatmap
plot_dist_cons(fit)             # distinguishing/consensus divergence forest
plot_ppc(fit)                   # posterior predictive check on by-person correlations
plot_tucker(fit)                # MatchAlign alignment quality
plot_hyper(fit)                 # hyperparameter posteriors
plot_elpd(run)                  # ELPD across K with peak / Sivula annotations
```

For figure export,
[`save_bayesqm_plot()`](https://rdazadda.github.io/bayesqm/reference/save_bayesqm_plot.md)
opens the appropriate device from the file extension and
[`caption_bayesqm()`](https://rdazadda.github.io/bayesqm/reference/caption_bayesqm.md)
returns a figure caption that reports K, N, J, chains, coverage
probability, and convergence diagnostics.

## Compatibility with `qmethod`

`bayesqm_fit` deliberately mirrors the slot names from the `qmethod`
package (Zabala, 2015): `$dataset`, `$loa`, `$zsc`, `$zsc_n`, `$f_char`,
`$qdc`, `$flagged`. `$qdc` is a Bayesian divergence summary (posterior
median and 95% CrI of `D_j`, with `pi_D` and `pi_C`), not the classical
significance-label vocabulary. Intentional Bayesian divergences are
documented in `?bayesqm-package`:

- `$flagged` is defined probabilistically as P(argmax_k \|λ_ik\| = k) \>
  0.5, replacing Brown’s (1980) significance-based rule.
- `$f_char$characteristics` omits the classical test-theory columns;
  factor-score uncertainty is already in the posterior credible
  intervals on `$ci_lower` and `$ci_upper`.

When you have substantive factor labels,
`rename_factors(fit, c("a", "b", "c"))` relabels every factor-indexed
slot in one call.

## Integration with `posterior` and `bayesplot`

`as.matrix(fit)`, `as.array(fit)`, and `as.data.frame(fit)` return draws
in Stan-style parameter naming (`Lambda[i,k]`, `F[j,k]`, `nu`, `sigma`,
`tau`). `as_draws_df()`, `as_draws_matrix()`, and `as_draws_array()` are
registered for `posterior::as_draws_*` when `posterior` is installed, so
`bayesplot` and `tidybayes` consume `bayesqm_fit` objects natively.

## Citing the package

``` r

citation("bayesqm")
```

## Where to look next

- [`vignette("bayesqm-intro")`](https://rdazadda.github.io/bayesqm/articles/bayesqm-intro.md)
  walks the full workflow end to end on a synthetic Q-sort.
- [`?fit_bayesian`](https://rdazadda.github.io/bayesqm/reference/fit_bayesian.md)
  documents every prior and sampler option.
- [`?run_bayes`](https://rdazadda.github.io/bayesqm/reference/run_bayes.md)
  covers the peak-plus-Sivula thresholds and the three case labels.
- `?bayesqm-membership` covers the probabilistic membership and
  distinguishing-statement summaries.
- Issues and feature requests:
  <https://github.com/rdazadda/bayesqm/issues>.

## License

Released under the GNU General Public License version 3 (GPL-3); see
<https://www.gnu.org/licenses/gpl-3.0.html> for the full text.
