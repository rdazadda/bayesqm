# bayesqm: Bayesian Q Methodology: Exact Rank-Order Likelihood for Forced Q Sorts

A Bayesian analysis for Q methodology, alongside the classical one.
Models the forced Q sort as an ordered partition of the statements
through an exact rank-order likelihood (the design quotas fix the
partition margins, so the likelihood of the observed sorting event is
exact), fits it by a parameter-expanded Gibbs sampler in R with no
compiled code and a convergence gate on rotation-invariant functionals,
resolves rotational ambiguity via the MatchAlign post-processing of
Poworoznek et al. (2025)
[doi:10.1214/25-BA1544](https://doi.org/10.1214/25-BA1544) , and returns
the familiar Q tables as posterior summaries: credible intervals for
bounded participant loadings, flag probabilities with an explicit
unclassified state, quota-respecting factor arrays, distinguishing and
consensus statements judged against a posterior critical difference and
a grid-width equivalence region, one posterior false-discovery rule for
all published claims, and a two-signal posterior-predictive workflow for
the number of factors.

A Bayesian analysis for Q methodology, alongside the classical one. The
forced Q sort is modeled as an ordered partition of the statements
through an exact rank-order likelihood: the design quotas fix the
partition margins, so the probability of the observed sorting event is
the full observed-data likelihood. The posterior is sampled by a
parameter-expanded Gibbs sampler in R with no compiled code, gated on
rotation-invariant convergence diagnostics, aligned by MatchAlign, and
returned as the familiar Q tables with uncertainty attached.

## Details

The typical workflow:

1.  **Import data.**
    [`read_qsort()`](https://rdazadda.github.io/bayesqm/reference/read_qsort.md)
    auto-detects CSV, Excel, PQMethod `.DAT`, Ken-Q JSON / multi-sheet
    Excel, KADE ZIP, or Easy-HTMLQ Firebase JSON.
    [`qsort_data()`](https://rdazadda.github.io/bayesqm/reference/qsort_data.md)
    constructs the object directly from a matrix. The exact likelihood
    needs forced sorts: every participant must match the design grid.

2.  **Fit.**
    [`fit_bayesian()`](https://rdazadda.github.io/bayesqm/reference/fit_bayesian.md)
    returns a `bayesqm_fit`;
    [`extend()`](https://rdazadda.github.io/bayesqm/reference/extend.md)
    warm-continues a chain the convergence gate flagged.

3.  **Read the tables.**
    [`compute_loadings()`](https://rdazadda.github.io/bayesqm/reference/compute_loadings.md)
    (bounded loadings with credible intervals),
    [`compute_flags()`](https://rdazadda.github.io/bayesqm/reference/compute_flags.md)
    (flag probabilities with an unclassified state),
    [`compute_zscores()`](https://rdazadda.github.io/bayesqm/reference/compute_zscores.md),
    [`compute_factor_array()`](https://rdazadda.github.io/bayesqm/reference/compute_factor_array.md)
    (quota-exact arrays),
    [`compute_qdc()`](https://rdazadda.github.io/bayesqm/reference/compute_qdc.md)
    (distinguishing / consensus / indeterminate),
    [`crib_sheet()`](https://rdazadda.github.io/bayesqm/reference/crib_sheet.md),
    and
    [`claims()`](https://rdazadda.github.io/bayesqm/reference/claims.md)
    — one posterior false-discovery rule selecting every claim.

4.  **Check the model.**
    [`check_fit()`](https://rdazadda.github.io/bayesqm/reference/check_fit.md)
    (agreement, extra-factor, and paired-comparison checks) and
    [`check_persons()`](https://rdazadda.github.io/bayesqm/reference/check_persons.md)
    (the person check, against mixed-replication bands).

5.  **Choose K.**
    [`fit_ladder()`](https://rdazadda.github.io/bayesqm/reference/fit_ladder.md)
    and
    [`select_k()`](https://rdazadda.github.io/bayesqm/reference/select_k.md)
    run the two-signal workflow;
    [`loo_ladder()`](https://rdazadda.github.io/bayesqm/reference/loo_ladder.md)
    adds directional corroboration.

6.  **Report.** The `plot_*` views,
    [`rotate_factors()`](https://rdazadda.github.io/bayesqm/reference/rotate_factors.md)
    for judgmental rotation,
    [`rename_factors()`](https://rdazadda.github.io/bayesqm/reference/rename_factors.md),
    and the standard R accessors
    ([`coef()`](https://rdrr.io/r/stats/coef.html),
    [`fitted()`](https://rdrr.io/r/stats/fitted.values.html),
    `as_draws_df()`,
    [`posterior_interval()`](https://rdazadda.github.io/bayesqm/reference/posterior_interval.md),
    [`prior_summary()`](https://rdazadda.github.io/bayesqm/reference/prior_summary.md)).

## Relationship to classical Q analysis

The questions and the reporting conventions are Q's own; what the
Bayesian account adds is a probability behind each familiar verdict.
Vocabulary carries over: flags, factor arrays, defining sorts,
distinguishing and consensus statements. Two deliberate differences in
the tables:

- Factor characteristics do not print eigenvalues or explained variance,
  which have no counterpart in a generative model; report the
  defining-sort counts from
  [`claims()`](https://rdazadda.github.io/bayesqm/reference/claims.md)
  and the extra-factor check of
  [`check_fit()`](https://rdazadda.github.io/bayesqm/reference/check_fit.md)
  in their place.

- Consensus is a positive finding (an equivalence region of one grid
  column,
  [`delta_grid()`](https://rdazadda.github.io/bayesqm/reference/delta_grid.md)),
  not the complement of distinguishing, so a statement can be
  distinguishing, consensus, or neither.

## References

Poworoznek, E., Anceschi, N., Ferrari, F., & Dunson, D. (2025).
Efficiently Resolving Rotational Ambiguity in Bayesian Matrix Sampling
with Matching. *Bayesian Analysis*.

Vehtari, A., Gelman, A., Simpson, D., Carpenter, B., & Bürkner, P.-C.
(2021). Rank-Normalization, Folding, and Localization: An Improved R-hat
for Assessing Convergence of MCMC. *Bayesian Analysis*, 16(2), 667-718.

## See also

Useful links:

- <https://github.com/rdazadda/bayesqm>

- <https://rdazadda.github.io/bayesqm/>

- Report bugs at <https://github.com/rdazadda/bayesqm/issues>

## Author

**Maintainer**: Raymond Dacosta Azadda <rdazadda@alaska.edu>
([ORCID](https://orcid.org/0009-0002-4384-4556))

Authors:

- Raymond Dacosta Azadda <rdazadda@alaska.edu>
  ([ORCID](https://orcid.org/0009-0002-4384-4556))

- Henry Ofoe Agbi-Kaiser
  ([ORCID](https://orcid.org/0009-0008-6127-9136))

- Hannah D. Robinson ([ORCID](https://orcid.org/0009-0000-5159-1363))

- AK-ACE Team

- Karsten Hueffer

- Taa'aii Peter

- Stacy Rasmus
