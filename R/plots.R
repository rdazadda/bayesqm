# plots.R
# Paper-quality base-R plots for bayesqm objects. Every function
# visualises a quantity already on the fit -- aligned posterior draws,
# PPC summaries, MatchAlign congruence, or the ELPD-over-K table. The
# family shares:
#   - a bayesplot-compatible "blue" palette (light -> mid -> dark plus
#     one muted-red accent), colourblind-safe and greyscale-legible;
#   - a single consistent idiom: nested 50 / 95 percent intervals, open
#     points, sort-once-apply-everywhere for multi-panel comparability;
#   - par() fully restored on exit; user-set par("mfrow") respected;
#   - user ... filtered against hardcoded args to avoid "formal argument
#     matched by multiple actual arguments" collisions.


# ---- internal helpers ----
# (.bq_col() lives in colors.R and reads from the active scheme)


.bq_dots <- function(dots, exclude) {
  dots[!(names(dots) %in% exclude)]
}


.bq_mfrow <- function(K) {
  cur <- graphics::par("mfrow")
  if (identical(as.integer(cur), c(1L, 1L))) {
    cols <- if (K <= 3L) K else 3L
    rows <- as.integer(ceiling(K / cols))
    list(override = TRUE, mfrow = c(rows, cols))
  } else {
    list(override = FALSE, mfrow = cur)
  }
}


# ---- plot.bayesqm_fit ----


#' Factor-score dotchart for a bayesqm_fit
#'
#' @description
#' One panel per factor: horizontal dotchart of every statement's
#' posterior median z-score with nested 50 percent (thick) and
#' `prob`-coverage (thin) credible-interval whiskers. Statements are
#' sorted once -- by default, by the first factor's posterior mean --
#' and that ordering is reused across panels so the reader can scan
#' horizontally to compare factors. For a loadings-only view, see
#' [plot_loading_posterior()]; for a single statement across factors,
#' see [plot_zscore_posterior()].
#'
#' @param x A `bayesqm_fit`.
#' @param sort_by Integer factor index whose posterior mean is used to
#'   sort rows (default 1).
#' @param prob Outer-interval coverage probability; defaults to
#'   `fit$brief$prob`.
#' @param cex.lab Axis-label text size.
#' @param ... Additional arguments forwarded to `plot()`.
#'
#' @return The input, invisibly.
#' @export
plot.bayesqm_fit <- function(x, sort_by = 1L, prob = NULL,
                             cex.lab = 0.7, ...) {
  cols <- .bq_col()
  K    <- x$brief$K
  if (is.null(prob)) prob <- x$brief$prob
  alpha <- 1 - prob

  fac_names <- colnames(x$loa)
  if (is.null(fac_names)) fac_names <- paste0("f", seq_len(K))
  sort_by <- as.integer(sort_by)
  if (sort_by < 1L || sort_by > K)
    stop("sort_by must be an integer in 1:K.")

  dm    <- dim(x$F_draws)[2:3]
  med   <- apply(x$F_draws, c(2, 3), median);                   dim(med)  <- dm
  o_lo  <- apply(x$F_draws, c(2, 3), quantile,
                 probs = alpha / 2,     names = FALSE);         dim(o_lo) <- dm
  o_hi  <- apply(x$F_draws, c(2, 3), quantile,
                 probs = 1 - alpha / 2, names = FALSE);         dim(o_hi) <- dm
  i_lo  <- apply(x$F_draws, c(2, 3), quantile,
                 probs = 0.25, names = FALSE);                  dim(i_lo) <- dm
  i_hi  <- apply(x$F_draws, c(2, 3), quantile,
                 probs = 0.75, names = FALSE);                  dim(i_hi) <- dm

  labels <- dimnames(x$F_draws)[[2]]
  if (is.null(labels)) labels <- paste0("S", seq_len(nrow(med)))

  ord <- order(med[, sort_by])
  med <- med[ord, , drop = FALSE]
  o_lo <- o_lo[ord, , drop = FALSE]; o_hi <- o_hi[ord, , drop = FALSE]
  i_lo <- i_lo[ord, , drop = FALSE]; i_hi <- i_hi[ord, , drop = FALSE]
  labels <- labels[ord]

  lay <- .bq_mfrow(K)
  old_par <- if (lay$override)
    graphics::par(mfrow = lay$mfrow, mar = c(4, 8, 3, 1))
  else
    graphics::par(mar = c(4, 8, 3, 1))
  on.exit(graphics::par(old_par), add = TRUE)

  xlim <- range(c(o_lo, o_hi), na.rm = TRUE)
  dots <- .bq_dots(list(...),
                   c("xlim", "yaxt", "xlab", "ylab", "main",
                     "pch", "bg", "col", "type"))
  y <- seq_len(nrow(med))

  for (k in seq_len(K)) {
    do.call(plot, c(
      list(x = med[, k], y = y, xlim = xlim, yaxt = "n",
           xlab = "z-score", ylab = "", main = fac_names[k],
           type = "n"),
      dots))
    graphics::abline(v = 0, lty = 3, col = cols$grey)
    graphics::segments(o_lo[, k], y, o_hi[, k], y, lwd = 0.9)
    graphics::segments(i_lo[, k], y, i_hi[, k], y, lwd = 2.5)
    graphics::points(med[, k], y, pch = 21, bg = "white",
                     col = cols$dark, cex = 1.1, lwd = 1.1)
    graphics::axis(2, at = y, labels = labels,
                   las = 1, tick = FALSE, cex.axis = cex.lab)
  }

  invisible(x)
}


