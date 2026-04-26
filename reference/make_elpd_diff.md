# Delta-ELPD plot with Sivula band, peak, and adopted-K annotations

Draws \\\Delta\\ELPD against K with +/- 1.96 SE whiskers, shades the
Sivula rejection band (\\\|\Delta \mathrm{ELPD}\| \< 4\\), and marks the
Sivula-selected K (red triangle), the ELPD peak (blue square), and an
optional adopted K (orange diamond).

## Usage

``` r
make_elpd_diff(run, title = NULL, adopted = NULL)
```

## Arguments

- run:

  A `bayesqm_run` object.

- title:

  Optional panel title.

- adopted:

  Integer K adopted by the analyst. Marked with the orange diamond.
  `NULL` suppresses this annotation.

## Value

A `ggplot` object.
