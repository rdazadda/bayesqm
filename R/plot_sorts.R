# plot_sorts.R
# The data preview: every participant's completed sort drawn as their own
# pyramid, before any model runs. Adopted from the author's canhrQsort
# design: tiles stacked per grid column, a diverging ramp across the
# disagree-agree axis, luminance-adaptive statement labels, and the
# printed rank values on the axis.


# diverging ramp across grid columns (disagree -> agree)
#' @keywords internal
#' @noRd
.rank_ramp <- function(C) {
  grDevices::colorRampPalette(
    c("#6C3483", "#2E86C1", "#17A589", "#F4D03F",
      "#E67E22", "#E74C3C", "#922B21"))(C)
}

# white on dark tiles, near-black on light ones
#' @keywords internal
#' @noRd
.tile_text_col <- function(fill) {
  vapply(fill, function(col) {
    v <- grDevices::col2rgb(col)
    lum <- (0.299 * v[1] + 0.587 * v[2] + 0.114 * v[3]) / 255
    if (lum > 0.5) "gray20" else "white"
  }, character(1))
}


#' Preview every participant's sort
#'
#' @description
#' Draws each participant's completed sort as their own pyramid: one tile
#' per statement, stacked in its grid column, colored along the
#' disagree-agree axis. This is the look-at-the-decisions-first view:
#' run it straight after import, before any analysis, to see how every
#' participant grouped the statements. `plot(qdata)` does the same.
#'
#' @param x A `qsort_data` object or a `J x N` matrix of sorts.
#' @param participants Which participants to draw (names or indices);
#'   `NULL` (default) draws everyone.
#' @param per_page How many pyramids per page (default up to 12,
#'   arranged automatically); further participants continue on the next
#'   page.
#' @param labels Optional statement labels for the tiles (defaults to the
#'   statement ids).
#' @param cex Tile label size; `NULL` (default) adapts to the tallest
#'   column.
#'
#' @return The input, invisibly.
#'
#' @examples
#' distr <- c(1, 2, 3, 2, 1)
#' set.seed(1)
#' Y <- replicate(4, {
#'   r <- integer(9)
#'   r[order(rnorm(9))] <- rep(seq_along(distr), distr)
#'   r - 3                                  # printed labels -2..+2
#' })
#' plot_sorts(qsort_data(Y, distribution = distr, validate = FALSE))
#'
#' @export
plot_sorts <- function(x, participants = NULL, per_page = 12,
                       labels = NULL, cex = NULL) {
  qd <- if (inherits(x, "qsort_data")) x
        else qsort_data(as.matrix(x), validate = FALSE)
  Y <- qd$Y
  J <- nrow(Y); N <- ncol(Y)
  grid_vals <- sort(unique(as.vector(Y[is.finite(Y)])))
  C <- length(grid_vals)
  max_h <- max(vapply(seq_len(N), function(i)
    max(tabulate(match(Y[, i], grid_vals), nbins = C)), integer(1)))

  part_ids <- colnames(Y); if (is.null(part_ids)) part_ids <- paste0("P", seq_len(N))
  stmt_ids <- rownames(Y); if (is.null(stmt_ids)) stmt_ids <- paste0("S", seq_len(J))
  if (is.null(labels)) labels <- stmt_ids
  sel <- if (is.null(participants)) seq_len(N)
         else if (is.character(participants)) match(participants, part_ids)
         else as.integer(participants)
  if (anyNA(sel) || any(sel < 1 | sel > N))
    .bq_abort("unknown participant in `participants`.")

  fills <- .rank_ramp(C)
  txt <- .tile_text_col(fills)
  if (is.null(cex)) cex <- if (max_h <= 5) 0.9 else if (max_h <= 8) 0.7 else 0.55

  op <- par(no.readonly = TRUE)
  on.exit(par(op), add = TRUE)
  pages <- split(sel, ceiling(seq_along(sel) / per_page))
  for (pg in pages) {
    n <- length(pg)
    nc <- ceiling(sqrt(n)); nr <- ceiling(n / nc)
    par(mfrow = c(nr, nc), mar = c(2.5, 0.5, 2, 0.5))
    for (i in pg) {
      plot(NULL, xlim = c(0.5, C + 0.5), ylim = c(0.35, max_h + 0.65),
           axes = FALSE, xlab = "", ylab = "", main = part_ids[i],
           cex.main = 1, asp = 1)
      axis(1, at = seq_len(C), labels = grid_vals, cex.axis = 0.8,
           lwd = 0, lwd.ticks = 0, line = -1)
      for (ci in seq_len(C)) {
        js <- which(Y[, i] == grid_vals[ci])
        for (h in seq_along(js)) {
          rect(ci - 0.47, h - 0.47, ci + 0.47, h + 0.47,
               col = fills[ci], border = "white", lwd = 1.2)
          text(ci, h, labels[js[h]], col = txt[ci], cex = cex, font = 2)
        }
      }
    }
  }
  invisible(x)
}


#' @export
plot.qsort_data <- function(x, ...) plot_sorts(x, ...)


# ggplot2 version, faceted small multiples; registered on autoplot
#' @keywords internal
#' @noRd
autoplot.qsort_data <- function(object, participants = NULL, labels = NULL,
                                ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    .bq_abort("autoplot needs ggplot2; plot_sorts() does not.")
  Y <- object$Y
  J <- nrow(Y); N <- ncol(Y)
  grid_vals <- sort(unique(as.vector(Y[is.finite(Y)])))
  C <- length(grid_vals)
  part_ids <- colnames(Y); if (is.null(part_ids)) part_ids <- paste0("P", seq_len(N))
  stmt_ids <- rownames(Y); if (is.null(stmt_ids)) stmt_ids <- paste0("S", seq_len(J))
  if (is.null(labels)) labels <- stmt_ids
  sel <- if (is.null(participants)) seq_len(N)
         else if (is.character(participants)) match(participants, part_ids)
         else as.integer(participants)

  rows <- list()
  for (i in sel) {
    for (ci in seq_len(C)) {
      js <- which(Y[, i] == grid_vals[ci])
      if (length(js))
        rows[[length(rows) + 1]] <- data.frame(
          participant = part_ids[i], column = ci,
          height = seq_along(js), rank = grid_vals[ci],
          label = labels[js], stringsAsFactors = FALSE)
    }
  }
  d <- do.call(rbind, rows)
  d$rank <- factor(d$rank, levels = grid_vals)
  fills <- stats::setNames(.rank_ramp(C), as.character(grid_vals))
  d$txt <- .tile_text_col(fills[as.character(d$rank)])
  d$participant <- factor(d$participant, levels = part_ids[sel])

  ggplot2::ggplot(d, ggplot2::aes(x = .data$column, y = .data$height,
                                  fill = .data$rank)) +
    ggplot2::geom_tile(colour = "white", linewidth = 0.4,
                       width = 0.95, height = 0.95) +
    ggplot2::geom_text(ggplot2::aes(label = .data$label,
                                    colour = .data$txt),
                       size = 2.6, fontface = "bold") +
    ggplot2::scale_fill_manual(values = fills, drop = FALSE) +
    ggplot2::scale_colour_identity() +
    ggplot2::scale_x_continuous(breaks = seq_len(C), labels = grid_vals) +
    ggplot2::facet_wrap(~participant) +
    ggplot2::labs(x = NULL, y = NULL, fill = "rank") +
    ggplot2::theme_minimal() +
    ggplot2::theme(axis.text.y = ggplot2::element_blank(),
                   panel.grid = ggplot2::element_blank(),
                   legend.position = "none")
}