# ---- plot_elpd ----


#' ELPD across K with peak and Sivula annotations
#'
#' @description
#' ELPD against K with +/- 1.96 SE whiskers, a solid vertical rule at
#' the ELPD peak, and a dashed rule at the Sivula (parsimony) K. Both
#' rules are drawn in the primary blue, distinguished by line type and
#' by text annotations at the top of the axis. The title reports the
#' peak-plus-Sivula case (`agree`, `gap`, `reversed`).
#'
#' @param run A `bayesqm_run`.
#' @param ... Additional arguments forwarded to `plot()`.
#'
#' @return The input, invisibly.
#' @export
plot_elpd <- function(run, ...) {
  stopifnot(inherits(run, "bayesqm_run"))
  cols <- .bq_col()

  tab <- run$tab
  K   <- tab$K
  y   <- tab$elpd
  se  <- tab$se
  lo  <- y - 1.96 * se
  hi  <- y + 1.96 * se
  if (!any(is.finite(y))) stop("No finite ELPD values on this run.")

  old_par <- graphics::par(mar = c(5, 5, 4, 2))
  on.exit(graphics::par(old_par), add = TRUE)

  dots <- .bq_dots(list(...),
                   c("xlim", "ylim", "xlab", "ylab",
                     "xaxt", "type", "main"))
  do.call(plot, c(
    list(x = K, y = y, type = "n", xaxt = "n",
         xlim = range(K),
         ylim = range(c(lo, hi), na.rm = TRUE),
         xlab = "Number of factors (K)",
         ylab = "ELPD (leave-one-out)"),
    dots))
  graphics::axis(1, at = K)

  if (!is.na(run$k_peak))
    graphics::abline(v = run$k_peak, lwd = 1.6, col = cols$dark)
  if (!is.na(run$k_sivula))
    graphics::abline(v = run$k_sivula, lwd = 1.6, lty = 2, col = cols$dark)

  usr <- graphics::par("usr")
  y_top <- usr[4] - 0.03 * (usr[4] - usr[3])
  if (!is.na(run$k_peak))
    graphics::text(run$k_peak, y_top, " Peak", pos = 4,
                   cex = 0.8, col = cols$dark)
  if (!is.na(run$k_sivula) && run$k_sivula != run$k_peak)
    graphics::text(run$k_sivula, y_top, " Sivula", pos = 4,
                   cex = 0.8, col = cols$dark)

  valid <- is.finite(y)
  graphics::segments(K[valid], lo[valid], K[valid], hi[valid], lwd = 1.1)
  graphics::points(K[valid], y[valid], pch = 21, bg = "white",
                   col = cols$dark, cex = 1.3, lwd = 1.2)

  case_str <- if (is.na(run$case)) "NA" else run$case
  graphics::title(main = sprintf("ELPD across K (case: %s)", case_str))

  invisible(run)
}


