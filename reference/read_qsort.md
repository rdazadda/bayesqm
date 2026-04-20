# Read Q-sort data from file

`read_qsort()` auto-detects the file format from extension and content
and dispatches to a specialised reader. The specialised readers are also
exported for explicit use:

- `read_qsort_csv()`, `read_qsort_excel()` for generic CSV / Excel (with
  HTMLQ / FlashQ / Ken-Q auto-detection baked in)

- `read_pqmethod()` for PQMethod `.DAT` files

- `read_kenq()` for Ken-Q JSON or CSV

- `read_kenq_excel()` for multi-sheet Ken-Q Excel (Type 1 and Type 2,
  both old and Ver2 sub-formats)

- `read_kade_zip()` for KADE ZIP archives

- `read_easyhtml_firebase()` for Easy-HTMLQ Firebase JSON

- `read_statements()` for a standalone statement-text file

All readers return a `qsort_data` object in `J x N` orientation
(statements as rows, participants as columns).

## Usage

``` r
read_qsort(file, format = "auto", ...)

read_qsort_csv(
  file,
  orientation = c("auto", "statements_rows", "participants_rows"),
  id_col = c("auto", "first", "none"),
  statements = NULL,
  distribution = NULL,
  ...
)

read_qsort_excel(
  file,
  sheet = 1,
  orientation = c("auto", "statements_rows", "participants_rows"),
  id_col = c("auto", "first", "none"),
  statements = NULL,
  distribution = NULL,
  ...
)

read_pqmethod(file, statements_file = NULL)

read_kenq(file, format = c("auto", "json", "csv"))

read_kenq_excel(file)

read_kade_zip(file)

read_easyhtml_firebase(file)

read_statements(file, column = 1, id_column = NULL)
```

## Arguments

- file:

  Path to the data file.

- format:

  For `read_qsort()`, `"auto"` (default) or one of `"csv"`, `"excel"`,
  `"pqmethod"`, `"kenq"`, `"kenq_excel"`, `"kade"`,
  `"easyhtml_firebase"`. For `read_kenq()`, one of `"auto"`, `"json"`,
  `"csv"`.

- ...:

  Passed to the underlying reader.

- orientation:

  For generic CSV/Excel: `"auto"`, `"statements_rows"`, or
  `"participants_rows"`.

- id_col:

  For generic CSV/Excel: `"auto"`, `"first"`, or `"none"`.

- statements, distribution:

  Optional overrides passed to
  [`qsort_data()`](https://rdazadda.github.io/bayesqm/reference/qsort_data.md).

- sheet:

  Excel sheet name or index (default `1`).

- statements_file:

  For PQMethod, optional companion statements file.

- column, id_column:

  For `read_statements()`: column index or name.

## Value

A `qsort_data` object, except `read_statements()` which returns a named
character vector.
