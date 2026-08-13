# Flip the pole of one factor

Reverses the sign of one factor's scores and loadings in every draw. The
polarity canon orients factors so defining sorts load positively; this
is the judgmental override.

## Usage

``` r
flip_factor(fit, factor)
```

## Arguments

- fit:

  A `bayesqm_fit`.

- factor:

  Factor index or `"f2"`-style name.

## Value

The fit with the factor's pole reversed.
