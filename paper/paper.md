---
title: 'Bayesian Q methodology: probabilistic factor analysis for the study of subjective opinions'
tags:
  - R
  - Stan
  - Bayesian inference
  - factor analysis
  - Q methodology
  - subjective opinions
  - posterior uncertainty
authors:
  - name: Raymond Dacosta Azadda
    orcid: 0009-0002-4384-4556
    affiliation: 1
affiliations:
  - name: Center for Alaska Native Health Research, University of Alaska Fairbanks, USA
    index: 1
date: 10 May 2026
bibliography: paper.bib
---

# Summary

Q methodology is a research approach for studying subjective opinions: participants rank-order a structured set of statements under a condition of instruction, and the resulting Q-sorts are factor-analyzed across persons to identify shared viewpoints [@Stephenson1935; @Brown1980]. Each participant places statements onto a forced distribution (Figure \ref{fig:qsort}), so the analytic input is a $J \times N$ matrix of integer scores constrained by a fixed column-marginal distribution.

![A common Q-sort grid: 36 statements arranged on a nine-category forced distribution from "most disagree" to "most agree." Each column placement is constrained to a fixed count, producing the ipsative structure that distinguishes Q-sort data from conventional rating scales.\label{fig:qsort}](figures/qsort-grid.pdf){width=70%}

`bayesqm` is an R package that implements this analysis in a fully Bayesian framework. It fits a low-rank factor model to Q-sort data with a Student-$t$ likelihood and a hierarchical prior on loadings, samples the joint posterior with Stan [@CarpenterEtAl2017], resolves rotational ambiguity through MatchAlign post-processing [@PoworoznekEtAl2025], and returns posterior credible intervals for participant loadings, probabilistic factor membership summaries, distinguishing and consensus statement probabilities, and PSIS-LOO-based factor enumeration [@VehtariEtAl2017; @SivulaEtAl2025]. The package supports both `cmdstanr` and `rstan` as Stan backends, imports Q-sort datasets from PQMethod, KADE, HTMLQ, and FlashQ, and integrates with the broader R Bayesian ecosystem via `posterior`, `loo`, and `ggplot2` autoplot methods.

# Statement of need

The standard frequentist toolkit for Q methodology, represented in R by the `qmethod` package [@Zabala2014], reports participant-to-factor assignments as binary "flagged" or "unflagged" classifications, with thresholds derived from a fixed standard error of $1/\sqrt{J}$ where $J$ is the number of statements [@Brown1980]. This binary framing obscures cross-loadings, hides the dependence of assignment confidence on study design, and yields no joint uncertainty characterization over factor structure and participant membership. Resampling-based extensions [@ZabalaPascual2016] add variability estimates for individual loadings and statement scores, yet they remain frequentist procedures and do not produce a single posterior over the joint factor structure.

Existing Bayesian exploratory factor analysis software in R operates on the standard variable-by-variable covariance matrix of R-mode factor analysis. It does not accommodate the by-person correlation structure that defines Q-sort data, the forced-distribution constraints that shape Q-sort scores, or the rotation conventions used in Q-methodology interpretation. A researcher wishing to apply Bayesian inference to a Q study has had to author a Stan model from scratch, implement rotation post-processing, and rebuild Q-specific reporting tools, an effort rarely undertaken in practice.

`bayesqm` provides a turnkey alternative. It supplies a Q-aware Stan model with sensible default priors, propagates posterior uncertainty through every reported quantity, and exposes results through familiar R idioms. The package serves Q-methodology researchers across disciplines including political science [@Brown1980], environmental management [@WeblerEtAl2009], and Indigenous health research [@SchmidtEtAl2021], where treating factor membership as binary in small Q-samples may overstate confidence in qualitative typologies, a risk that the Bayesian framework makes explicit.

# Implementation

The package separates the methodological core from the user-facing surface. The Stan model in `inst/stan/factor_model.stan` parameterizes the low-rank factorization
$$\mathbf{Y} = \mathbf{F} \boldsymbol{\Lambda}^{\top} + \mathbf{E},$$
with a per-draw column standardization of $\mathbf{F}$ to pin scale identifiability; the orthogonal-rotation, sign, and label-permutation invariances are intentionally left unresolved at sampling time and addressed in R post-hoc. The function `fit_bayesian()` runs the sampler through whichever Stan backend is available, applies MatchAlign [@PoworoznekEtAl2025] to align the posterior draws, and returns a classed `bayesqm_fit` object carrying aligned draws, point and interval summaries, sampler diagnostics, and posterior predictive output.

Results are exposed through standard model accessors: `coef()`, `fitted()`, `residuals()`, `posterior_interval()`, `prior_summary()`, and a `summary()` method with Q-specific reporting. The fit object integrates with `posterior` (via `as_draws_*` methods), with `loo` (via a `loo.bayesqm_fit` method), and with `ggplot2` (via `autoplot` methods covering loadings, dominant-factor probabilities, posterior predictive checks, and ELPD-versus-$K$ diagnostics for factor enumeration following the parsimony rule of @SivulaEtAl2025). The probabilistic-membership output that distinguishes `bayesqm` from frequentist Q tools is illustrated in Figure \ref{fig:membership}: each cell shows $P(\mathrm{dominant}_i = k \mid \mathbf{Y})$, making cross-loadings visible rather than collapsing them to a binary flag.

![Posterior dominant-factor probabilities estimated by `bayesqm` on two Q-sort datasets [@AkhtarDanesh2023]: a childhood-obesity study with $J = 42$ statements and $N = 33$ participants (panel A) and a marijuana-legalization study with $J = 19$ statements and $N = 40$ participants (panel B). Each cell shows $P(\mathrm{dominant}_i = k \mid \mathbf{Y})$. Cross-loadings and uncertain assignments are explicit, in contrast to the binary flagging used in classical Q analysis. With $J = 42$ statements, 30 of 33 participants reach moderate-or-strong assignment confidence; with $J = 19$, only 25 of 40 do, illustrating how assignment confidence depends on the size of the Q-sample.\label{fig:membership}](figures/dominant-membership.pdf){width=100%}

For users transitioning from existing Q-methodology workflows, `bayesqm` provides direct importers for the file formats produced by PQMethod, KADE, HTMLQ, and FlashQ, so legacy datasets can be analyzed without manual reformatting.

Five simulation studies validate the framework: credible-interval coverage is near-nominal (93–96% under favorable conditions), and the conservative factor-enumeration protocol correctly guards against overselection in 89.5% of replications across a range of sample sizes and error structures.

# Acknowledgements

This work was conducted at the Center for Alaska Native Health Research at the University of Alaska Fairbanks. The author thanks the Q-methodology research community for the publicly available datasets used in package development, and the development teams of Stan, `cmdstanr`, `rstan`, `loo`, `posterior`, and `ggplot2` for the foundational tooling on which this package is built.

# References
