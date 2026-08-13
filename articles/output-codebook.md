# Output codebook

Every column of every table the package reports, defined in one place.
The examples run on the small demonstration fit, so the numbers here are
illustrations, not findings.

## compute_loadings()

``` r

head(compute_loadings(fit), 3)
#>   participant f1_loading   f1_lower  f1_upper f2_loading   f2_lower   f2_upper
#> 1          P1  0.6975806  0.3510298 0.8852994 -0.3502945 -0.6733120 0.06053878
#> 2          P2 -0.1185755 -0.4985179 0.2018393  0.6775444  0.1103558 0.93709993
#> 3          P3  0.7164964  0.4107087 0.9122487  0.1511020 -0.3070454 0.51003980
#>     spread
#> 1 1.525988
#> 2 1.280882
#> 3 1.381425
```

One row per participant. `f*_loading` is the posterior mean loading on
the bounded correlation scale, between -1 and 1. `f*_lower` and
`f*_upper` bound the credible interval at the fit’s stored probability,
95 percent by default. `spread` is the posterior mean of the
participant’s person spread, the size of their systematic signal.
Calling with `prob = 0.5` returns the same table with 50 percent
intervals for nested plotting.

## compute_flags()

``` r

head(compute_flags(fit), 3)
#>   participant factor sign flag_prob unclassified_prob selected
#> 1          P1     f1    1     0.840             0.120    FALSE
#> 2          P2     f2    1     0.795             0.195    FALSE
#> 3          P3     f1    1     0.875             0.120    FALSE
```

One row per participant. `factor` is the participant’s most probable
factor, `sign` its pole, 1 for a defining sort and -1 for a mirrored
one. `flag_prob` is the posterior probability that the participant
defines that factor, both poles combined, and `unclassified_prob` the
probability that no factor claims them. `selected` marks the flags the
false-discovery rule reports at the chosen level. The table carries two
attributes, `expected_false`, the expected number of false flags among
the selected, and `phi`, the full probability matrix over every factor,
pole, and the unclassified state.

## compute_zscores()

``` r

head(compute_zscores(fit), 3)
#>   statement     f1_zsc   f1_lower    f1_upper     f2_zsc   f2_lower   f2_upper
#> 1        S1 -0.7642786 -1.4925646 0.006103133 -1.6875007 -2.5266156 -0.6412988
#> 2        S2  0.2387391 -0.5696067 1.057480468  0.7050000 -0.3868269  1.8736307
#> 3        S3 -0.8688942 -1.6855842 0.051724430 -0.2481569 -1.2173831  0.7538681
```

One row per statement. `f*_zsc` is the posterior mean statement score in
z units under each factor, with `f*_lower` and `f*_upper` its interval.
Scores are computed from the aligned draws, so they are comparable
across factors.

## compute_factor_array()

``` r

head(compute_factor_array(fit), 3)
#>   statement f1_grid f2_grid
#> 1        S1       4       1
#> 2        S2       5       6
#> 3        S3       3       3
```

