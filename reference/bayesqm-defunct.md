# Defunct 0.1.0 functions

These 0.1.0 entry points belonged to the removed Student-t score-scale
model and now signal an error naming their 0.2.0 replacement: flag
probabilities and signs come from
[`compute_flags()`](https://rdazadda.github.io/bayesqm/reference/compute_flags.md),
distinguishing/consensus verdicts from
[`compute_qdc()`](https://rdazadda.github.io/bayesqm/reference/compute_qdc.md),
the critical difference from the posterior itself, factor enumeration
from
[`fit_ladder()`](https://rdazadda.github.io/bayesqm/reference/fit_ladder.md)
and
[`select_k()`](https://rdazadda.github.io/bayesqm/reference/select_k.md),
and scalar summaries from `as_draws_df()`.

## Usage

``` r
run_bayes(...)

plot_hyper(...)

select_k_peak(...)

select_k_sivula(...)

compute_dominant_prob(...)

compute_dominant_sign(...)

compute_threshold_prob(...)

classify_membership(...)

compute_divergence(...)

critical_delta(...)

suggest_delta(...)

compute_posterior_scalars(...)

demo_run(...)

plot_elpd(...)

make_elpd_diff(...)

make_ppc_ridge(...)

make_dominant_panel(...)
```

## Arguments

- ...:

  Ignored.

## Value

Always signals an error.
