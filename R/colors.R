# colors.R
# A bayesplot-style colour-scheme system. Plots in this package read
# their palette through bayesqm_colors(); setting a scheme with
# bayesqm_set_colors() reshapes every plot without touching user code.
# A custom named list can also be supplied.


.bq_env <- new.env(parent = emptyenv())
.bq_env$scheme <- "sorts"
.bq_env$custom <- NULL


# sorts-ramp semantic colours shared by the verdict-coloured plots
.bq_verdict <- c(distinguishing = "#922B21", consensus = "#17A589",
                 indeterminate = "grey72")


# placement-certainty scale for the factor array: light floor so low
# certainty stays visibly pale, dark navy top
.bq_certainty <- c("#DEEBF7", "#4292C6", "#08306B")


# Built-in schemes. Each provides six named slots consumed by the
# plotting code: a dark line/point colour, an accent colour (used
# sparingly for warning-rules and decision marks), a grey for axes /
# zero rules, a lighter grey for descriptive cut-offs, a "fill" for
# histograms / shaded bands, and "qual", the qualitative palette for
# factor identity, drawn from the plot_sorts() colour ramp (never
# cycled, shared by all schemes so factor colours stay stable when the
# scheme changes).
.bq_schemes <- list(
  sorts = list(
    dark     = "#1B4F72",
    accent   = "#922B21",
    grey     = "grey40",
    gridgrey = "grey75",
    fill     = "#D6EAF8",
    qual     = c("#2E86C1", "#E67E22", "#17A589", "#6C3483",
                 "#E74C3C", "#922B21", "#F4D03F", "#5D6D7E")
  ),
  blue = list(
    dark     = "#03306b",
    accent   = "#8F272C",
    grey     = "grey40",
    gridgrey = "grey75",
    fill     = "#b3cde0",
    qual     = c("#2E86C1", "#E67E22", "#17A589", "#6C3483",
                 "#E74C3C", "#922B21", "#F4D03F", "#5D6D7E")
  ),
  teal = list(
    dark     = "#00441b",
    accent   = "#b2182b",
    grey     = "grey40",
    gridgrey = "grey75",
    fill     = "#a8ddb5",
    qual     = c("#2E86C1", "#E67E22", "#17A589", "#6C3483",
                 "#E74C3C", "#922B21", "#F4D03F", "#5D6D7E")
  ),
  red = list(
    dark     = "#67001f",
    accent   = "#2166ac",
    grey     = "grey40",
    gridgrey = "grey75",
    fill     = "#f4a582",
    qual     = c("#2E86C1", "#E67E22", "#17A589", "#6C3483",
                 "#E74C3C", "#922B21", "#F4D03F", "#5D6D7E")
  ),
  purple = list(
    dark     = "#3f007d",
    accent   = "#b35806",
    grey     = "grey40",
    gridgrey = "grey75",
    fill     = "#bcbddc",
    qual     = c("#2E86C1", "#E67E22", "#17A589", "#6C3483",
                 "#E74C3C", "#922B21", "#F4D03F", "#5D6D7E")
  ),
  grey = list(
    dark     = "#1a1a1a",
    accent   = "#8F272C",
    grey     = "grey40",
    gridgrey = "grey75",
    fill     = "#cccccc",
    qual     = c("#2E86C1", "#E67E22", "#17A589", "#6C3483",
                 "#E74C3C", "#922B21", "#F4D03F", "#5D6D7E")
  )
)


#' Get or set the bayesqm colour scheme
#'
#' @description
#' Every plot in the package reads its palette through
#' `bayesqm_colors()`. Call `bayesqm_set_colors()` to switch the active
#' scheme for every subsequent plot. The available built-in schemes are
#' `"sorts"` (default, the [plot_sorts()] colour family), `"blue"`,
#' `"teal"`, `"red"`, `"purple"`, and `"grey"`.
#' For full control, pass a named list with slots `dark`, `accent`,
#' `grey`, `gridgrey`, and `fill`.
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
#' old <- bayesqm_set_colors("teal")
#' bayesqm_colors()[["fill"]]
#' bayesqm_set_colors(old)
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
  required <- c("dark", "accent", "grey", "gridgrey", "fill")

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
    if (is.null(scheme$qual)) scheme$qual <- .bq_schemes$blue$qual
    old <- .bq_env$scheme
    .bq_env$custom <- scheme[c(required, "qual")]
    .bq_env$scheme <- "custom"
    return(invisible(old))
  }

  stop("scheme must be a character name or a named list of colours.")
}