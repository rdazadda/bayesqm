# Choose K by the two-signal rule

Signal one is posterior-predictive adequacy: the extra-factor check sits
inside the central band and the person check shows no mutual unspanned
cluster. Signal two is parsimony: every factor is supported, meaning at
least two selected flags and at least one selected distinguishing
listing. The selection is the smallest adequate K with all factors
supported. When no factor is supported at any rung the verdict separates
two opposite situations: a panel sharing nothing (no factor ever
attracts two flags) and a panel so unanimous that flags abound but no
statement distinguishes any pair — a single shared viewpoint, reported
as such. When adequacy and support never coincide, both candidate
solutions are reported rather than forcing a winner.

## Usage

``` r
select_k(ladder, q = NULL, band = c(0.05, 0.95))
```

## Arguments

- ladder:

  A `bayesqm_ladder`.

- q:

  Re-select the support evidence at this level; `NULL` (the default)
  keeps the level the ladder stored.

- band:

  Central adequacy band for the extra-factor percentile (default
  `c(0.05, 0.95)`).

## Value

A `bayesqm_selection` with the verdict, the per-rung evidence table, and
the selected `K` (or `NA`).
