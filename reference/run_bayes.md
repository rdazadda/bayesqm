# Fit the model across a range of K

Fits
[`fit_bayesian()`](https://rdazadda.github.io/bayesqm/reference/fit_bayesian.md)
for K = 1..K_max and reports the ELPD peak (automated adoption), the
Sivula (2025) parsimony diagnostic, and a case label (`agree`, `gap`,
`reversed`) summarising their relationship. When the two agree the data
supports that K; when they disagree the `gap` is itself a reportable
finding.

## Usage

``` r
run_bayes(
  Y,
  K_max = 5,
  stan_dir = NULL,
  elpd_diff_threshold = 4,
  se_ratio_threshold = 2,
  ...
)

select_k_peak(elpds, K_candidates)

select_k_sivula(
  elpds,
  loo_list,
  K_candidates,
  elpd_diff_threshold = 4,
  se_ratio_threshold = 2
)
```

## Arguments

- Y:

  A `qsort_data` object or `J x N` numeric matrix.

- K_max:

  Largest K to try (default 5).

- stan_dir:

  Optional override of the Stan model directory.

- elpd_diff_threshold, se_ratio_threshold:

  Sivula rule thresholds (paper defaults 4 and 2).

- ...:

  Passed to
  [`fit_bayesian()`](https://rdazadda.github.io/bayesqm/reference/fit_bayesian.md).

- elpds, loo_list, K_candidates:

  Internal inputs for `select_k_peak()` and `select_k_sivula()`.

## Value

`run_bayes()` returns a `bayesqm_run` object carrying the list of fits,
the ELPD comparison table, and the peak / Sivula / case verdict.
`select_k_peak()` and `select_k_sivula()` return an integer K.