# ---- plot_membership ----


#' Dominant-factor posterior-probability heatmap
#'
#' @description
#' Tiled heatmap of `P(argmax_k |Lambda[i, k]| = k)` with one row per
#' participant, one column per factor, rendered on a sequential blue
#' ramp. A right-side tier strip encodes Strong / Moderate / Weak
#' membership (per [classify_membership()]). A horizontal colourbar
#' under the plot gives the probability scale. Rows are sorted by
#' dominant factor first, then tier, then probability -- so the block
#' structure a reader wants to see is preserved.
#'
#' @param fit A `bayesqm_fit`.
#' @param sort Logical; apply the default ordering.
#' @param ... Additional arguments forwarded to `image()`.
#'
#' @return The input, invisibly.
#' @export
plot_membership <- function(fit, sort = TRUE, ...) {
  stopifnot(inherits(fit, "bayesqm_fit"))
  cols <- .bq_col()

  prob <- compute_dominant_prob(fit$Lambda_draws)
  tier <- classify_membership(fit$Lambda_draws)

  if (sort) {
    ord <- order(tier$dominant_factor,
                 as.integer(tier$tier),
                 -tier$max_prob)
    prob <- prob[ord, , drop = FALSE]
    tier <- tier[ord, , drop = FALSE]
  }

  N <- nrow(prob); K <- ncol(prob)
  pal <- grDevices::colorRampPalette(
    c(cols$light, cols$mid, cols$dark))(100)

  old_par <- graphics::par(mar = c(6.5, 8, 4, 7))
  on.exit(graphics::par(old_par), add = TRUE)

  dots <- .bq_dots(list(...),
                   c("col", "zlim", "axes", "xlab", "ylab", "main", "x", "y", "z"))
  do.call(graphics::image, c(
    list(x = seq_len(K), y = seq_len(N),
         z = t(prob[N:1, , drop = FALSE]),
         axes = FALSE, xlab = "", ylab = "",
         col = pal, zlim = c(0, 1)),
    dots))
  graphics::axis(1, at = seq_len(K), labels = colnames(prob),
                 tick = FALSE, line = -0.5)
  graphics::axis(2, at = N:1, labels = rownames(prob),
                 las = 1, tick = FALSE, cex.axis = 0.75)
  graphics::box()

  tier_cols <- c(Strong = cols$dark, Moderate = cols$mid, Weak = cols$light)
  x_strip <- K + 0.6
  graphics::rect(x_strip, seq_len(N) - 0.5,
                 x_strip + 0.4, seq_len(N) + 0.5,
                 col = tier_cols[as.character(tier$tier[N:1])],
                 border = NA, xpd = TRUE)
  graphics::mtext("tier", side = 3, at = x_strip + 0.2, line = 0.1,
                  cex = 0.8)
  graphics::legend("topright", inset = c(-0.10, -0.15), xpd = TRUE,
                   legend = names(tier_cols), fill = tier_cols,
                   bty = "n", cex = 0.75, border = NA)

  # Horizontal colour bar below the plot.
  usr <- graphics::par("usr")
  bar_y1 <- usr[3] - 0.08 * (usr[4] - usr[3])
  bar_y2 <- usr[3] - 0.03 * (usr[4] - usr[3])
  bx <- seq(usr[1], usr[2], length.out = length(pal) + 1)
  graphics::rect(bx[-length(bx)], bar_y1, bx[-1], bar_y2,
                 col = pal, border = NA, xpd = NA)
  lab_y <- usr[3] - 0.14 * (usr[4] - usr[3])
  graphics::text(c(usr[1], mean(usr[1:2]), usr[2]), lab_y,
                 labels = c("0", "P(dominant)", "1"),
                 cex = 0.75, xpd = NA)

  graphics::title(main = "Dominant-factor posterior probability")

  invisible(fit)
}


