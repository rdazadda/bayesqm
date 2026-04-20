# MatchAlign post-processing for Bayesian factor draws

Resolves rotational, sign, and label-permutation ambiguity in posterior
draws of a factor model by the three-step MatchAlign procedure of
Poworoznek et al. (2025): varimax rotation per draw, median-condition
pivot selection, greedy L2 signed-permutation matching, and Procrustes
rotation.

## Usage

``` r
matchalign(Lambda_draws, F_draws)
```

## Arguments

- Lambda_draws:

  Array of shape `[T, N, K]` of loading draws.

- F_draws:

  Array of shape `[T, J, K]` of factor-score draws.

## Value

A list with aligned `Lambda` and `Fmat` arrays, a `congruence` matrix of
per-draw Tucker-phi per factor, and the `pivot` index used.

## References

Poworoznek et al. (2025). *Bayesian Analysis*.
