# Posterior-predictive checks of the fitted model

Three checks, each comparing the observed sorts with replicates drawn
from the fitted model: the agreement check (T1a) compares the observed
person-agreement matrix with replicated ones against a double-replicate
reference; the extra-factor check (T1b) locates the observed `(K+1)`-th
eigenvalue in its replicated distribution; and the paired-comparison
check (T2) compares standardized statement-pair margins, ties counted
one half. These are diagnostics to read, not tests to pass.

## Usage

``` r
check_fit(fit, draws = 100)
```

## Arguments

- fit:

  A `bayesqm_fit`.

- draws:

  Posterior draws used for replication (default 100).

## Value

A `bayesqm_checks` list: `agreement` (`p`), `extra_factor`
(`percentile`), and `paired` (`p`, per-statement `p_j`), with a print
method.

## Examples

``` r
check_fit(demo_fit(), draws = 20)
#> Posterior-predictive checks (20 replicated draws):
#>   agreement check (T1a):        p = 0.60
#>   extra-factor check (T1b):     observed e_(K+1) at percentile 0.35
#>   paired-comparison check (T2): p = 0.30 (worst statement 0.15)
#>   diagnostics to read, not tests to pass
```
