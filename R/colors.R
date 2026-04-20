# colors.R
# A bayesplot-style colour-scheme system. Plots in this package read
# their palette through bayesqm_colors(); setting a scheme with
# bayesqm_set_colors() reshapes every plot without touching user code.
# A custom named list can also be supplied.


.bq_env <- new.env(parent = emptyenv())
.bq_env$scheme <- "blue"
.bq_env$custom <- NULL


# Built-in schemes. Each provides seven named slots consumed by the
# plotting code: light/mid/dark fills and outlines, an accent colour
# (used sparingly for warning-rules and flagged points), a grey for
# axes / zero rules, a lighter grey for descriptive cut-offs, and a
# "fill" for histograms / shaded densities.
.bq_schemes <- list(
  blue = list(
    light    = "#d1e1ec",
    mid      = "#6497b1",
    dark     = "#03306b",
    accent   = "#8F272C",
    grey     = "grey40",
    gridgrey = "grey75",
    fill     = "#b3cde0"
  ),
  teal = list(
    light    = "#d9f0ea",
    mid      = "#66c2a5",
    dark     = "#00441b",
    accent   = "#b2182b",
    grey     = "grey40",
    gridgrey = "grey75",
    fill     = "#a8ddb5"
  ),
  red = list(
    light    = "#fddbc7",
    mid      = "#d6604d",
    dark     = "#67001f",
    accent   = "#2166ac",
    grey     = "grey40",
    gridgrey = "grey75",
    fill     = "#f4a582"
  ),
  purple = list(
    light    = "#dadaeb",
    mid      = "#807dba",
    dark     = "#3f007d",
    accent   = "#b35806",
    grey     = "grey40",
    gridgrey = "grey75",
    fill     = "#bcbddc"
  ),
  grey = list(
    light    = "#e5e5e5",
    mid      = "#888888",
    dark     = "#1a1a1a",
    accent   = "#8F272C",
    grey     = "grey40",
    gridgrey = "grey75",
    fill     = "#cccccc"
  )
)


#' Get or set the bayesqm colour scheme
#'
#' @description
#' Every plot in the package reads its palette through
#' `bayesqm_colors()`. Call `bayesqm_set_colors()` to switch the active
#' scheme for every subsequent plot. The available built-in schemes
#' are `"blue"` (default), `"teal"`, `"red"`, `"purple"`, and `"grey"`.
#' For full control, pass a named list with slots `light`, `mid`,
#' `dark`, `accent`, `grey`, `gridgrey`, and `fill`.
#'
#' @param scheme Character name of a built-in scheme, or a named list
#'   of colours with the slot names listed in the description.
#'
#' @return `bayesqm_colors()` returns the active palette as a named
#'   list. `bayesqm_set_colors()` returns the previous scheme name,
#'   invisibly.
#'
#' @examples
#' bayesqm_colors()
#' \dontrun{
#' bayesqm_set_colors("teal")
#' plot(fit)
#' bayesqm_set_colors("blue")  # restore default
#' }
#'
#' @name bayesqm-colors
#' @aliases bayesqm_colors bayesqm_set_colors
#' @export
bayesqm_colors <- function() {
  if (identical(.bq_env$scheme, "custom") && !is.null(.bq_env$custom))
    return(.bq_env$custom)
  .bq_schemes[[.bq_env$scheme]]
}


#' @rdname bayesqm-colors
#' @export
bayesqm_set_colors <- function(scheme) {
  required <- c("light", "mid", "dark", "accent",
                "grey", "gridgrey", "fill")

  if (is.character(scheme) && length(scheme) == 1L) {
    if (!scheme %in% names(.bq_schemes))
      stop("Unknown scheme '", scheme, "'. Available: ",
           paste(names(.bq_schemes), collapse = ", "))
    old <- .bq_env$scheme
    .bq_env$scheme <- scheme
    .bq_env$custom <- NULL
    return(invisible(old))
  }

  if (is.list(scheme)) {
    missing <- setdiff(required, names(scheme))
    if (length(missing))
      stop("Custom scheme is missing slot(s): ",
           paste(missing, collapse = ", "))
    old <- .bq_env$scheme
    .bq_env$custom <- scheme[required]
    .bq_env$scheme <- "custom"
    return(invisible(old))
  }

  stop("scheme must be a character name or a named list of colours.")
}


# Kept as an internal shim so existing call sites don't break if the
# public getter is ever renamed.
.bq_col <- function() bayesqm_colors()
