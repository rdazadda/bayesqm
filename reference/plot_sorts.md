# Preview every participant's sort

Draws each participant's completed sort as their own pyramid: one tile
per statement, stacked in its grid column, colored along the
disagree-agree axis. This is the look-at-the-decisions-first view: run
it straight after import, before any analysis, to see how every
participant grouped the statements. `plot(qdata)` does the same.

## Usage

``` r
plot_sorts(x, participants = NULL, per_page = 12, labels = NULL, cex = NULL)
```

## Arguments

- x:

  A `qsort_data` object or a `J x N` matrix of sorts.

- participants:

  Which participants to draw (names or indices); `NULL` (default) draws
  everyone.

- per_page:

  How many pyramids per page (default up to 12, arranged automatically);
  further participants continue on the next page.

- labels:

  Optional statement labels for the tiles (defaults to the statement
  ids).

- cex:

  Tile label size; `NULL` (default) adapts to the tallest column.

## Value

The input, invisibly.

## Examples

``` r
distr <- c(1, 2, 3, 2, 1)
set.seed(1)
Y <- replicate(4, {
  r <- integer(9)
  r[order(rnorm(9))] <- rep(seq_along(distr), distr)
  r - 3                                  # printed labels -2..+2
})
plot_sorts(qsort_data(Y, distribution = distr, validate = FALSE))

```
