# bayesqm

A Bayesian implementation of Q-methodology factor analysis for R. The
factor model is sampled with Stan, rotational and sign ambiguity is
resolved by MatchAlign post-processing, and every quantity the
analysis produces (loadings, factor z-scores, distinguishing
statements, factor membership) is reported with posterior credible
intervals. The number of factors is chosen by PSIS-LOO, under a
peak-plus-Sivula protocol that reports both the ELPD-optimal K and
the more conservative parsimony choice.

## Installation

You need a Stan backend first, either `cmdstanr` or `rstan`. Then:

```r
# install.packages("remotes")
remotes::install_github("rdazadda/bayesqm")
```

## Using it

The basic workflow is three calls:

```r
library(bayesqm)
qdata <- read_qsort("mystudy.csv")
fit   <- fit_bayesian(qdata, K = 3)
```

`read_qsort()` handles the common Q-software file formats: CSV and
Excel (including HTMLQ, FlashQ, and tablet exports), PQMethod `.DAT`,
Ken-Q JSON and multi-sheet Excel, KADE ZIP, and Easy-HTMLQ Firebase
JSON.

`fit_bayesian()` returns an object of class `bayesqm_fit` that
behaves like any other modelling object in R: `print`, `summary`,
`coef`, `fitted`, `residuals`, `sigma`, `as.matrix`, and `plot`
all work as you would expect.

To choose the number of factors, fit across a range of K:

```r
run <- run_bayes(qdata, K_max = 5)
plot_elpd(run)
```

The `bayesqm_run` object adopts the ELPD peak as the chosen K and
reports the Sivula K alongside as a parsimony diagnostic. `run_bayes()`
labels the relationship between the two `agree`, `gap`, or `reversed`.
The peak is always the adopted K; the label tells the reader how
confidently the data discriminate between adjacent models.

The richer visual views for a single fit are:

```r
plot_loading_posterior(fit)   # loadings with 50 and 95 percent intervals
plot_membership(fit)          # dominant-factor probability heatmap
plot_dist_cons(fit)           # distinguishing-statement probability
plot_ppc(fit)                 # posterior predictive check
plot_tucker(fit)              # MatchAlign alignment quality
plot_hyper(fit)               # hyperparameter posteriors
```

These are all base-R plots; the package has no hard dependency on
ggplot2. If you have `ggplot2` and `ggdist` installed, an
`autoplot()` method is registered that renders the same views using
`stat_pointinterval` and `stat_halfeye`.

For figure export, `save_bayesqm_plot()` opens the right device from
the file extension, and `caption_bayesqm()` returns a ready-to-paste
figure caption that reports K, N, J, chains, coverage probability,
and convergence diagnostics.

## How it works

`bayesqm` samples a low-rank Bayesian factor model with Stan — a
Student-t likelihood by default, Normal optional — and resolves
rotational, sign, and label-permutation ambiguity with MatchAlign
post-processing. Every factor-analytic quantity is returned as
posterior draws: loadings, z-scores, and hyperparameters all carry
credible intervals rather than point estimates. Participant flagging
is the posterior probability that a factor is dominant for a given
participant; distinguishing statements are scored by
`P(|f_jk - f_jl| > δ)`; and the number of factors is chosen by the
ELPD peak under a peak-plus-Sivula protocol built on PSIS-LOO.

The fit stores everything on a small set of named slots: `$loa` for
posterior-mean loadings, `$ci_lower` / `$ci_upper` for credible
intervals, `$zsc` and `$zsc_n` for continuous and forced-distribution
factor scores, `$f_char` for factor characteristics, `$flagged` for
the dominance logical, and `$qdc` for the distinguishing-statement
table. Standard R accessors (`coef`, `fitted`, `residuals`, `sigma`,
`as.matrix`, `plot`) dispatch on the object, and the draws are also
exposed in a Stan-style matrix that `posterior` and `bayesplot`
consume natively.

## Where to look next

- `vignette("bayesqm-intro")` walks the full workflow on a
  simulated dataset.
- `?fit_bayesian` documents every prior and sampler option.
- `?run_bayes` covers the peak-plus-Sivula thresholds.
- Issues and feature requests:
  <https://github.com/rdazadda/bayesqm/issues>.

## License

Copyright &copy; 2026 Raymond Dacosta Azadda. Released under the MIT
license; see [LICENSE](LICENSE) for the full text.
