# Fit a Bayesian Q-methodology factor model

Fits the low-rank Bayesian factor model to Q-sort data. Samples the
posterior with Stan (via cmdstanr or rstan), resolves rotational
ambiguity with MatchAlign, and returns a classed `bayesqm_fit` object
carrying posterior-mean loadings and factor scores, credible intervals,
raw draws, LOO, PPC, and diagnostics.

## Usage

``` r
fit_bayesian(
  Y,
  K,
  stan_dir = NULL,
  robust = TRUE,
  nu = "estimate",
  chains = 4,
  iter = 2000,
  warmup = 1000,
  seed = NULL,
  adapt_delta = 0.9,
  max_draws = 2000,
  prior_loading_scale = 1,
  prior_sigma_scale = 1,
  prior_nu_alpha = 2,
  prior_nu_beta = 0.1,
  use_half_cauchy = FALSE,
  prob = 0.95,
  delta = NULL
)
```

## Arguments

- Y:

  Either a `qsort_data` object or a `J x N` numeric matrix with
  statements as rows and participants as columns.

- K:

  Integer number of factors to extract.

- stan_dir:

  Directory containing `stan/factor_model.stan`. `NULL` (the default)
  uses the copy shipped in `inst/stan/`.

- robust:

  Logical; `TRUE` uses a Student-t likelihood, `FALSE` uses Normal.

- nu:

  Either `"estimate"` (default) to sample the Student-t degrees of
  freedom, or a numeric value (e.g. `5`, `Inf`) to fix it.

- chains, iter, warmup:

  NUTS sampler settings.

- seed:

  Optional integer seed for reproducibility.

- adapt_delta:

  NUTS adapt_delta target (default 0.90).

- max_draws:

  Thin post-warmup draws to at most this many before MatchAlign (default
  2000).

- prior_loading_scale, prior_sigma_scale, prior_nu_alpha, prior_nu_beta,
  use_half_cauchy:

  Prior hyperparameters (see the Stan model for parameterization).

- prob:

  Credible-interval probability stored on the fit (default 0.95).

- delta:

  Substantive viewpoint separation for the distinguishing/consensus
  probabilities. If `NULL` (default) it is computed as the
  reliability-adjusted critical difference
  ([`critical_delta()`](https://rdazadda.github.io/bayesqm/reference/critical_delta.md));
  pass a numeric value to override, or use
  [`suggest_delta()`](https://rdazadda.github.io/bayesqm/reference/suggest_delta.md)
  as an alternative.

## Value

A `bayesqm_fit` object. See
[bayesqm-fit-methods](https://rdazadda.github.io/bayesqm/reference/bayesqm-fit-methods.md)
for [`print()`](https://rdrr.io/r/base/print.html) and
[`summary()`](https://rdrr.io/r/base/summary.html), and
[`coef.bayesqm_fit()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-fit-accessors.md)
for the standard R accessors.

## References

Poworoznek et al. (2025). Efficiently Resolving Rotational Ambiguity in
Bayesian Matrix Sampling with Matching. *Bayesian Analysis*.

## Examples

``` r
if (FALSE) { # \dontrun{
qdata <- read_qsort("mystudy.csv")
fit <- fit_bayesian(qdata, K = 3)
fit
summary(fit)
} # }
```
