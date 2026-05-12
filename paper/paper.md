---
title: 'bayesqm: Probabilistic factor analysis for Q methodology in R'
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

`bayesqm` introduces fully Bayesian inference to Q methodology, an approach that identifies shared viewpoints from how participants rank-order a set of statements [@Stephenson1935; @Brown1980]. Each participant places statements onto a forced distribution (Figure \ref{fig:qsort}), so the analytic input is a $J \times N$ matrix of integer scores where every participant uses the same fixed count of statements at each rank position.

![A common Q-sort grid: participants arrange 36 statements on a nine-category forced distribution from "most disagree" to "most agree." Each column placement is constrained to a fixed count, producing the structural constraint that distinguishes Q-sort data from conventional rating scales.\label{fig:qsort}](figures/qsort-grid.pdf){width=70%}

The package fits a low-rank factor model to Q-sort data with a Student-$t$ likelihood and a hierarchical prior on loadings, samples the joint posterior with Stan [@CarpenterEtAl2017], resolves rotational ambiguity through MatchAlign post-processing [@PoworoznekEtAl2025], and returns posterior credible intervals for participant loadings, probabilistic factor membership summaries, distinguishing and consensus statement probabilities, and PSIS-LOO-based factor enumeration [@VehtariEtAl2017; @SivulaEtAl2025]. It supports both `cmdstanr` and `rstan` as Stan backends, imports Q-sort datasets from PQMethod and KADE, and integrates with the broader R Bayesian ecosystem via `posterior`, `loo`, and `ggplot2` autoplot methods.

# Statement of need

The standard frequentist toolkit for Q methodology, represented in R by the `qmethod` package [@Zabala2014], reports participant-to-factor assignments as binary "flagged" or "unflagged" classifications, with thresholds derived from a fixed standard error of $1/\sqrt{J}$ where $J$ is the number of statements [@Brown1980]. This binary framing obscures cross-loadings, hides the dependence of assignment confidence on study design, and provides no single posterior describing uncertainty in both the factor structure and the participants' assignments. Resampling-based extensions [@ZabalaPascual2016] add variability estimates for individual loadings and statement scores, yet they remain frequentist procedures and do not produce a single posterior over the joint factor structure.

Existing Bayesian exploratory factor analysis software in R operates on the standard variable-by-variable covariance matrix of R-mode factor analysis. It does not accommodate the by-person correlation structure that defines Q-sort data, the forced-distribution constraints that shape Q-sort scores, or the rotation conventions used in Q-methodology interpretation. A researcher wishing to apply Bayesian inference to a Q study has had to author a Stan model from scratch, implement rotation post-processing, and rebuild Q-specific reporting tools, an effort rarely undertaken in practice.

`bayesqm` provides a complete alternative. It supplies a Q-aware Stan model with sensible default priors, propagates posterior uncertainty through every reported quantity, and presents results through R's standard model interface. The package serves Q-methodology researchers across disciplines including political science [@Brown1980], environmental management [@WeblerEtAl2009], and Indigenous health research [@SchmidtEtAl2021], where treating factor membership as binary in small Q-samples may overstate the confidence of those factor assignments, a risk that the Bayesian framework makes explicit. The package originated in Q studies conducted with Alaska Native communities at the Center for Alaska Native Health Research, where small participant samples and substantive interest in cross-loadings made the limitations of binary classical assignment particularly visible.

# Implementation

The Stan model parameterizes the low-rank factorization
$$\mathbf{Y} = \mathbf{F} \boldsymbol{\Lambda}^{\top} + \mathbf{E},$$
with a per-draw column standardization of $\mathbf{F}$ to pin scale identifiability. Rotation, sign-flip, and factor-relabeling ambiguities are intentionally left unresolved during sampling and addressed in R after the fit. The function `fit_bayesian()` runs the sampler through whichever Stan backend is available, applies MatchAlign [@PoworoznekEtAl2025] to align the posterior draws, and returns a classed `bayesqm_fit` object carrying aligned draws, point and interval summaries, sampler diagnostics, and posterior predictive output.

Results are available through standard model accessors: `coef()`, `fitted()`, `residuals()`, `posterior_interval()`, `prior_summary()`, and a `summary()` method with Q-specific reporting. The fit object integrates with `posterior` (via `as_draws_*` methods), with `loo` (via a `loo.bayesqm_fit` method), and with `ggplot2` (via `autoplot` methods covering loadings, dominant-factor probabilities, and posterior predictive checks). The probabilistic-membership output that distinguishes `bayesqm` from frequentist Q tools is illustrated in Figure \ref{fig:membership}: each cell shows $P(\mathrm{dominant}_i = k \mid \mathbf{Y})$, making cross-loadings visible rather than collapsing them to a binary flag.

![Posterior dominant-factor probabilities estimated by `bayesqm` on two Q-sort datasets [@AkhtarDanesh2023]: a childhood-obesity study with $J = 42$ statements and $N = 33$ participants (panel A) and a marijuana-legalization study with $J = 19$ statements and $N = 40$ participants (panel B). Each cell shows $P(\mathrm{dominant}_i = k \mid \mathbf{Y})$. Cross-loadings and uncertain assignments are explicit, in contrast to the binary flagging used in classical Q analysis. With $J = 42$ statements, 30 of 33 participants reach moderate-or-strong assignment confidence; with $J = 19$, only 25 of 40 do, illustrating how assignment confidence depends on the size of the Q-sample.\label{fig:membership}](figures/dominant-membership.pdf){width=100%}

Classical Q analysis chooses the number of factors through interpretive judgment, eigenvalue thresholds, and other heuristics. `bayesqm` instead reports two principled signals across a fitted range of K, namely the expected log predictive density (ELPD) peak and the conservative parsimony rule of @SivulaEtAl2025. The package adopts the ELPD peak as the chosen K (Figure \ref{fig:elpd}). When the two signals agree, the choice is uncontroversial; when the Sivula rule recommends fewer factors than the peak, the gap is itself diagnostic.

![Factor enumeration on two Q-sort datasets [@AkhtarDanesh2023]: $\Delta$ELPD relative to $K = 1$ across $K \in \{1, \ldots, 5\}$, with the Sivula parsimony rule (red triangle) and the ELPD peak (blue square) marked. The shaded band at $|\Delta\mathrm{ELPD}| < 4$ indicates where the Sivula rule rejects an increment as not parsimonious. In both datasets, the ELPD peak is $K = 3$ while the Sivula rule recommends fewer factors, illustrating the gap case the protocol is designed to handle.\label{fig:elpd}](figures/elpd-k-selection.pdf){width=100%}

For users transitioning from existing Q-methodology workflows, `bayesqm` provides direct importers for the file formats produced by PQMethod and KADE, so legacy datasets can be analyzed without manual reformatting.

# Acknowledgements

`bayesqm` grew out of work at the Center for Alaska Native Health Research at the University of Alaska Fairbanks, and would not exist without the people there. I am grateful to the CANHR research team for their discussions and encouragement, and especially to the Numbers Team, particularly Andrew Grogan-Kaylor and KyungSook Lee, for their methodological discussions, feedback on early designs, and patience with the questions that shaped this package over many conversations.

# References
