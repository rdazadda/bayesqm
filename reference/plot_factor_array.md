# The factor array on its grid

The reported array for one factor drawn as the physical sorting grid:
columns are grid positions with their quota heights, each cell carries
its statement, and cell shading shows how certain the placement is (the
posterior probability of that statement landing in that column).

## Usage

``` r
plot_factor_array(fit, factor = 1, labels = NULL)
```

## Arguments

- fit:

  A `bayesqm_fit`.

- factor:

  Which factor to draw (index or `"f2"`-style name; default 1).

- labels:

  Optional statement labels (defaults to the statement ids).

## Value

`fit`, invisibly.
