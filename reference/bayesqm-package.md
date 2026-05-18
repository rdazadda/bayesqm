# bayesqm: Bayesian Q Methodology: Probabilistic Factor Analysis

A Bayesian factor-analytic framework for Q methodology. Fits a low-rank
factor model to Q-sort data with a Student-t likelihood and a
hierarchical normal prior on loadings, samples the posterior with Stan,
resolves rotational ambiguity via the MatchAlign post-processing of
Poworoznek et al. (2025)
[doi:10.1214/25-BA1544](https://doi.org/10.1214/25-BA1544) , and returns
posterior summaries including credible intervals for loadings and factor
scores, probabilistic dominant-factor membership, distinguishing and
consensus statements, and PSIS-LOO-based factor enumeration following
Vehtari et al. (2017)
[doi:10.1007/s11222-016-9696-4](https://doi.org/10.1007/s11222-016-9696-4)
with the Sivula et al. (2025)
[doi:10.1214/25-BA1569](https://doi.org/10.1214/25-BA1569) parsimony
rule.

A Bayesian factor-analytic framework for Q methodology. Fits a low-rank
factor model to Q-sort data with a Student-t likelihood and a
hierarchical normal prior on loadings, samples the posterior with Stan,
resolves rotational ambiguity via MatchAlign post-processing, and
returns posterior summaries including credible intervals for loadings
and factor scores, probabilistic dominant-factor membership,
distinguishing and consensus statements, and PSIS-LOO-based factor
enumeration.

## Details

The typical workflow is:

1.  **Import data.**
    [`read_qsort()`](https://rdazadda.github.io/bayesqm/reference/read_qsort.md)
    auto-detects CSV, Excel, PQMethod `.DAT`, Ken-Q JSON / multi-sheet
    Excel, KADE ZIP, or Easy-HTMLQ Firebase JSON.
    [`qsort_data()`](https://rdazadda.github.io/bayesqm/reference/qsort_data.md)
    constructs the object directly from a matrix.

2.  **Fit the model.**
    [`fit_bayesian()`](https://rdazadda.github.io/bayesqm/reference/fit_bayesian.md)
    returns a `bayesqm_fit` object.
    [`run_bayes()`](https://rdazadda.github.io/bayesqm/reference/run_bayes.md)
    fits the model for a range of K and returns a `bayesqm_run` object
    carrying the ELPD comparison table and the peak-plus-Sivula protocol
    verdict.

3.  **Summarise the posterior.**
    [`compute_loadings()`](https://rdazadda.github.io/bayesqm/reference/compute_loadings.md),
    [`compute_zscores()`](https://rdazadda.github.io/bayesqm/reference/compute_zscores.md),
    [`compute_factor_array()`](https://rdazadda.github.io/bayesqm/reference/compute_factor_array.md),
    [`compute_dominant_prob()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-membership.md),
    [`compute_threshold_prob()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-membership.md),
    [`compute_divergence()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-membership.md),
    [`classify_membership()`](https://rdazadda.github.io/bayesqm/reference/bayesqm-membership.md),
    and
    [`compute_posterior_scalars()`](https://rdazadda.github.io/bayesqm/reference/compute_posterior_scalars.md).

4.  **Use standard R accessors.**
    [`coef()`](https://rdrr.io/r/stats/coef.html),
    [`fitted()`](https://rdrr.io/r/stats/fitted.values.html),
    [`residuals()`](https://rdrr.io/r/stats/residuals.html),
    [`sigma()`](https://rdrr.io/r/stats/sigma.html),
    [`family()`](https://rdrr.io/r/stats/family.html),
    [`nobs()`](https://rdrr.io/r/stats/nobs.html),
    [`as.matrix()`](https://rdrr.io/r/base/matrix.html),
    [`as.array()`](https://rdrr.io/r/base/array.html),
    [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html),
    [`update()`](https://rdrr.io/r/stats/update.html), plus
    [`rstantools::posterior_interval()`](https://mc-stan.org/rstantools/reference/posterior_interval.html)
    and
    [`rstantools::prior_summary()`](https://mc-stan.org/rstantools/reference/prior_summary.html)
    work directly on the fit.

Draws extraction works with the `posterior` package (`as_draws_df()`,
`as_draws_matrix()`, `as_draws_array()`), which in turn makes the fit
usable with `bayesplot` and `tidybayes` through their standard
conventions.

## Relationship to the qmethod package

The `bayesqm_fit` object parallels `qmethod::qmethod` output where that
is meaningful, so scripts written against `qmethod` largely keep
working:

- Slot names match: `$dataset`, `$loa`, `$zsc`, `$zsc_n`, `$f_char`,
  `$qdc`, `$flagged`.

- The `$qdc$dist.and.cons` vocabulary matches exactly
  (`"Distinguishes all"`, `"Consensus"`, `"Distinguishes f1, f3"`,
  `""`).

- Dotted reader aliases
  ([`import.pqmethod()`](https://rdazadda.github.io/bayesqm/reference/import-aliases.md),
  [`import.htmlq()`](https://rdazadda.github.io/bayesqm/reference/import-aliases.md),
  [`import.kenq()`](https://rdazadda.github.io/bayesqm/reference/import-aliases.md),
  [`import.easyhtmlq()`](https://rdazadda.github.io/bayesqm/reference/import-aliases.md))
  forward to the `read_*` readers.

Intentional Bayesian divergences:

- `$f_char$characteristics` omits the classical test-theory columns
  (`av_rel_coef`, `reliability`, `se_fscores`, `sd_dif`). Factor-score
  uncertainty is already quantified by the posterior credible intervals
  in `$ci_lower` and `$ci_upper`, so Spearman-Brown composite
  reliability is not the right construct.

- `$flagged` is a logical `N x K` matrix defined as
  `P(argmax_k |Lambda[i, k]| = k) > 0.5` rather than Brown's (1980)
  significance-based rule. The posterior probability makes the Bayesian
  analogue direct.

- `$brief` uses `K`, `N`, `J` (not `nfactors`, `nqsort`, `nstat`) and
  includes Bayesian-specific fields (`family`, `prob`, `priors`,
  `backend`).

## References

Poworoznek, E., Anceschi, N., Ferrari, F., & Dunson, D. (2025).
Efficiently Resolving Rotational Ambiguity in Bayesian Matrix Sampling
with Matching. *Bayesian Analysis*.

Sivula, T., Magnusson, M., Matamoros, A. A., & Vehtari, A. (2025).
Uncertainty in Bayesian Leave-One-Out Cross-Validation Based Model
Comparison. *Bayesian Analysis*.

Vehtari, A., Gelman, A., & Gabry, J. (2017). Practical Bayesian model
evaluation using leave-one-out cross-validation and WAIC. *Statistics
and Computing*, 27(5), 1413-1432.

## See also

Useful links:

- <https://github.com/rdazadda/bayesqm>

- <https://rdazadda.github.io/bayesqm/>

- Report bugs at <https://github.com/rdazadda/bayesqm/issues>

## Author

**Maintainer**: Raymond Dacosta Azadda <rdazadda@alaska.edu>

Authors:

- Raymond Dacosta Azadda <rdazadda@alaska.edu>
