# save_plot.R
# Opens the appropriate graphics device for the file extension, evaluates
# the (lazily evaluated) plot expression on it, closes the device, and
# returns the path. Defaults to a 7.2 x 5 inch figure at 300 dpi for
# raster formats.


#' Save a bayesqm plot to file
#'
#' @description
#' Opens a graphics device chosen from the file extension (`.pdf`,
#' `.svg`, `.png`, `.tiff`, `.jpeg`), evaluates `expr` so whatever it
#' draws lands on that device, and closes the device. `expr` is lazily
#' evaluated, so a call like `save_bayesqm_plot("fig.pdf", plot(fit))`
#' does not draw to the current screen device first. If `expr` returns
#' a `ggplot` object (for example, from [ggplot2::autoplot()]), it is
#' `print()`ed onto the device.
#'
#' @param file Output path. Extension determines the device.
#' @param expr Plotting expression (lazily evaluated).
#' @param width,height Dimensions in inches. Defaults to a 7.2 x 5
#'   inch two-column journal figure.
#' @param dpi Resolution for raster formats (`png`, `tiff`, `jpeg`).
#'
#' @return The `file` path, invisibly.
#'
#' @examples
#' f <- file.path(tempdir(), "fig.pdf")
#' save_bayesqm_plot(f, plot(1:10))
#' unlink(f)
#'
#' @export
save_bayesqm_plot <- function(file, expr,
                              width  = 7.2,
                              height = 5,
                              dpi    = 300) {
  ext <- tolower(tools::file_ext(file))
  if (!nzchar(ext))
    stop("file must have an extension (pdf, svg, png, tiff, jpeg).")

  switch(ext,
    pdf  = grDevices::pdf(file, width = width, height = height),
    svg  = grDevices::svg(file, width = width, height = height),
    png  = grDevices::png(file,  width = width  * dpi,
                                 height = height * dpi,
                                 res    = dpi),
    tiff = grDevices::tiff(file, width = width  * dpi,
                                 height = height * dpi,
                                 res    = dpi),
    jpeg = ,
    jpg  = grDevices::jpeg(file, width = width  * dpi,
                                 height = height * dpi,
                                 res    = dpi,
                                 quality = 95),
    stop("Unsupported extension '", ext,
         "'. Use pdf, svg, png, tiff, or jpeg."))

  on.exit(grDevices::dev.off(), add = TRUE)

  result <- force(expr)
  if (inherits(result, c("ggplot", "gg"))) print(result)

  invisible(file)
}
