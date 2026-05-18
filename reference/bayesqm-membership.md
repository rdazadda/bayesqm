# Probabilistic factor-membership and divergence summaries

Posterior summaries of factor membership and statement interpretation,
each computed entirely from posterior draws:

- `compute_threshold_prob()` returns the `N x K` posterior probability
  that `|lambda_ik| > threshold`, i.e. the Bayesian version of the
  Brown (1980) flagging rule.

- `compute_dominant_prob()` returns the `N x K` posterior probability
  that factor `k` is the dominant factor for participant `i`.

- `compute_dominant_sign()` returns the length-`N` posterior probability
  that the dominant loading is positive; participants with probability
  below 0.5 are negative exemplars.

- `compute_divergence()` returns the posterior of the viewpoint
  divergence `D_j` for every statement, together with the distinguishing
  and consensus probabilities it implies.

- `classify_membership()` turns dominant probabilities into a
  per-participant descriptive tier (Strong / Moderate / Weak).

## Usage

``` r
compute_threshold_prob(Lambda_draws, threshold)

compute_dominant_prob(Lambda_draws)

compute_dominant_sign(Lambda_draws)

compute_divergence(F_draws, delta = NULL, delta_grid = NULL)

classify_membership(Lambda_draws, strong = 0.8, moderate = 0.6)
```

## Arguments

- Lambda_draws:

  Array of shape `[T, N, K]` of aligned loading draws.

- threshold:

  Numeric threshold; a natural default is `1.96 / sqrt(J)` for the Brown
  rule.

- F_draws:

  Array of shape `[T, J, K]` of aligned factor-score draws.

- delta:

  Substantive separation for the distinguishing and consensus
  probabilities. The fit pipeline supplies the default, the
  reliability-adjusted critical difference of
  [`critical_delta()`](https://rdazadda.github.io/bayesqm/reference/critical_delta.md);
  [`suggest_delta()`](https://rdazadda.github.io/bayesqm/reference/suggest_delta.md)
  is an alternative. If `NULL` the `D_j` posterior (median, 95% CrI,
  `g_jk`) is still returned but the distinguishing/consensus
  probabilities are `NA`.

- delta_grid:

  Optional numeric vector of `delta` values for a sensitivity sweep.

- strong, moderate:

  Tier cutoffs on `max P(dominant)` (defaults 0.80 and 0.60).

## Value

`compute_threshold_prob()` and `compute_dominant_prob()` return `N x K`
matrices. `compute_dominant_sign()` returns a length-`N` named vector.
`compute_divergence()` returns a list (see Details).
`classify_membership()` returns a data frame.

## Details

For statement `j` with standardized viewpoint scores
`f_{j1}, ..., f_{jK}`, the divergence estimand is the mean absolute
pairwise difference `D_j = 2 / (K (K - 1)) * sum_{k < l} |f_jk - f_jl|`.
The mean is used rather than the maximum, which is an order statistic
over the `K (K - 1) / 2` contrasts and is inflated when the posterior is
diffuse. `compute_divergence()` reports the posterior median and central
95% credible interval of `D_j`, `pi_D = P(D_j > delta | Y)`
(distinguishing) and `pi_C = P(D_j < delta | Y) = 1 - pi_D` (consensus),
and the per-viewpoint departure `g_jk = f_jk - mean_{l != k} f_jl` with
its dominant viewpoint, sign, and `P(|g_jk| > delta | Y)`. The
probabilities are the reported quantities; no fixed probability cutoff
defines a distinguishing or consensus statement.
