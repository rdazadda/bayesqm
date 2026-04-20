# qmethod-style import aliases

Thin aliases that forward to
[`read_pqmethod()`](https://rdazadda.github.io/bayesqm/reference/read_qsort.md),
[`read_qsort()`](https://rdazadda.github.io/bayesqm/reference/read_qsort.md)
(HTMLQ auto-detection),
[`read_kenq()`](https://rdazadda.github.io/bayesqm/reference/read_qsort.md),
and
[`read_easyhtml_firebase()`](https://rdazadda.github.io/bayesqm/reference/read_qsort.md).
These exist only so scripts written against the `qmethod` package
continue to work; new code should call the `read_*` functions directly.

## Usage

``` r
import.pqmethod(file, ...)

import.htmlq(file, ...)

import.kenq(file, ...)

import.easyhtmlq(file, ...)
```

## Arguments

- file:

  Path to the data file.

- ...:

  Passed to the underlying reader.

## Value

A `qsort_data` object.