One row per statement. `f*_grid` is the reported grid column for the
statement under each factor, quota-exact by construction, numbered as
consecutive categories from 1 to the number of columns. Attribute
`certainty` is the posterior probability of each placement, the shading
in
[`plot_factor_array()`](https://rdazadda.github.io/bayesqm/reference/plot_factor_array.md),
and `footrule_disagreement` records how far the reported array sits from
the unconstrained posterior ranking.

## compute_qdc()

``` r

qdc <- compute_qdc(fit)
head(qdc, 3)
#>   statement f1_dist_prob f2_dist_prob consensus_prob       verdict
#> 1        S1         0.30         0.30          0.250 indeterminate
#> 2        S2         0.16         0.16          0.450 indeterminate
#> 3        S3         0.17         0.17          0.445 indeterminate
```

One row per statement. `f*_dist_prob` is the probability that the
statement distinguishes that factor from every other, and
`consensus_prob` the probability that all factors place it within one
grid column of each other. `verdict` is the resulting three-way call,
distinguishing with its factors named, consensus, or indeterminate.

The `contrasts` attribute is the long table behind the verdicts:

``` r

head(attr(qdc, "contrasts"), 3)
#>   statement  pair     median     lower     upper exceed_prob diff_column_prob
#> 1        S1 f1-f2  0.9708457 -0.240445 1.9006403        0.30             0.86
#> 2        S2 f1-f2 -0.4525552 -1.902053 0.9999716        0.16             0.78
#> 3        S3 f1-f2 -0.6280758 -1.922185 0.4566944        0.17             0.77
#>   selected stars
#> 1    FALSE      
#> 2    FALSE      
#> 3    FALSE
```

One row per statement and factor pair. `median`, `lower`, and `upper`
summarize the posterior score contrast. `exceed_prob` is the probability
that the contrast exceeds the critical difference, `diff_column_prob`
the probability that the two factors place the statement in different
grid columns, `selected` the false-discovery selection at the first
level, and `stars` the two-level marking, one star for a selected
contrast and two when the stricter level is also cleared. The attributes
`delta_kl`, `delta_kl99`, and `delta_grid` carry the two critical
differences and the one-column consensus region.

## factor_characteristics()

``` r

factor_characteristics(fit)
#>   factor flagged defining_modal defining_mean defining_lower defining_upper
#> 1     f1       0              4         3.585              2              5
#> 2     f2       0              2         2.265              1              4
#>   score_spread reliability
#> 1    0.4153759          NA
#> 2    0.5072720          NA
```

One row per factor. `flagged` counts the selected flags, and
`defining_modal`, `defining_mean`, `defining_lower`, and
`defining_upper` summarize the posterior number of defining sorts.
`score_spread` is the average posterior spread of the factor’s statement
scores, and `reliability` the mean replicate reliability of the factor’s
flagged participants, `NA` when no participant is flagged. The
`score_correlations` attribute holds the posterior mean correlations
between factor score columns.

## claims()

``` r

claims(fit, q = 0.25)
#> Selected claims at q = 0.25 (posterior expected FDR):
#>   flags             6 participants selected (expected false 1.06)
#>   distinguishing    9 listings selected (expected false 1.88)
#>   consensus         0 statements selected (expected false 0.00)
#>   stars             4 pairwise selected (expected false 0.62)
```

Four tables and a rule. `flags`, `distinguishing`, `consensus`, and
`stars` list every claim the false-discovery rule selects at level `q`,
each row carrying its posterior probability, and `expected_false` gives
the expected number of false claims inside each family.

## check_fit() and check_persons()

``` r

check_fit(fit, draws = 20)
#> Posterior-predictive checks (20 replicated draws):
#>   agreement check (T1a):        p = 0.60
#>   extra-factor check (T1b):     observed e_(K+1) at percentile 0.35
#>   paired-comparison check (T2): p = 0.30 (worst statement 0.15)
#>   diagnostics to read, not tests to pass
```

`agreement` compares the observed person-to-model agreement with its
replicated reference and reports a two-sided probability. `paired` does
the same for paired comparisons. `extra_factor` reports where the next
unused eigenvalue falls among the model’s replications, the percentile
the choice-of-K rule reads.

``` r

pc <- check_persons(fit, draws = 10, mixes = 20)
head(pc, 3)
#> Person check: fits 3, no_shared 0, unspanned 0, atypical 0 
#>  participant    m    w partner partner_index verdict
#>           P1 0.75 0.67      P3             3    fits
#>           P2 0.66 0.71      P4             4    fits
#>           P3 0.73 0.71      P5             5    fits
```

One row per participant. `m` is agreement with the model’s
reconstruction, `w` agreement with their own mixed replicates, and
`verdict` the resulting call, with `partner` naming the nearest other
sorter when a shared viewpoint sits outside the model.

## crib_sheet()

``` r

head(crib_sheet(fit), 3)
#>   statement factor p_top p_bottom p_highest p_lowest
#> 1        S1     f1 0.000    0.065      0.93     0.07
#> 2        S2     f1 0.005    0.000      0.23     0.77
#> 3        S3     f1 0.000    0.120      0.20     0.80
```

One row per statement and factor. `p_top` and `p_bottom` are the
probabilities of landing in the most extreme agree and disagree columns,
`p_highest` and `p_lowest` of being that factor’s single most and least
agreed statement. These are the shortlists used when interpreting a
factor.

## select_k()

Run on a ladder of fits,
[`select_k()`](https://rdazadda.github.io/bayesqm/reference/select_k.md)
returns `K`, the verdict, and a table with one row per candidate.
`extra_factor` is the posterior-predictive percentile, `adequate`
whether it sits in the band with no unspanned cluster,
`factors_supported` how many factors earn at least two selected flags
and one selected distinguishing statement, and `all_supported` whether
every factor does. The `detail` element carries the same support
information factor by factor, and the plot method draws the whole
decision.