# ---- plot_ppc ----


#' Posterior predictive check on the correlation-matrix RMSE
#'
#' @description
#' Histogram of the replicated correlation-matrix RMSE stored on
#' `fit$ppc$rmse.r`: per draw, the RMSE between `cor(Y_rep)` and
#' `cor(Y_obs)`. Rendered in the bayesplot-idiom (filled bars, no
#' border, suppressed y-axis) with the median and central credible
#' interval marked.
#'
#' @param fit A `bayesqm_fit`.
#' @param breaks Passed to `hist()`.
#' @param ... Additional arguments forwarded to `hist()`.
#'
#' @return The input, invisibly.
#' @export
plot_ppc <- function(fit, breaks = 30, ...) {
  stopifnot(inherits(fit, "bayesqm_fit"))
  cols <- .bq_col()

  rmse <- fit$ppc$rmse.r
  if (is.null(rmse)) stop("No posterior predictive RMSE stored on this fit.")
  rmse <- rmse[is.finite(rmse)]
  if (length(rmse) < 2)
    stop("Not enough finite PPC draws to plot (need >= 2).")

  prob  <- fit$brief$prob
  alpha <- 1 - prob
  med <- median(rmse)
  q   <- quantile(rmse, probs = c(alpha / 2, 1 - alpha / 2), names = FALSE)

  old_par <- graphics::par(mar = c(5, 4, 4, 2))
  on.exit(graphics::par(old_par), add = TRUE)

  dots <- .bq_dots(list(...),
                   c("col", "border", "main", "xlab", "ylab", "yaxt",
                     "breaks", "x"))
  do.call(graphics::hist, c(
    list(x = rmse, breaks = breaks,
         col = cols$fill, border = NA, yaxt = "n",
         main = "Posterior predictive: correlation-matrix RMSE",
         xlab = "RMSE( cor(Y_rep), cor(Y_obs) )",
         ylab = ""),
    dots))

  graphics::abline(v = q,   lwd = 1,   col = cols$dark, lty = 2)
  graphics::abline(v = med, lwd = 2.3, col = cols$dark)
  graphics::mtext(sprintf("median %.3f   (%d%% CrI: %.3f, %.3f)",
                          med, round(100 * prob), q[1], q[2]),
                  side = 3, line = 0.25, cex = 0.85)

  invisible(fit)
}


# ---- plot_loading_posterior ----


