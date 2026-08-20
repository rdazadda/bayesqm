# Validation

This article checks the implementation two ways. It fits a panel with
planted viewpoints and measures how well the truth comes back, and it
runs a real panel through both this package and `qmethod` to compare the
outputs wherever the two compute the same object. Every number on this
page is computed when the site builds.

## Recovering planted truth

[`generate_data()`](https://rdazadda.github.io/bayesqm/reference/generate_data.md)
builds a panel with known viewpoints. 14 sorters, 20 statements, two
planted factors, the same panel the README analyzes.

``` r

sim <- generate_data(N = 14, J = 20, K = 2, noise_sd = 0.6,
                     primary_range = c(0.65, 0.9), seed = 7)
qdata <- qsort_data(sim$Y, distribution = sim$distribution)
fit <- fit_bayesian(qdata, K = 2, seed = 7)
#> grid labels -4..4 recoded onto categories 1..9 (a monotone relabeling; the sorts are unchanged)
```

The model reports loadings on a bounded correlation scale, so the
planted loadings go onto the same scale before the comparison, and the
posterior draws supply the interval checks.
[`assess_recovery()`](https://rdazadda.github.io/bayesqm/reference/assess_recovery.md)
aligns the estimate to the truth and returns the error, the congruence
per factor, a 0-to-1 agreement between loading patterns, and the
coverage of the credible intervals.

``` r

rho_true  <- sim$Lambda_true / sqrt(1 + rowSums(sim$Lambda_true^2))
lo        <- compute_loadings(fit)
rho_hat   <- as.matrix(lo[, paste0("f", 1:2, "_loading")])
s2        <- fit$draws$s_i^2
rho_draws <- fit$draws$Lambda /
  sqrt(1 + array(s2, dim(fit$draws$Lambda)))

rec <- assess_recovery(rho_hat, rho_true, rho_draws)
round(rec$tucker, 3)
#> [1] 0.978 0.953
round(unlist(rec[c("rmse", "coverage", "ci_width")]), 3)
#>     rmse coverage ci_width 
#>    0.129    0.964    0.588
```

Congruence at these levels says the planted viewpoints come back as
themselves, and coverage near the 95 percent the intervals promise says
the uncertainty is honest. The statement scores tell the same story.

``` r

zs <- compute_zscores(fit)
F_hat <- as.matrix(zs[, paste0("f", 1:2, "_zsc")])
R <- attr(procrustes_rotation(rho_hat, rho_true), "rotation")
round(diag(cor(scale(sim$F_true), F_hat %*% R)), 3)
#> [1] 0.959 0.955
```

A single run shows the machinery working, it does not prove calibration.
The generator scales to any panel shape, so the check can be repeated at
your own study’s size before you commit to an analysis.

## Corresponding with classical analysis

`qmethod` ([Zabala, 2014](#ref-Zabala2014)) is the field’s reference
implementation of the classical workflow, principal components, varimax
rotation, and the standard flagging and scoring rules. Where both
packages compute the same object the two should track each other, and
the childhood obesity panel of Akhtar-Danesh
([2023](#ref-AkhtarDanesh2023)) shows what that looks like on a real
study.

``` r

data(obesity_sorts)
qm  <- qmethod::qmethod(as.data.frame(obesity_sorts$Y), nfactors = 3,
                        silent = TRUE)
fb  <- fit_bayesian(obesity_sorts, K = 3, seed = 11)
#> grid labels -4..4 recoded onto categories 1..9 (a monotone relabeling; the sorts are unchanged)
lo3 <- compute_loadings(fb)
rho <- as.matrix(lo3[, paste0("f", 1:3, "_loading")])
```

Find each classical factor’s closest posterior counterpart by
congruence, then compare the loadings and the statement scores.

``` r

loa <- as.matrix(qm$loa)
cong <- abs(t(apply(loa, 2, function(a)
  apply(rho, 2, function(b) tucker_congruence(a, b)))))
closest <- apply(cong, 1, which.max)
zb <- as.matrix(compute_zscores(fb)[, paste0("f", 1:3, "_zsc")])
zq <- as.matrix(qm$zsc)

data.frame(
  classical  = colnames(loa),
  closest    = paste0("f", closest),
  congruence = round(cong[cbind(1:3, closest)], 2),
  score_cor  = round(diag(cor(zq, zb[, closest])), 2)
)
#>   classical closest congruence score_cor
#> 1        f1      f2       0.96      0.99
#> 2        f2      f1       0.85      0.66
#> 3        f3      f2       0.75      0.63
```

The dominant factor corresponds tightly, in loadings and in scores. The
two weaker classical factors correspond progressively less, and they are
exactly the factors the decision layer declines to support. Notice also
that two classical factors share the same closest posterior counterpart,
which is what a split of one viewpoint looks like from the posterior’s
side.

The arrays tell the same story. The share of statements both analyses
place in the same grid column:

``` r

ab <- compute_factor_array(fb)
gb <- as.matrix(ab[, paste0("f", 1:3, "_grid")])
gq <- as.matrix(qm$zsc_n) + 5     # printed -4..4 onto categories 1..9
round(colMeans(gq == gb[, closest]), 2)
#> fsc_f1 fsc_f2 fsc_f3 
#>   0.62   0.26   0.26
```

Strong for the dominant pair, far weaker for the rest.

The two differ where they are designed to differ. The classical analysis
flags a participant or it does not, while
[`compute_flags()`](https://rdazadda.github.io/bayesqm/reference/compute_flags.md)
returns the probability of that assignment, and
[`claims()`](https://rdazadda.github.io/bayesqm/reference/claims.md)
refuses to report a flag the posterior cannot stand behind. On this
panel the classical account reports three factors, and the decision
layer reads the same numbers as one shared viewpoint, a divergence the
package front page shows in full. Point summaries correspond where both
methods compute the same object. The Bayesian layer adds the uncertainty
and the rules.

## References

Akhtar-Danesh, N. (2023). Impact of factor rotation on Q-methodology
analysis. *PLOS ONE*, *18*(9), 1–11.
<https://doi.org/10.1371/journal.pone.0290728>

Zabala, A. (2014). Qmethod: A package to explore human perspectives
using Q methodology. *The R Journal*, *6*(2), 163–173.
<https://doi.org/10.32614/RJ-2014-032>
