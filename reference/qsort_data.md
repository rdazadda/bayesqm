# Construct a validated qsort_data object

`qsort_data()` is the canonical constructor for a Q-sort dataset.
`validate_qsort()`, `check_distribution()`, and `infer_distribution()`
are the validation helpers used internally by the constructor and by the
file readers. `parse_distribution()` accepts a numeric vector, a
comma-/semicolon-/space-separated string, or a text file containing one
of those.

## Usage

``` r
qsort_data(
  Y,
  statements = NULL,
  participants = NULL,
  distribution = NULL,
  metadata = list(),
  source = "manual",
  validate = TRUE
)

validate_qsort(qdata, distribution = NULL)

check_distribution(Y, distribution)

infer_distribution(Y)

parse_distribution(x)
```

## Arguments

- Y:

  A `J x N` numeric matrix (statements as rows, participants as columns)
  or a data frame.

- statements, participants:

  Optional character vectors of IDs; default to `S1..SJ` and `P1..PN`.

- distribution:

  Optional integer vector of forced-distribution counts. Inferred from
  `Y[, 1]` when `NULL`.

- metadata:

  Optional named list of study-level info.

- source:

  Provenance string stored on the object.

- validate:

  If `TRUE` (default), run `validate_qsort()` and emit warnings /
  messages for any issues found.

- qdata:

  A `qsort_data` object or bare matrix, passed to `validate_qsort()`.

- x:

  Numeric vector, character string, or path to a file containing the
  forced distribution, passed to `parse_distribution()`.

## Value

`qsort_data()` returns a `qsort_data` S3 list with fields `Y`,
`statements`, `participants`, `distribution`, `metadata`, and `source`.
`validate_qsort()` returns a list with `valid`, `issues`, `warnings`,
and `summary`. `check_distribution()` returns a list with `ok`,
`non_conforming`, and `grid_values`. `infer_distribution()` and
`parse_distribution()` return integer vectors.