#' Loading forest with 50 and 95 percent credible intervals
#'
#' @description
#' Horizontal dotchart of every participant's loading, one panel per
#' factor, ranked by posterior mean. Each loading is drawn as a
#' median point with nested 50 percent (thick) and 95 percent (thin)
#' credible-interval whiskers. A faint grey vertical rule marks
#' Brown's descriptive cut-off `+/- 1.96 / sqrt(J)`. When
#' `highlight_flagged = TRUE`, participants in `fit$flagged[, k]` are
#' drawn as filled points in the accent colour.
#'
#' @param fit A `bayesqm_fit`.
#' @param factors Optional subset of factors to show (integer or name).
#' @param highlight_flagged Logical; fill flagged participants.
#' @param ... Additional arguments forwarded to `plot()`.
#'
#' @return The input, invisibly.
#' @export
plot_loading_posterior <- function(fit, factors = NULL,
                                   highlight_flagged = TRUE, ...) {
  stopifnot(inherits(fit, "bayesqm_fit"))
  cols <- .bq_col()

  L <- fit$Lambda_draws
  N <- dim(L)[2]; K <- dim(L)[3]
  fac_names  <- colnames(fit$loa)
  part_names <- rownames(fit$loa)

  if (is.null(factors)) {
    fac_ix <- seq_len(K)
  } else if (is.character(factors)) {
    fac_ix <- match(factors, fac_names)
    if (anyNA(fac_ix))
      stop("Unknown factor(s): ",
           paste(factors[is.na(fac_ix)], collapse = ", "))
  } else {
    fac_ix <- as.integer(factors)
  }
  if (length(fac_ix) == 0L) stop("No factors selected.")

  prob    <- fit$brief$prob
  alpha_o <- 1 - prob

  dm   <- c(N, K)
  med  <- apply(L, c(2, 3), median);                            dim(med)  <- dm
  o_lo <- apply(L, c(2, 3), quantile, probs = alpha_o / 2,
                names = FALSE);                                 dim(o_lo) <- dm
  o_hi <- apply(L, c(2, 3), quantile, probs = 1 - alpha_o / 2,
                names = FALSE);                                 dim(o_hi) <- dm
  i_lo <- apply(L, c(2, 3), quantile, probs = 0.25,
                names = FALSE);                                 dim(i_lo) <- dm
  i_hi <- apply(L, c(2, 3), quantile, probs = 0.75,
                names = FALSE);                                 dim(i_hi) <- dm

  brown <- 1.96 / sqrt(fit$brief$J)
  xlim  <- range(c(o_lo, o_hi, -brown, brown), na.rm = TRUE)

  lay <- .bq_mfrow(length(fac_ix))
  old_par <- if (lay$override)
    graphics::par(mfrow = lay$mfrow, mar = c(5, 7, 3, 1))
  else
    graphics::par(mar = c(5, 7, 3, 1))
  on.exit(graphics::par(old_par), add = TRUE)

  dots <- .bq_dots(list(...),
                   c("xlim", "yaxt", "xlab", "ylab", "main", "type",
                     "pch", "bg", "col", "x", "y"))

  for (k in fac_ix) {
    ord <- order(med[, k])
    y   <- seq_len(N)

    do.call(plot, c(
      list(x = med[ord, k], y = y, xlim = xlim, type = "n",
           yaxt = "n", xlab = "Loading", ylab = "",
           main = fac_names[k]),
      dots))

    graphics::abline(v = 0, lty = 3, col = cols$grey)
    graphics::abline(v = c(-brown, brown), lty = 2,
                     col = cols$gridgrey, lwd = 1)

    graphics::segments(o_lo[ord, k], y, o_hi[ord, k], y, lwd = 0.9)
    graphics::segments(i_lo[ord, k], y, i_hi[ord, k], y, lwd = 2.5)

    flagged <- if (isTRUE(highlight_flagged) && !is.null(fit$flagged) &&
                   identical(dim(fit$flagged), c(N, K)))
      fit$flagged[ord, k]
    else
      rep(FALSE, N)

    graphics::points(med[ord, k], y, pch = 21,
                     bg = ifelse(flagged, cols$accent, "white"),
                     col = cols$dark, cex = 1.1, lwd = 1)

    graphics::axis(2, at = y, labels = part_names[ord],
                   las = 1, tick = FALSE, cex.axis = 0.7)
  }

  invisible(fit)
}


# ---- plot_zscore_posterior ----


