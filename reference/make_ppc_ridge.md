# Posterior predictive RMSE ridgeline across K

Draws a ridgeline density of the posterior predictive correlation-matrix
RMSE (\\RMSE_R\\) at every K in `run`, with a median tick per ridge.

## Usage

``` r
make_ppc_ridge(run, title = NULL)
```

## Arguments

- run:

  A `bayesqm_run`.

- title:

  Optional panel title.

## Value

A `ggplot` object.
