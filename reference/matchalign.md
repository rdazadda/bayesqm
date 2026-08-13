# MatchAlign post-processing for partition-model draws

Resolves rotational, sign, and label-permutation ambiguity in posterior
draws by the MatchAlign procedure of Poworoznek et al. (2025), adapted
to the partition model: varimax rotation of the loadings per draw, a
pivot draw at the median condition number (overridable), pivot polarity
fixed so each factor's loadings skew positive (defining sorts load
positively), greedy signed matching of loading columns to the pivot, and
a Procrustes rotation. A final pass re-orients every draw to the varimax
of the aligned mean loadings, re-signed to positive skew, so the
delivered orientation does not inherit one draw's sampling noise. One
rotation is applied to loadings and scores alike, and the loading scale
`sigma` is carried through.

Called for its side effect on the draw arrays of an engine-level fit;
users normally receive already-aligned draws from
[`fit_bayesian()`](https://rdazadda.github.io/bayesqm/reference/fit_bayesian.md)
and need this only to realign under a different pivot.

## Usage

``` r
matchalign(fit, pivot = NULL)
```

## Arguments

- fit:

  A fit carrying draw arrays `F` (`[T, J, K]`), `Lambda` (`[T, N, K]`),
  `sigma` (`[T, K]`), and `K`.

- pivot:

  Optional draw index to use as the alignment pivot. `NULL` (the
  default) selects the draw whose loading condition number sits at the
  median.

## Value

The fit with aligned `F`, `Lambda`, and `sigma`, and the chosen `pivot`
index appended.

## References

Poworoznek, E., Anceschi, N., Ferrari, F., & Dunson, D. (2025).
Efficiently Resolving Rotational Ambiguity in Bayesian Matrix Sampling
with Matching. *Bayesian Analysis*.