#' Per-statement factor-score posterior across factors
#'
#' @description
#' For a single statement, draws the posterior median z-score per
#' factor with nested 50 percent (thick) and 95 percent (thin)
#' credible-interval whiskers, stacked vertically. The x-axis is
#' symmetric around zero so the zero reference is centred.
#'
#' @param fit A `bayesqm_fit`.
#' @param statement Integer index or statement name.
#' @param ... Additional arguments forwarded to `plot()`.
#'
#' @return The input, invisibly.
#' @export
plot_zscore_posterior <- function(fit, statement, ...) {
  stopifnot(inherits(fit, "bayesqm_fit"))
  cols <- .bq_col()

  F <- fit$F_draws
  J <- dim(F)[2]; K <- dim(F)[3]
  stmt_names <- dimnames(F)[[2]]
  fac_names  <- dimnames(F)[[3]]
  if (is.null(stmt_names)) stmt_names <- paste0("S", seq_len(J))
  if (is.null(fac_names))  fac_names  <- paste0("f", seq_len(K))

  if (is.character(statement)) {
    j <- match(statement, stmt_names)
    if (is.na(j)) stop("Statement '", statement, "' not found.")
  } else {
    j <- as.integer(statement)
    if (j < 1L || j > J) stop("statement index out of range.")
  }

  prob    <- fit$brief$prob
  alpha_o <- 1 - prob

  med  <- vapply(seq_len(K),
                 function(k) median(F[, j, k], na.rm = TRUE), numeric(1))
  i_lo <- vapply(seq_len(K),
                 function(k) quantile(F[, j, k], 0.25,
                                      names = FALSE, na.rm = TRUE), numeric(1))
  i_hi <- vapply(seq_len(K),
                 function(k) quantile(F[, j, k], 0.75,
                                      names = FALSE, na.rm = TRUE), numeric(1))
  o_lo <- vapply(seq_len(K),
                 function(k) quantile(F[, j, k], alpha_o / 2,
                                      names = FALSE, na.rm = TRUE), numeric(1))
  o_hi <- vapply(seq_len(K),
                 function(k) quantile(F[, j, k], 1 - alpha_o / 2,
                                      names = FALSE, na.rm = TRUE), numeric(1))

  span <- max(abs(c(o_lo, o_hi)), na.rm = TRUE)
  xlim <- c(-span, span) * 1.05

  old_par <- graphics::par(mar = c(5, 7, 4, 2))
  on.exit(graphics::par(old_par), add = TRUE)

  dots <- .bq_dots(list(...),
                   c("xlim", "ylim", "type", "yaxt",
                     "xlab", "ylab", "main", "x", "y"))
  do.call(plot, c(
    list(x = med, y = seq_len(K), xlim = xlim,
         ylim = c(0.5, K + 0.5), type = "n", yaxt = "n",
         xlab = "z-score", ylab = "",
         main = sprintf("Posterior z-score: %s", stmt_names[j])),
    dots))

  graphics::abline(v = 0, lty = 3, col = cols$grey)
  graphics::segments(o_lo, seq_len(K), o_hi, seq_len(K), lwd = 0.9)
  graphics::segments(i_lo, seq_len(K), i_hi, seq_len(K), lwd = 2.6)
  graphics::points(med, seq_len(K), pch = 21, bg = "white",
                   col = cols$dark, cex = 1.3, lwd = 1.2)
  graphics::axis(2, at = seq_len(K), labels = fac_names,
                 las = 1, tick = FALSE)

  invisible(fit)
}


# ---- plot_tucker ----


#' MatchAlign Tucker's phi distribution by factor
#'
#' @description
#' Boxplot of the per-draw Tucker's phi between each aligned loading
#' column and the MatchAlign pivot, stored on
#' `fit$align_info$congruence`. A semi-transparent strip of the
#' individual draws is overlaid so bimodality -- the visible signature
#' of residual label-switching -- is not hidden by the box. A dashed
#' rule at 0.95 marks the conventional near-identity threshold.
#'
#' @param fit A `bayesqm_fit`.
#' @param ... Additional arguments forwarded to `boxplot()`.
#'
#' @return The input, invisibly.
#' @export
plot_tucker <- function(fit, ...) {
  stopifnot(inherits(fit, "bayesqm_fit"))
  cols <- .bq_col()

  cng <- fit$align_info$congruence
  if (is.null(cng)) stop("No MatchAlign congruence on this fit.")
  if (!is.matrix(cng))
    stop("align_info$congruence must be a matrix (draws x factor).")

  fac_names <- colnames(cng)
  if (is.null(fac_names)) fac_names <- colnames(fit$loa)
  K <- ncol(cng)

  old_par <- graphics::par(mar = c(5, 5, 4, 2))
  on.exit(graphics::par(old_par), add = TRUE)

  y_lo <- min(c(cng, 0.5), na.rm = TRUE)

  dots <- .bq_dots(list(...),
                   c("names", "outline", "boxwex", "col", "border",
                     "ylim", "xlab", "ylab", "main", "x"))
  do.call(graphics::boxplot, c(
    list(x = as.data.frame(cng),
         names   = fac_names,
         outline = FALSE,
         boxwex  = 0.45,
         col     = cols$light,
         border  = cols$dark,
         ylim    = c(y_lo, 1),
         xlab    = "Factor",
         ylab    = "Tucker's phi (aligned vs pivot)",
         main    = "MatchAlign alignment quality"),
    dots))

  # Strip of per-draw points to reveal multimodality.
  jit_col <- grDevices::adjustcolor(cols$mid, alpha.f = 0.18)
  for (k in seq_len(K)) {
    xp <- k + stats::runif(nrow(cng), -0.12, 0.12)
    graphics::points(xp, cng[, k], pch = 16, cex = 0.35, col = jit_col)
  }

  graphics::abline(h = 0.95, lty = 2, col = cols$accent, lwd = 1.1)
  graphics::abline(h = 1,    lty = 3, col = cols$grey)
  graphics::mtext("0.95 near-identity", side = 4, at = 0.95,
                  line = 0.4, las = 1, cex = 0.7, col = cols$accent)

  invisible(fit)
}


