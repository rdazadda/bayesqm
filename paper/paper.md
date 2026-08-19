---
title: 'bayesqm: Bayesian Q methodology from an exact rank-order likelihood'
tags:
  - R
  - Bayesian inference
  - Q methodology
  - factor analysis
  - rank-order data
  - forced distribution
authors:
  - name: Raymond Dacosta Azadda
    orcid: 0009-0002-4384-4556
    affiliation: 1
    corresponding: true
  - name: Henry Ofoe Agbi-Kaiser
    orcid: 0009-0008-6127-9136
    affiliation: 1
  - name: Hannah D. Robinson
    affiliation: 1
  - name: AK-ACE Team
    affiliation: 1
  - name: Karsten Hueffer
    affiliation: 1
  - name: Taa'aii Peter
    affiliation: 1
  - name: Stacy Rasmus
    affiliation: 1
affiliations:
  - name: University of Alaska Fairbanks, USA
    index: 1
date: 18 August 2026
bibliography: paper.bib
---

# Summary

`bayesqm` is an R package for Bayesian analysis of Q methodology studies. It fits a model whose likelihood, the probability assigned to the data, is the exact probability of each observed ranking under the design quotas, and each standard Q result carries a probability statement.

In a Q study, participants rank a set of statements into a forced grid from most disagree to most agree, with column counts fixed by design [@Stephenson1935]. A completed sort records an ordered partition, which group outranks which with group sizes known in advance. Factor analysis gathers participants who ranked similarly, and each factor is read as a shared viewpoint [@Brown1980].

![A forced Q sort grid, one statement per cell, column counts fixed by design.\label{fig:qsort}](figures/qsort-grid.pdf){width=70%}

Fitting uses a parameter-expanded Gibbs sampler [@MurrayEtAl2013], a simulation method that draws many plausible solutions given the data, in pure R with no compiled code. MatchAlign [@PoworoznekEtAl2025] aligns the draws after sampling so factor order, signs, and orientation stay consistent. Loadings, each participant's strength of match to each factor on a correlation scale, carry credible intervals, ranges that contain the value with stated probability. The flags that assign participants to factors become probabilities. Factor arrays, the reconstructed sort for each viewpoint, shade every placement by how certain it is. Distinguishing statements, which separate one viewpoint from the rest, and consensus statements, which all viewpoints rank alike, are selected under an error rule that states the expected number of wrong claims in every table. The number of factors is itself a decision.

# Statement of need

Q studies are commonly analyzed with PQMethod or the qmethod package [@Zabala2014]. In classical practice a participant is flagged when a loading clears a threshold set from the number of statements, distinguishing and consensus statements are settled by significance against a conventional standard error, and the number of factors is chosen by rule and judgment [@Brown1980]. These conventions state no level of confidence for the claims they produce. Bootstrap extensions [@ZabalaPascual2016] measure the stability of the classical estimates without giving the uncertainty of the whole solution, general Bayesian factor-analysis software models measured variables, and no model of the sorting event existed to fit. `bayesqm` supplies that model and runs alongside classical practice. Varimax, the standard orientation of factors, stays the default, the classical flag rule is applied draw by draw, and defining sorts, the sorts of flagged participants, keep their role. Fixed numbers become estimated quantities with stated uncertainty.

# Functionality

`read_qsort()` loads a statements-by-sorts table and validates every sort against its grid, and importers load PQMethod, KenQ, KADE, and easyHTMLQ files without reformatting. `fit_bayesian()` fits the model at a single number of factors K, `fit_ladder()` fits a range of candidates, and `select_k()` decides from two checks, whether a candidate accounts for the sorts and whether every factor keeps at least two flagged participants and one distinguishing statement. The possible answers are a selected K, one shared viewpoint, no shared structure, or a tension between candidates. `claims()` returns the flag, distinguishing, and consensus tables with the expected number of false claims in each. `compute_factor_array()`, `compute_zscores()`, `factor_characteristics()`, and `crib_sheet()` cover the standard Q report. `check_fit()` and `check_persons()` test whether the fitted model reproduces the sorts and whether any participant sits outside it. Plot functions draw the sorts, arrays, contrasts, flags, and the choice of K. A fit takes one to three minutes on an ordinary desktop, and a complete analysis with checks runs in five to fifteen minutes.

Two studies ship as package data. `obesity_sorts` holds the childhood obesity study of @AkhtarDanesh2023, 42 statements and 33 participants, where the decision is one shared viewpoint, 32 of 33 participants flagged on a single factor, its array in Figure \ref{fig:array}. `grizzly_sorts` holds the grizzly bear reintroduction study of @EasterEtAl2025, 41 statements and 67 participants, where the rule selects two viewpoints, shown in Figure \ref{fig:choice}. The two decisions show the range of the rule, a selection when factors hold support and a single shared viewpoint when they do not. The analyses and figures in this paper regenerate from a seeded script using only the shipped datasets.

![The obesity study's shared factor array. Darker tiles mark more certain placements.\label{fig:array}](figures/obesity-array.pdf){width=85%}

![Choice of K for the grizzly study. The rule selects K = 2, the smallest candidate with every factor supported.\label{fig:choice}](figures/grizzly-choice.pdf){width=85%}

# Funding

This research was, in part, funded by the National Institutes of Health (NIH) Agreement OT2HL158287 (Stacy Rasmus, Contact PI, smrasmus@alaska.edu; Karsten Hueffer and Taa'aii Peter, MPIs). The views and conclusions contained in this document are those of the authors and should not be interpreted as representing the official policies, either expressed or implied, of the NIH.

# References
