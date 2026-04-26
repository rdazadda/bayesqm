# qsort_data.R
# The qsort_data class: a small container for a Q-sort dataset with its
# statement labels, participant IDs, forced distribution, and metadata.
# Also the validation helpers shared by the readers and the constructor.


#' Construct a validated qsort_data object
#'
#' @description
#' `qsort_data()` is the canonical constructor for a Q-sort dataset.
#' `validate_qsort()`, `check_distribution()`, and `infer_distribution()`
#' are the validation helpers used internally by the constructor and
#' by the file readers. `parse_distribution()` accepts a numeric vector,
#' a comma-/semicolon-/space-separated string, or a text file containing
#' one of those.
#'
#' @param Y A `J x N` numeric matrix (statements as rows, participants
#'   as columns) or a data frame.
#' @param statements,participants Optional character vectors of IDs;
#'   default to `S1..SJ` and `P1..PN`.
#' @param distribution Optional integer vector of forced-distribution
#'   counts. Inferred from `Y[, 1]` when `NULL`.
#' @param metadata Optional named list of study-level info.
#' @param source Provenance string stored on the object.
#' @param validate If `TRUE` (default), run [validate_qsort()] and emit
#'   warnings / messages for any issues found.
#' @param qdata A `qsort_data` object or bare matrix, passed to
#'   `validate_qsort()`.
#' @param x Numeric vector, character string, or path to a file
#'   containing the forced distribution, passed to
#'   `parse_distribution()`.
#'
#' @return `qsort_data()` returns a `qsort_data` S3 list with fields
#'   `Y`, `statements`, `participants`, `distribution`, `metadata`, and
#'   `source`. `validate_qsort()` returns a list with `valid`, `issues`,
#'   `warnings`, and `summary`. `check_distribution()` returns a list
#'   with `ok`, `non_conforming`, and `grid_values`.
#'   `infer_distribution()` and `parse_distribution()` return integer
#'   vectors.
#'
#' @name qsort_data
#' @aliases validate_qsort check_distribution infer_distribution parse_distribution
#' @export
qsort_data <- function(Y, statements = NULL, participants = NULL,
                       distribution = NULL, metadata = list(),
                       source = "manual", validate = TRUE) {
  if (is.data.frame(Y)) Y <- as.matrix(Y)
  if (!is.matrix(Y)) stop("Y must be a matrix or data frame.")
  storage.mode(Y) <- "double"

  J <- nrow(Y); N <- ncol(Y)
  if (J < 1 || N < 1) stop("Y is empty.")

  if (is.null(statements)) {
    statements <- rownames(Y)
    if (is.null(statements)) statements <- paste0("S", seq_len(J))
  }
  if (length(statements) != J)
    stop("statements length (", length(statements),
         ") does not match nrow(Y) (", J, ").")

  if (is.null(participants)) {
    participants <- colnames(Y)
    if (is.null(participants)) participants <- paste0("P", seq_len(N))
  }
  if (length(participants) != N)
    stop("participants length (", length(participants),
         ") does not match ncol(Y) (", N, ").")

  rownames(Y) <- as.character(statements)
  colnames(Y) <- as.character(participants)

  if (is.null(distribution)) distribution <- infer_distribution(Y)

  obj <- structure(
    list(Y            = Y,
         statements   = as.character(statements),
         participants = as.character(participants),
         distribution = as.integer(distribution),
         metadata     = as.list(metadata),
         source       = source),
    class = "qsort_data")

  if (validate) {
    v <- validate_qsort(obj)
    for (msg in v$issues)   warning(msg, call. = FALSE)
    for (msg in v$warnings) message(msg)
  }
  obj
}


#' @rdname qsort_data
#' @export
validate_qsort <- function(qdata, distribution = NULL) {
  Y <- if (inherits(qdata, "qsort_data")) qdata$Y else as.matrix(qdata)
  d <- if (!is.null(distribution)) distribution
       else if (inherits(qdata, "qsort_data")) qdata$distribution
       else NULL

  issues <- warns <- character(0)
  J <- nrow(Y); N <- ncol(Y)

  if (J < 5)
    issues <- c(issues, paste0("Only J=", J, " statements; at least 5 recommended."))
  if (N < 3)
    issues <- c(issues, paste0("Only N=", N, " participants; at least 3 required."))

  n_nonfinite <- sum(!is.finite(Y))
  if (n_nonfinite > 0)
    issues <- c(issues, paste0(n_nonfinite, " non-finite entries (NA/NaN/Inf) in Y."))

  if (!is.null(d) && length(d) > 0) {
    if (sum(d) != J) {
      issues <- c(issues, paste0("Forced distribution sums to ", sum(d),
                                 " but Y has J=", J, " statements."))
    } else {
      ck <- check_distribution(Y, d)
      if (!ck$ok) {
        n_bad <- length(ck$non_conforming)
        warns <- c(warns, paste0(
          n_bad, " of ", N, " participants do not match the forced distribution ",
          "(columns: ", paste(head(ck$non_conforming, 10), collapse = ", "),
          if (n_bad > 10) ", ..." else "", ")."))
      }
    }
  }

  list(valid    = length(issues) == 0,
       issues   = issues,
       warnings = warns,
       summary  = list(J = J, N = N, n_nonfinite = n_nonfinite))
}