# ---- plot_dist_cons ----


#' Distinguishing-statement posterior-probability heatmap
#'
#' @description
#' Heatmap of `P(|F[j, k] - F[j, l]| > delta)` for every statement and
#' every factor pair, rendered on a sequential blue ramp. Rows are
#' ordered so the most discriminating statements are at the top. A
#' vertical colour bar in the right margin gives the probability scale.
#'
#' @param fit A `bayesqm_fit`.
#' @param delta Minimum z-score separation (default 1.0).
#' @param ... Additional arguments forwarded to `image()`.
#'
#' @return The input, invisibly.
#' @export
plot_dist_cons <- function(fit, delta = 1.0, ...) {
  stopifnot(inherits(fit, "bayesqm_fit"))
  if (fit$brief$K < 2) stop("plot_dist_cons requires K >= 2.")
  cols <- .bq_col()

  mat <- compute_distinguishing_prob(fit$F_draws, delta = delta)
  ord <- order(apply(mat, 1, max))
  mat <- mat[ord, , drop = FALSE]
  J <- nrow(mat); P <- ncol(mat)

  pal <- grDevices::colorRampPalette(
    c(cols$light, cols$mid, cols$dark))(100)

  old_par <- graphics::par(no.readonly = TRUE)
  on.exit({ graphics::par(old_par); graphics::layout(1) }, add = TRUE)

  graphics::layout(matrix(c(1, 2), nrow = 1), widths = c(6, 1))

  graphics::par(mar = c(5, 8, 4, 1))
  dots <- .bq_dots(list(...),
                   c("col", "zlim", "axes", "xlab", "ylab", "main", "x", "y", "z"))
  do.call(graphics::image, c(
    list(x = seq_len(P), y = seq_len(J), z = t(mat),
         axes = FALSE, xlab = "Factor pair", ylab = "",
         col = pal, zlim = c(0, 1),
         main = sprintf("P(|F[j,k] - F[j,l]| > %.2g)", delta)),
    dots))
  graphics::axis(1, at = seq_len(P), labels = colnames(mat),
                 tick = FALSE, cex.axis = 0.85)
  graphics::axis(2, at = seq_len(J), labels = rownames(mat),
                 las = 1, tick = FALSE, cex.axis = 0.7)
  graphics::box()

  # Colour bar in second layout cell.
  graphics::par(mar = c(5, 1, 4, 4))
  bar_y <- seq(0, 1, length.out = length(pal) + 1)
  graphics::image(1, (bar_y[-length(bar_y)] + bar_y[-1]) / 2,
                  matrix(seq_along(pal), nrow = 1),
                  col = pal, axes = FALSE, xlab = "", ylab = "")
  graphics::axis(4, at = c(0, 0.5, 1), las = 1, cex.axis = 0.8)
  graphics::mtext("probability", side = 4, line = 2.2, cex = 0.8)

  invisible(fit)
}


