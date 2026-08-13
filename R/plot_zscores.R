# plot_zscores.R
# The whole-panel statement view (the classic Q z-score chart, with the
# posterior behind it) and the single-statement drill-down.


#' Statement scores across factors, whole panel
#'
#' @description
#' Every statement's score under every factor, with nested 50% and 95%
#' credible intervals — the classic Q z-score chart carrying its
#' uncertainty. Statements are ordered by how strongly the factors
#' diverge on them, so the top of the chart is where the viewpoints
#' disagree and the bottom is where they concur; the left margin marks
#' each statement's verdict.
#'
#' @param fit A `bayesqm_fit`.
#' @param order_by `"divergence"` (default; by the largest median pairwise
#'   contrast) or `"score"` (by the first factor's median score).
#' @param q,cons_floor As in [compute_qdc()] (used for the verdict marks
#'   when `K >= 2`).
#'
#' @return `fit`, invisibly.
#'
#' @export
plot_zscores <- function(fit, order_by = c("divergence", "score"),
                         q = 0.05, cons_floor = 0.95) {
  assert_bayesqm_fit(fit)
  order_by <- match.arg(order_by)
  cols <- bayesqm_colors()
  K <- fit$brief$K; J <- fit$brief$J
  fac_ids <- dimnames(fit$draws$sigma)[[2]]
  kq <- cols$qual[(seq_len(K) - 1) %% length(cols$qual) + 1]

  zs <- compute_zscores(fit)
  zs50 <- compute_zscores(fit, prob = 0.5)

  verdict <- rep("", J)
  if (K >= 2) {
    qdc <- compute_qdc(fit, q = q, cons_floor = cons_floor)
    verdict <- qdc$verdict
    ct <- attr(qdc, "contrasts")
    div <- vapply(zs$statement, function(s)
      max(abs(ct$median[ct$statement == s])), numeric(1))
  } else {
    div <- abs(zs[[paste0(fac_ids[1], "_zsc")]])
  }
  o <- if (order_by == "divergence") order(div)
       else order(zs[[paste0(fac_ids[1], "_zsc")]])
  zs <- zs[o, ]; zs50 <- zs50[o, ]; verdict <- verdict[o]

  vcol <- ifelse(grepl("^distinguishing", verdict),
                 .bq_verdict[["distinguishing"]],
                 ifelse(verdict == "consensus", .bq_verdict[["consensus"]],
                        NA))

  op <- .bq_par(mar = c(4, 6, 3, 1))
  on.exit(par(op), add = TRUE)
  xr <- range(unlist(zs[, grep("_lower|_upper", names(zs))]))
  plot(NULL, xlim = xr, ylim = c(0.5, J + 0.5), yaxt = "n",
       xlab = "statement score (z units)", ylab = "",
       main = "Statement scores by factor, 50% and 95% intervals")
  abline(v = 0, col = cols$grey)
  axis(2, at = seq_len(J), labels = zs$statement, las = 1, cex.axis = 0.7)
  off <- seq(-0.25, 0.25, length.out = K)
  for (k in seq_len(K)) {
    fk <- fac_ids[k]
    y <- seq_len(J) + off[k]
    segments(zs[[paste0(fk, "_lower")]], y, zs[[paste0(fk, "_upper")]], y,
             col = kq[k], lwd = 1.2)
    segments(zs50[[paste0(fk, "_lower")]], y, zs50[[paste0(fk, "_upper")]], y,
             col = kq[k], lwd = 3)
    points(zs[[paste0(fk, "_zsc")]], y, pch = 19, col = kq[k], cex = 0.7)
  }
  mark <- which(!is.na(vcol))
  if (length(mark))
    points(rep(xr[1], length(mark)), mark, pch = 15, col = vcol[mark],
           cex = 0.8, xpd = TRUE)
  .bq_legend("bottomright",
             legend = c(fac_ids, "distinguishing", "consensus"),
             col = c(kq, .bq_verdict[["distinguishing"]],
                     .bq_verdict[["consensus"]]),
             pch = c(rep(19, K), 15, 15), cex = 0.75)
  invisible(fit)
}


#' One statement, in depth
#'
#' @description
#' The posterior of a single statement's score under each factor, drawn
#' as full densities with the medians marked, plus the statement's
#' verdict and its pairwise contrasts in the margin text. The drill-down
#' for the statement a write-up centers on.
#'
#' @param fit A `bayesqm_fit`.
#' @param statement Statement id or index.
#' @param q,cons_floor As in [compute_qdc()].
#'
#' @return `fit`, invisibly.
#'
#' @export
plot_statement <- function(fit, statement, q = 0.05, cons_floor = 0.95) {
  assert_bayesqm_fit(fit)
  cols <- bayesqm_colors()
  K <- fit$brief$K
  stmt_ids <- dimnames(fit$draws$F)[[2]]
  j <- if (is.character(statement)) match(statement, stmt_ids)
       else as.integer(statement)
  if (is.na(j) || j < 1 || j > fit$brief$J) .bq_abort("no such statement.")
  fac_ids <- dimnames(fit$draws$sigma)[[2]]
  kq <- cols$qual[(seq_len(K) - 1) %% length(cols$qual) + 1]

  dens <- lapply(seq_len(K), function(k) density(fit$draws$F[, j, k]))
  med <- vapply(seq_len(K), function(k) median(fit$draws$F[, j, k]), numeric(1))

  sub <- ""
  if (K >= 2) {
    qdc <- compute_qdc(fit, q = q, cons_floor = cons_floor)
    ct <- attr(qdc, "contrasts")
    ct <- ct[ct$statement == stmt_ids[j], ]
    dkl <- attr(qdc, "delta_kl")
    sub <- sprintf("verdict %s. contrasts %s, critical difference %s",
                   qdc$verdict[j],
                   paste(sprintf("%s %.2f", ct$pair, ct$median), collapse = ", "),
                   paste(sprintf("%.2f", dkl), collapse = " / "))
  }

  op <- .bq_par(mar = c(4, 4, 4, 1))
  on.exit(par(op), add = TRUE)
  plot(NULL, xlim = range(unlist(lapply(dens, `[[`, "x"))),
       ylim = c(0, 1.08 * max(unlist(lapply(dens, `[[`, "y")))),
       xlab = "statement score (z units)", ylab = "density",
       main = sprintf("Statement %s", stmt_ids[j]))
  mtext(sub, side = 3, line = 0.2, cex = 0.75, col = cols$grey)
  abline(v = 0, col = cols$grey)
  for (k in seq_len(K)) {
    polygon(dens[[k]], col = adjustcolor(kq[k], 0.25), border = kq[k],
            lwd = 1.5)
    segments(med[k], 0, med[k], max(dens[[k]]$y), col = kq[k], lwd = 2,
             lty = 2)
  }
  .bq_legend("topright", legend = fac_ids, fill = adjustcolor(kq, 0.4),
             border = kq, cex = 0.8)
  invisible(fit)
}


#' @rdname plot_statement
#' @param ... Passed on.
#' @export
plot_zscore_posterior <- function(...) {
  .Deprecated("plot_statement", package = "bayesqm")
  plot_statement(...)
}