#' @rdname qsort_data
#' @export
check_distribution <- function(Y, distribution) {
  n_pos <- length(distribution)
  if (n_pos %% 2 == 1) {
    half <- (n_pos - 1) / 2
    grid_vals <- seq(-half, half)
  } else {
    half <- n_pos / 2
    grid_vals <- c(seq(-half, -1), seq(1, half))
  }

  non_conforming <- integer(0)
  for (i in seq_len(ncol(Y))) {
    tab <- tabulate(match(Y[, i], grid_vals), nbins = n_pos)
    if (!all(tab == distribution)) non_conforming <- c(non_conforming, i)
  }
  list(ok             = length(non_conforming) == 0,
       non_conforming = non_conforming,
       grid_values    = grid_vals)
}


#' @rdname qsort_data
#' @export
infer_distribution <- function(Y) {
  vals <- Y[is.finite(Y)]
  if (length(vals) == 0) return(integer(0))
  grid_vals <- sort(unique(vals))
  col1 <- Y[, 1]
  col1 <- col1[is.finite(col1)]
  as.integer(tabulate(match(col1, grid_vals), nbins = length(grid_vals)))
}


#' @rdname qsort_data
#' @export
parse_distribution <- function(x) {
  if (is.numeric(x)) return(as.integer(x))
  if (!is.character(x) || length(x) != 1)
    stop("parse_distribution() expects a numeric vector or a single string.")

  if (file.exists(x)) x <- readLines(x, warn = FALSE)[1]
  x <- trimws(x)

  if (grepl("[,;]", x)) {
    v <- suppressWarnings(as.numeric(strsplit(x, "\\s*[,;]\\s*")[[1]]))
    if (!any(is.na(v))) return(as.integer(v))
  }

  v <- suppressWarnings(as.numeric(strsplit(x, "\\s+")[[1]]))
  if (!any(is.na(v))) return(as.integer(v))

  stop("Could not parse distribution from: ", x)
}


#' Print, summary, and matrix conversion for qsort_data
#'
#' @param x,object A `qsort_data` object.
#' @param ... Unused.
#' @return `print()` and `summary()` return the input invisibly;
#'   `as.matrix()` returns the `J x N` Q-sort matrix.
#' @name qsort_data-methods
#' @export
print.qsort_data <- function(x, ...) {
  cat("Q-sort data\n")
  cat("  statements  :", length(x$statements),
      "  participants :", length(x$participants), "\n")
  cat("  distribution:", paste(x$distribution, collapse = " "),
      "  (sum =", sum(x$distribution), ")\n")
  cat("  value range : [", min(x$Y, na.rm = TRUE), ", ",
      max(x$Y, na.rm = TRUE), "]\n", sep = "")
  cat("  source      :", x$source, "\n")
  invisible(x)
}


#' @rdname qsort_data-methods
#' @export
summary.qsort_data <- function(object, ...) {
  v <- validate_qsort(object)
  cat("Q-sort data summary\n")
  cat("  statements  :", length(object$statements), "\n")
  cat("  participants:", length(object$participants), "\n")
  cat("  distribution:", paste(object$distribution, collapse = " "), "\n")
  cat("  source      :", object$source, "\n")
  if (length(v$issues) > 0) {
    cat("  issues:\n")
    for (msg in v$issues)   cat("    - ", msg, "\n", sep = "")
  }
  if (length(v$warnings) > 0) {
    cat("  warnings:\n")
    for (msg in v$warnings) cat("    - ", msg, "\n", sep = "")
  }
  invisible(object)
}


#' @rdname qsort_data-methods
#' @export
as.matrix.qsort_data <- function(x, ...) x$Y