# ---- plot_hyper ----


#' Hyperparameter posterior densities
#'
#' @description
#' One panel per scalar hyperparameter (default `nu`, `sigma`, `tau`)
#' showing a two-tone kernel density: the full posterior in the light
#' shade, the central credible interval re-shaded in the mid shade,
#' and the posterior median marked by a short tick at the baseline.
#' Coverage defaults to `fit$brief$prob`. When a parameter's support
#' spans more than one order of magnitude (`max / min > 20`, all
#' positive), the x-axis is automatically rendered on a log scale so
#' the density shape is not crushed against the lower bound.
#'
#' @param fit A `bayesqm_fit`.
#' @param pars Character vector of hyperparameter names to show.
#' @param log `NULL` (default) auto-detects per parameter; set to
#'   `"x"` to force log, or `""` to force linear.
#' @param ... Additional arguments forwarded to `plot()`.
#'
#' @return The input, invisibly.
#' @export
plot_hyper <- function(fit, pars = c("nu", "sigma", "tau"),
                       log = NULL, ...) {
  stopifnot(inherits(fit, "bayesqm_fit"))
  cols <- .bq_col()

  hp    <- fit$hyperparams
  prob  <- fit$brief$prob
  alpha <- 1 - prob

  avail <- pars[vapply(pars, function(p) {
    v <- hp[[p]]
    !is.null(v) && sum(is.finite(v)) >= 2L
  }, logical(1))]
  if (length(avail) == 0L)
    stop("No non-empty hyperparameter draws to plot.")

  old_par <- graphics::par(mfrow = c(1, length(avail)),
                           mar = c(5, 4, 3, 1))
  on.exit(graphics::par(old_par), add = TRUE)

  dots <- .bq_dots(list(...),
                   c("main", "xlab", "ylab", "lwd", "col", "type",
                     "xlim", "ylim", "log", "x", "y"))

  for (p in avail) {
    v <- hp[[p]]
    v <- v[is.finite(v)]

    use_log <- if (is.null(log))
      all(v > 0) && (max(v) / min(v[v > 0]) > 20)
    else
      identical(log, "x")

    # Compute density in the right space. On log-x, we estimate density
    # on log(v); the x positions are then exp(d$x), so polygon / line
    # points sit correctly on the log-scaled axis.
    bw <- if (use_log) "SJ" else "nrd0"
    d_raw <- stats::density(if (use_log) log(v) else v, bw = bw)
    d_x <- if (use_log) exp(d_raw$x) else d_raw$x
    d_y <- d_raw$y

    lo  <- quantile(v, alpha / 2,     names = FALSE)
    hi  <- quantile(v, 1 - alpha / 2, names = FALSE)
    med <- median(v)

    do.call(plot, c(
      list(x = d_x, y = d_y, type = "n",
           log = if (use_log) "x" else "",
           main = p, xlab = p, ylab = "Posterior density"),
      dots))

    # Full density (light shade).
    graphics::polygon(c(d_x[1], d_x, d_x[length(d_x)]),
                      c(0,      d_y, 0),
                      col = cols$light, border = NA)
    # CrI band (mid shade).
    in_band <- d_x >= lo & d_x <= hi
    graphics::polygon(c(lo, d_x[in_band], hi),
                      c(0,  d_y[in_band], 0),
                      col = cols$fill, border = NA)
    graphics::lines(d_x, d_y, lwd = 1.4, col = cols$dark)
    # Median: short tick at the baseline.
    y_tick <- -0.02 * max(d_y)
    graphics::segments(med, 0, med, y_tick, lwd = 2, col = cols$dark)

    scale_note <- if (use_log) "  (log x)" else ""
    graphics::mtext(sprintf("median %.3g   (%d%% CrI %.3g, %.3g)%s",
                            med, round(100 * prob), lo, hi, scale_note),
                    side = 3, line = 0.2, cex = 0.78)
  }

  invisible(fit)
}
