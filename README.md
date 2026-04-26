# bayesqm

<!-- badges: start -->
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

**Bayesian Q methodology: probabilistic factor analysis for the study
of subjectivity.**

`bayesqm` is the first fully Bayesian framework for Q-methodology
factor analysis. Since Stephenson (1935), Q analysis has relied on
frequentist factor extraction with the standard error rule of Brown
(1980), which returns participant-to-factor assignments as binary
flagged / unflagged decisions and offers no measure of uncertainty
about them. `bayesqm` replaces that with posterior credible intervals
for every loading, probabilistic factor membership P(dominant_i = k | Y)
that makes cross-loading visible and quantifiable, and a principled
K-selection protocol built on element-wise PSIS-LOO. The model uses a
Student-t likelihood for robustness to idiosyncratic Q-sorts and
resolves rotational, sign, and label-permutation ambiguity through
the MatchAlign post-processing of Poworoznek et al. (2025). Posterior
sampling is via Stan (cmdstanr or rstan).

## What the package gives you

For each Q-sort dataset, `bayesqm` returns three things classical Q
analysis cannot:

1. **Posterior credible intervals for every participant loading**,
   replacing the binary flagged / unflagged classification of Brown
   (1980) with a continuous measure of assignment certainty.
2. **Probabilistic factor membership**, P(dominant_i = k | Y), making
   cross-loading visible and quantifiable rather than forcing each
   participant onto a single factor.
3. **A peak-plus-Sivula protocol for choosing K**, pairing the ELPD
   peak with the conservative parsimony diagnostic of Sivula et al.
   (2025) and surfacing the gap between them as informative about how
   strongly the data discriminate adjacent models.

## Installation

A Stan backend is required. Install `cmdstanr` or `rstan`, then:

```r
# install.packages("remotes")
remotes::install_github("rdazadda/bayesqm")
```

## Minimal workflow

```r
library(bayesqm)
qdata <- read_qsort("mystudy.csv")
fit   <- fit_bayesian(qdata, K = 3)
fit
```

`read_qsort()` auto-detects CSV, Excel (including HTMLQ, FlashQ, and
tablet-export variants), PQMethod `.DAT`, Ken-Q JSON or multi-sheet
Excel, KADE ZIP, and Easy-HTMLQ Firebase JSON.

`fit_bayesian()` returns an object of class `bayesqm_fit`. Standard R
accessors work as expected: `coef()`, `fitted()`, `residuals()`,
`sigma()`, `nobs()`, `family()`, `as.matrix()`, `summary()`,
`plot()`, plus `posterior_interval()` and `prior_summary()` from the
`rstantools` API.

## Choosing K

```r
run <- run_bayes(qdata, K_max = 5)
plot_elpd(run)
```

`run_bayes()` fits the model for K = 1..K_max and reports two
summaries:

- The **ELPD peak**: argmax of the expected log pointwise predictive
  density via element-wise PSIS-LOO (Vehtari, Gelman, & Gabry, 2017).
- The **Sivula parsimony diagnostic** (Sivula et al., 2025): a
  sequential rule that accepts a more complex K only when ΔELPD > 4
  and |ΔELPD| / SE(Δ) > 2.

The `$case` field labels their relationship as `agree`, `gap`, or
`reversed`. The ELPD peak is always the adopted K; the case label
tells the reader how confidently the data discriminate between
adjacent models, and the gap, when present, is itself a reportable
finding rather than something to paper over.

## Probabilistic factor membership

Membership is summarized at three levels of resolution:

```r
compute_threshold_prob(fit$Lambda_draws, threshold = 1.96 / sqrt(fit$brief$J))
compute_dominant_prob(fit$Lambda_draws)
classify_membership(fit$Lambda_draws)   # Strong / Moderate / Weak tiers
plot_membership(fit)
```

Distinguishing and consensus statements use posterior probabilities of
pairwise factor-score separations rather than thresholded standard
errors:

```r
compute_distinguishing_prob(fit$F_draws, delta = 1.0)
compute_consensus_prob(fit$F_draws, delta = 1.0)
plot_dist_cons(fit, delta = 1.0)
```

## Plotting

The package provides nine base-R plots and matching
`ggplot2::autoplot()` methods (registered when `ggplot2` and `ggdist`
are installed). All read their palette through `bayesqm_colors()` and
restore `par()` on exit:

```r
plot(fit)                       # cross-panel z-score dotchart
plot_loading_posterior(fit)     # loadings with 50% / 95% intervals
plot_membership(fit)            # dominant-factor probability heatmap
plot_dist_cons(fit)             # distinguishing-statement probability
plot_ppc(fit)                   # posterior predictive check on by-person correlations
plot_tucker(fit)                # MatchAlign alignment quality
plot_hyper(fit)                 # hyperparameter posteriors
plot_elpd(run)                  # ELPD across K with peak / Sivula annotations
```

For figure export, `save_bayesqm_plot()` opens the appropriate device
from the file extension and `caption_bayesqm()` returns a
ready-to-paste figure caption that reports K, N, J, chains, coverage
probability, and convergence diagnostics.

## Compatibility with `qmethod`

`bayesqm_fit` deliberately mirrors the slot names from the `qmethod`
package (Zabala, 2014): `$dataset`, `$loa`, `$zsc`, `$zsc_n`,
`$f_char`, `$qdc`, `$flagged`. It uses the same
distinguishing-statement vocabulary (`"Distinguishes all"`,
`"Consensus"`, `"Distinguishes f1, f3"`, `""`). Scripts written
against `qmethod` largely keep working. Intentional Bayesian
divergences are documented in `?bayesqm-package`:

- `$flagged` is defined probabilistically as
  P(argmax_k |λ_ik| = k) > 0.5, replacing Brown's (1980)
  significance-based rule.
- `$f_char$characteristics` omits the classical test-theory columns;
  factor-score uncertainty is already in the posterior credible
  intervals on `$ci_lower` and `$ci_upper`.

When you have substantive factor labels,
`rename_factors(fit, c("a", "b", "c"))` relabels every
factor-indexed slot in one call.

## Integration with `posterior` and `bayesplot`

`as.matrix(fit)`, `as.array(fit)`, and `as.data.frame(fit)` return
draws in Stan-style parameter naming (`Lambda[i,k]`, `F[j,k]`,
`nu`, `sigma`, `tau`). `as_draws_df()`, `as_draws_matrix()`, and
`as_draws_array()` are registered for `posterior::as_draws_*` when
`posterior` is installed, so `bayesplot` and `tidybayes` consume
`bayesqm_fit` objects natively.

## Citing the package

```r
citation("bayesqm")
```

## Where to look next

- `vignette("bayesqm-intro")` walks the full workflow end to end on
  a reproducible synthetic Q-sort.
- `?fit_bayesian` documents every prior and sampler option.
- `?run_bayes` covers the peak-plus-Sivula thresholds and the three
  case labels.
- `?bayesqm-membership` covers the probabilistic membership and
  distinguishing-statement summaries.
- Issues and feature requests:
  <https://github.com/rdazadda/bayesqm/issues>.

## License

Released under the MIT license; see [LICENSE](LICENSE) for the full
text.
