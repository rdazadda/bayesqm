# Person-level partition log-likelihoods

GHK-simulated log-likelihood of each participant's sort under each kept
posterior draw (thinned to `draws`), the input PSIS-LOO needs. The GHK
seed depends only on the draw index and the person, never on `K`, so
log-likelihoods are common-random-number comparable across a ladder of
fits.

## Usage

``` r
loglik_person(fit, draws = 100, R = 64, seed = 1)
```

## Arguments

- fit:

  A `bayesqm_fit`.

- draws:

  Posterior draws to evaluate (default 100, thinned evenly).

- R:

  GHK replications per evaluation (default 64).

- seed:

  Base seed for the GHK draws (default 1).

## Value

A `draws x N` matrix of log-likelihoods.
