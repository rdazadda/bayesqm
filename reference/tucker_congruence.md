# Tucker's congruence and orthogonal Procrustes rotation

Linear-algebra utilities shared by MatchAlign and the recovery
assessments. `tucker_congruence(x, y)` computes
`sum(x*y) / sqrt(sum(x^2) * sum(y^2))`. `procrustes_rotation(X, Target)`
finds the orthogonal `R` minimising `||X R - Target||_F` and returns
`X %*% R` with `R` attached as attribute `"rotation"`.

## Usage

``` r
tucker_congruence(x, y)

procrustes_rotation(X, Target)
```

## Arguments

- x, y:

  Numeric vectors (for Tucker).

- X, Target:

  Matrices (for Procrustes).

## Value

Tucker returns a scalar; Procrustes returns the rotated matrix with a
`"rotation"` attribute.
