# Probabilistic factor-membership summaries

The paper's Section 6 summaries, each computed entirely from posterior
draws:

- `compute_threshold_prob()` returns the `N x K` posterior probability
  that `|lambda_ik| > threshold`, i.e. the Bayesian version of the
  Brown (1980) flagging rule.

- `compute_dominant_prob()` returns the `N x K` posterior probability
  that factor `k` is the dominant factor for participant `i`.

- `compute_distinguishing_prob()` returns `P(|f_jk - f_jl| > delta)` for
  every pair of factors.

- `compute_consensus_prob()` returns the joint probability that *every*
  factor pair's separation stays below `delta`.

- `classify_membership()` turns dominant probabilities into a
  per-participant tier verdict (Strong / Moderate / Weak).

## Usage

``` r
compute_threshold_prob(Lambda_draws, threshold)

compute_dominant_prob(Lambda_draws)

compute_distinguishing_prob(F_draws, delta = 1)

compute_consensus_prob(F_draws, delta = 1)

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

  Minimum separation on the standardized factor-score scale (default
  `1.0`).

- strong, moderate:

  Tier cutoffs on `max P(dominant)` (defaults 0.80 and 0.60 following
  the paper).

## Value

`compute_threshold_prob()`, `compute_dominant_prob()` return `N x K`
matrices. `compute_distinguishing_prob()` returns a `J x choose(K, 2)`
matrix. `compute_consensus_prob()` returns a length-`J` named vector.
`classify_membership()` returns a data frame.
