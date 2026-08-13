# Save a bayesqm plot to file

Opens a graphics device chosen from the file extension (`.pdf`, `.svg`,
`.png`, `.tiff`, `.jpeg`), evaluates `expr` so whatever it draws lands
on that device, and closes the device. `expr` is lazily evaluated, so a
call like `save_bayesqm_plot("fig.pdf", plot(fit))` does not draw to the
current screen device first. If `expr` returns a `ggplot` object (for
example, from
[`ggplot2::autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)),
it is [`print()`](https://rdrr.io/r/base/print.html)ed onto the device.

## Usage

``` r
save_bayesqm_plot(file, expr, width = 7.2, height = 5, dpi = 300)
```

## Arguments

- file:

  Output path. Extension determines the device.

- expr:

  Plotting expression (lazily evaluated).

- width, height:

  Dimensions in inches. Defaults to a 7.2 x 5 inch two-column journal
  figure.

- dpi:

  Resolution for raster formats (`png`, `tiff`, `jpeg`).

## Value

The `file` path, invisibly.

## Examples

``` r
f <- file.path(tempdir(), "fig.pdf")
save_bayesqm_plot(f, plot(1:10))
unlink(f)
```
