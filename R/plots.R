# plots.R
# Base-graphics views of the partition-model fit, one per user question.
# Every plot reads its palette through bayesqm_colors(), restores par()
# on exit, and returns its input invisibly. Factor identity always rides
# on the qualitative palette plus position or symbol, never colour alone.


#' @keywords internal
#' @noRd
.bq_par <- function(...) {
  op <- par(no.readonly = TRUE)
  par(font.axis = 2, font.lab = 2, font.main = 2, cex.main = 1.1)
  par(...)
  op
}


# every legend sits in a white box with a grey border
#' @keywords internal
#' @noRd
.bq_legend <- function(...)
  legend(..., bg = "white", box.col = "gray70", box.lwd = 0.8)


#' Bounded loadings with credible intervals
#'
#' @description
#' One row per participant, one interval per factor on the bounded
#' loading scale, with selected flags marked. The dotted rules sit at
#' the classical descriptive cut-off `1.96 / sqrt(J)` (reference).
#'
#' @param fit A `bayesqm_fit`.
#' @param q False-discovery level for the flag marks (default 0.05).
#'
#' @return `fit`, invisibly.
#'
#' @export
plot_loading_posterior <- function(fit, q = 0.05) {
  assert_bayesqm_fit(fit)
  cols <- bayesqm_colors()
  lo <- compute_loadings(fit)
  fl <- compute_flags(fit, q = q)
  K <- fit$brief$K; N <- fit$brief$N
  fac_ids <- dimnames(fit$draws$sigma)[[2]]
  thr <- 1.96 / sqrt(fit$brief$J)

  inner <- compute_loadings(fit, prob = 0.5)     # nested 50% interval

  op <- .bq_par(mar = c(4, 6, 3, 1))
  on.exit(par(op), add = TRUE)
  plot(NULL, xlim = c(-1, 1), ylim = c(0.5, N + 0.5), yaxt = "n",
       xlab = "bounded loading", ylab = "",
       main = "Participant loadings, 50% and 95% intervals")
  axis(2, at = seq_len(N), labels = lo$participant, las = 1, cex.axis = 0.8)
  abline(v = 0, col = cols$grey)
  abline(v = c(-thr, thr), col = cols$gridgrey, lty = 3)
  text(thr, N + 0.5, expression(bold(1.96 / sqrt(J))), pos = 4, cex = 0.7,
       col = cols$grey, xpd = TRUE)
  off <- seq(-0.22, 0.22, length.out = K)
  for (k in seq_len(K)) {
    ck <- cols$qual[(k - 1) %% length(cols$qual) + 1]
    y <- seq_len(N) + off[k]
    segments(lo[[paste0(fac_ids[k], "_lower")]], y,
             lo[[paste0(fac_ids[k], "_upper")]], y, col = ck, lwd = 1.2)
    segments(inner[[paste0(fac_ids[k], "_lower")]], y,
             inner[[paste0(fac_ids[k], "_upper")]], y, col = ck, lwd = 3.2)
    pub_k <- fl$selected & fl$factor == fac_ids[k]
    points(lo[[paste0(fac_ids[k], "_loading")]], y,
           pch = ifelse(pub_k, 19, 21), col = ck, bg = "white", cex = 0.9)
  }
  .bq_legend("topleft", legend = c(fac_ids, "selected flag"),
             col = c(cols$qual[seq_len(K)], cols$grey),
             pch = c(rep(15, K), 19), cex = 0.8)
  invisible(fit)
}


#' Flag probabilities with the unclassified state
#'
#' @description
#' One row per participant, one dot per factor at its posterior flag
#' probability (both poles combined; a minus sign marks a dominant
#' negative pole), and a grey square for the probability of remaining
#' unclassified. Filled dots are selected flags, and the dotted rule is
#' the 0.5 selection floor.
#'
#' @param fit A `bayesqm_fit`.
#' @param q False-discovery level for the selection marks (default 0.05).
#'
#' @return `fit`, invisibly.
#'
#' @export
plot_flags <- function(fit, q = 0.05) {
  assert_bayesqm_fit(fit)
  cols <- bayesqm_colors()
  fl <- compute_flags(fit, q = q)
  phi <- attr(fl, "phi")
  K <- fit$brief$K; N <- fit$brief$N
  fac_ids <- dimnames(fit$draws$sigma)[[2]]
  kq <- cols$qual[(seq_len(K) - 1) %% length(cols$qual) + 1]

  op <- .bq_par(mar = c(4, 6, 3, 1))
  on.exit(par(op), add = TRUE)
  plot(NULL, xlim = c(0, 1.05), ylim = c(0.5, N + 1.4), yaxt = "n",
       xlab = "posterior flag probability", ylab = "",
       main = "Flag probabilities")
  axis(2, at = seq_len(N), labels = rownames(phi), las = 1, cex.axis = 0.8)
  abline(v = 0.5, col = cols$grey, lty = 3)
  text(0.5, 0.56, "selection floor", pos = 4, cex = 0.7,
       col = cols$grey, font = 3)
  off <- seq(-0.26, 0.26, length.out = K + 1)
  for (k in seq_len(K)) {
    pk <- phi[, 2 * k - 1] + phi[, 2 * k]
    neg <- phi[, 2 * k] > phi[, 2 * k - 1]
    y <- seq_len(N) + off[k]
    sel <- fl$selected & fl$factor == fac_ids[k]
    points(pk, y, pch = ifelse(sel, 19, 21), col = kq[k], bg = "white",
           cex = 1.05, lwd = 1.4)
    show <- neg & pk > 0.02
    if (any(show))
      text(pk[show] + 0.02, y[show], "-", col = kq[k], font = 2)
  }
  points(phi[, 2 * K + 1], seq_len(N) + off[K + 1], pch = 22,
         col = cols$grey, bg = cols$gridgrey, cex = 1.0)
  .bq_legend("top", ncol = min(K + 2, 4),
             legend = c(fac_ids, "unclassified", "filled: selected"),
             col = c(kq, cols$grey, cols$grey),
             pt.bg = c(rep("white", K), cols$gridgrey, "white"),
             pch = c(rep(21, K), 22, 19), cex = 0.75)
  invisible(fit)
}


#' The factor array on its grid
#'
#' @description
#' The reported array for one factor drawn as the physical sorting grid:
#' columns are grid positions with their quota heights, each cell carries
#' its statement, and cell shading shows how certain the placement is
#' (the posterior probability of that statement landing in that column).
#'
#' @param fit A `bayesqm_fit`.
#' @param factor Which factor to draw (index or `"f2"`-style name;
#'   default 1).
#' @param labels Optional statement labels (defaults to the statement
#'   ids).
#'
#' @return `fit`, invisibly.
#'
#' @export
plot_factor_array <- function(fit, factor = 1, labels = NULL) {
  assert_bayesqm_fit(fit)
  cols <- bayesqm_colors()
  distr <- fit$distribution
  C <- length(distr)
  fac_ids <- dimnames(fit$draws$sigma)[[2]]
  k <- if (is.character(factor)) match(factor, fac_ids) else as.integer(factor)
  if (is.na(k) || k < 1 || k > fit$brief$K) .bq_abort("no such factor.")

  ar <- compute_factor_array(fit)
  slot <- ar[[paste0(fac_ids[k], "_grid")]]
  pcol <- attr(ar, "certainty")[, k]
  if (is.null(labels)) labels <- ar$statement

  op <- .bq_par(mar = c(4, 1, 3.5, 1))
  on.exit(par(op), add = TRUE)
  plot(NULL, xlim = c(0.5, C + 0.5), ylim = c(0, max(distr) + 0.5),
       axes = FALSE, xlab = "grid column", ylab = "",
       main = sprintf("Factor %s array", fac_ids[k]))
  mtext("darker tiles are more certain of their column", side = 3,
        line = 0.2, cex = 0.8, font = 3, col = cols$grey)
  col_labels <- if (C %% 2 == 0)
    c(seq(-C / 2, -1), seq(1, C / 2)) else seq_len(C) - (C + 1) / 2
  axis(1, at = seq_len(C), labels = col_labels)
  shade <- colorRampPalette(.bq_certainty)(101)
  for (cc in seq_len(C)) {
    js <- which(slot == cc)
    js <- js[order(-pcol[js])]
    for (h in seq_along(js)) {
      fill <- shade[round(100 * pcol[js[h]]) + 1]
      rect(cc - 0.45, h - 1 + 0.05, cc + 0.45, h - 0.05,
           col = fill, border = cols$grey)
      text(cc, h - 0.5, labels[js[h]], cex = 0.7,
           col = .tile_text_col(fill))
    }
  }
  invisible(fit)
}


#' Statement contrasts between two factors
#'
#' @description
#' Per statement, the posterior contrast interval for one factor pair,
#' the posterior critical difference `delta_kl` (dashed), and the
#' grid-width consensus region ([delta_grid()], shaded). Verdict
#' colours: selected distinguishing listings, consensus statements,
#' indeterminate.
#'
#' @param fit A `bayesqm_fit` with `K >= 2`.
#' @param pair Which factor pair to draw (index into the pair list or
#'   `"f1-f2"`-style name; default 1).
#' @param q,cons_floor As in [compute_qdc()].
#'
#' @return `fit`, invisibly.
#'
#' @export
plot_contrasts <- function(fit, pair = 1, q = 0.05, cons_floor = 0.95) {
  assert_bayesqm_fit(fit)
  cols <- bayesqm_colors()
  qdc <- compute_qdc(fit, q = q, cons_floor = cons_floor)
  ct50 <- attr(compute_qdc(fit, q = q, cons_floor = cons_floor,
                           prob = 0.5), "contrasts")
  ct <- attr(qdc, "contrasts")
  dkl <- attr(qdc, "delta_kl")
  dg <- attr(qdc, "delta_grid")
  pair_ids <- unique(ct$pair)
  p <- if (is.character(pair)) match(pair, pair_ids) else as.integer(pair)
  if (is.na(p) || p < 1 || p > length(pair_ids)) .bq_abort("no such pair.")
  keep <- ct$pair == pair_ids[p]
  ct <- ct[keep, ]; ct50 <- ct50[keep, ]
  o <- order(ct$median)
  ct <- ct[o, ]; ct50 <- ct50[o, ]
  verdict <- qdc$verdict[o]
  vcol <- ifelse(grepl("^distinguishing", verdict),
                 .bq_verdict[["distinguishing"]],
                 ifelse(verdict == "consensus", .bq_verdict[["consensus"]],
                        .bq_verdict[["indeterminate"]]))
  J <- nrow(ct)

  op <- .bq_par(mar = c(4, 6, 3, 1))
  on.exit(par(op), add = TRUE)
  xr <- range(c(ct$lower, ct$upper, dkl[p], -dkl[p]))
  plot(NULL, xlim = xr, ylim = c(0.5, J + 0.5), yaxt = "n",
       xlab = sprintf("score contrast (%s)", pair_ids[p]), ylab = "",
       main = sprintf("Statement contrasts, %s", pair_ids[p]))
  rect(-dg, 0, dg, J + 1, col = adjustcolor(cols$fill, 0.5), border = NA)
  abline(v = c(-dkl[p], dkl[p]), col = cols$accent, lty = 2)
  abline(v = 0, col = cols$grey)
  text(dkl[p], J + 0.5, expression(bold(+delta[kl])), pos = 4, cex = 0.75,
       col = cols$accent, xpd = TRUE)
  text(-dkl[p], J + 0.5, expression(bold(-delta[kl])), pos = 2, cex = 0.75,
       col = cols$accent, xpd = TRUE)
  axis(2, at = seq_len(J), labels = ct$statement, las = 1, cex.axis = 0.7)
  segments(ct$lower, seq_len(J), ct$upper, seq_len(J), col = vcol, lwd = 1.2)
  segments(ct50$lower, seq_len(J), ct50$upper, seq_len(J), col = vcol,
           lwd = 3.2)
  points(ct$median, seq_len(J), pch = 19, col = vcol, cex = 0.8)
  .bq_legend("topleft",
             legend = expression("distinguishing", "consensus",
                                 "indeterminate",
                                 "consensus region (one grid column)",
                                 delta[kl] * ", critical difference"),
             col = c(unname(.bq_verdict), cols$grey, cols$accent),
             pch = c(19, 19, 19, 22, NA),
             lty = c(NA, NA, NA, NA, 2),
             pt.bg = c(NA, NA, NA, adjustcolor(cols$fill, 0.7), NA),
             pt.cex = c(0.9, 0.9, 0.9, 1.6, NA), cex = 0.72)
  invisible(fit)
}


#' The two-signal choice-of-K display
#'
#' @description
#' The whole decision in one strip, one row per ladder rung. The left
#' span shows the adequacy signal, the extra-factor percentile inside
#' its shaded band, with a warning ring where the person check found a
#' mutual unspanned cluster. The right span shows one chip per factor,
#' coloured when the factor is supported and grey when not, with the
#' reason inside: `f` means fewer than two selected flags, `d` means no
#' selected distinguishing statement. Each row ends with its own verdict
#' in words, the selected row is boxed, and when no K passes both checks
#' the conclusion is written across the bottom of the plot.
#'
#' @param x A `bayesqm_selection` from [select_k()].
#'
#' @return `x`, invisibly.
#'
#' @export
plot_choice_k <- function(x) {
  if (!inherits(x, "bayesqm_selection"))
    .bq_abort("plot_choice_k() takes a bayesqm_selection from select_k().")
  cols <- bayesqm_colors()
  tab <- x$table
  det <- x$detail
  nK <- nrow(tab)
  Kmax <- max(tab$K)
  kq <- cols$qual[(seq_len(Kmax) - 1) %% length(cols$qual) + 1]
  chipw <- 0.45 / Kmax
  cx0 <- 1.12
  vx0 <- cx0 + Kmax * chipw + 0.06
  xmax <- vx0 + 0.62

  row_word <- function(r) {
    if (!tab$adequate[r]) return("not adequate")
    if (!tab$all_supported[r]) return("adequate, but unsupported")
    if (!is.na(x$K) && tab$K[r] == x$K) return("report this one")
    "also passes"
  }
  concl <- switch(x$verdict,
    no_shared_structure = "No factor is supported at any K. Report no factor solution.",
    single_viewpoint = "The sorts agree as one shared viewpoint, consider K = 1.",
    adequate_but_unsupported = "Adequate, but no K has every factor supported.",
    no_adequate_rung = "No K is adequate. Try a larger K or read the person check.",
    tension = "The two checks disagree, read the rows before choosing.",
    NULL)

  op <- .bq_par(mar = c(6, 4.5, 4, 1))
  on.exit(par(op), add = TRUE)
  y0 <- if (is.null(concl)) 0.5 else -0.15
  plot(NULL, xlim = c(0, xmax), ylim = c(y0, nK + 0.9), axes = FALSE,
       xlab = "", ylab = "", main = "Choice of K, two signals")
  mtext(sprintf("verdict: %s", gsub("_", " ", x$verdict)), side = 3,
        line = 0.3, cex = 0.85, font = 3, col = cols$grey)

  # left span: adequacy
  rect(x$band[1], 0.5, x$band[2], nK + 0.5,
       col = adjustcolor(cols$fill, 0.4), border = NA)
  text(mean(x$band), nK + 0.7, "adequate range", cex = 0.7,
       col = cols$grey, font = 3)
  axis(1, at = seq(0, 1, 0.25), cex.axis = 0.8)
  axis(2, at = seq_len(nK), labels = paste0("K = ", tab$K), las = 1,
       tick = FALSE)
  mtext("extra-factor percentile", side = 1, line = 2.3, at = 0.5,
        cex = 0.85, font = 2)
  segments(0, seq_len(nK), 1, seq_len(nK), col = "grey92")
  points(tab$extra_factor, seq_len(nK),
         pch = ifelse(tab$adequate, 19, 21), col = cols$dark,
         bg = "white", cex = 1.4, lwd = 1.4)
  if (any(tab$cluster))
    points(tab$extra_factor[tab$cluster], which(tab$cluster), pch = 1,
           col = cols$accent, cex = 2.6, lwd = 2)

  # right span: one chip per factor, then the row's verdict in words
  abline(v = 1.06, col = "grey85")
  for (r in seq_len(nK)) {
    dr <- det[det$K == tab$K[r], ]
    for (k in seq_len(nrow(dr))) {
      xc <- cx0 + (k - 0.5) * chipw
      ok <- dr$supported[k]
      rect(xc - 0.46 * chipw, r - 0.3, xc + 0.46 * chipw, r + 0.3,
           col = if (ok) kq[k] else "grey92",
           border = if (ok) cols$grey else "grey80")
      if (!ok) {
        why <- paste0(if (dr$flags[k] < 2) "f" else "",
                      if (!dr$has_dist[k]) "d" else "")
        text(xc, r, why, col = cols$accent, cex = 0.8, font = 2)
      }
    }
    win <- !is.na(x$K) && tab$K[r] == x$K
    text(vx0, r, row_word(r), adj = 0, cex = 0.75,
         col = if (win) cols$accent else cols$grey,
         font = if (win) 2 else 3, xpd = TRUE)
    if (win)
      rect(-0.02, r - 0.45, xmax, r + 0.45, border = cols$accent, lwd = 2,
           xpd = TRUE)
  }
  text(cx0 + Kmax * chipw / 2, nK + 0.7, "every factor supported",
       cex = 0.7, col = cols$grey, font = 3)
  axis(1, at = cx0 + (seq_len(Kmax) - 0.5) * chipw,
       labels = seq_len(Kmax), tick = FALSE, cex.axis = 0.7, line = -0.7)
  mtext("factor", side = 1, line = 2.3, at = cx0 + Kmax * chipw / 2,
        cex = 0.85, font = 2)
  if (!is.null(concl))
    text(xmax / 2, 0.12, concl, cex = 0.8, font = 2, col = cols$dark,
         xpd = TRUE)
  .bq_legend(x = grconvertX(0.5, "ndc", "user"),
             y = grconvertY(0.012, "ndc", "user"),
             xjust = 0.5, yjust = 0, xpd = NA, ncol = 2,
             legend = c("in band: adequate", "coloured chip: supported",
                        "f / d: too few flags / nothing distinguishes"),
             pch = c(19, 22, NA),
             col = c(cols$dark, cols$grey, cols$accent),
             pt.bg = c(NA, kq[1], NA),
             pt.cex = c(1, 1.4, NA), cex = 0.7)
  invisible(x)
}


#' The person check against the mixed bands
#'
#' @description
#' The `m` (model agreement) by `w` (person agreement) scatter with the
#' mixed-replication bands; verdict colours, and arrows from unspanned
#' persons to their nearest partners.
#'
#' @param x A `bayesqm_persons` from [check_persons()].
#'
#' @return `x`, invisibly.
#'
#' @export
plot_person_check <- function(x) {
  if (!inherits(x, "bayesqm_persons"))
    .bq_abort("plot_person_check() takes a bayesqm_persons from check_persons().")
  cols <- bayesqm_colors()
  band_m <- attr(x, "band_m"); band_w <- attr(x, "band_w")
  vmap <- c(fits = "#17A589", no_shared = "grey72",
            unspanned = "#E67E22", atypical = "#6C3483")
  vlab <- c(fits = "fits the factors", no_shared = "no shared viewpoint",
            unspanned = "unspanned viewpoint", atypical = "atypical")

  op <- .bq_par(mar = c(4, 4, 3, 1))
  on.exit(par(op), add = TRUE)
  plot(NULL, xlim = range(c(x$m, band_m)), ylim = c(0, 1),
       xlab = "model agreement m", ylab = "person agreement w",
       main = "Person check")
  rect(band_m[1], -0.04, band_m[2], 1.04,
       col = adjustcolor(cols$fill, 0.45), border = NA)
  abline(v = band_m, col = cols$grey, lty = 3)
  text(mean(band_m), 0.02, "reference band", cex = 0.7, col = cols$grey,
       font = 3)
  segments(x$m, band_w[, 1], x$m, band_w[, 2], col = cols$gridgrey)
  points(x$m, x$w, pch = 19, col = vmap[x$verdict], cex = 1.1)
  text(x$m, x$w, x$participant, pos = 3, cex = 0.7, col = cols$grey)
  unsp <- which(x$verdict == "unspanned")
  for (i in unsp) {
    j <- if (!is.null(x$partner_index)) x$partner_index[i]
         else match(x$partner[i], x$participant)
    arrows(x$m[i], x$w[i], x$m[j], x$w[j], length = 0.08, col = cols$accent)
  }
  .bq_legend("bottomright", legend = unname(vlab), col = vmap, pch = 19,
             cex = 0.75)
  invisible(x)
}


#' Convergence and alignment view
#'
#' @description
#' Traces of the invariant person spreads `s_i` for the persons with the
#' lowest effective sample size — the series the convergence gate reads —
#' plus the per-draw congruence of the aligned draws to the pivot, with
#' the gate report in the margin. A congruence histogram hugging 1 says
#' the alignment found one common orientation; a long left tail says some
#' draws sit far from it.
#'
#' @param fit A `bayesqm_fit`.
#' @param n_series How many worst-ESS persons to trace (default 3).
#'
#' @return `fit`, invisibly.
#'
#' @export
plot_convergence <- function(fit, n_series = 3) {
  assert_bayesqm_fit(fit)
  cols <- bayesqm_colors()
  s <- fit$draws$s_i
  ess <- apply(s, 2, function(x) conv_stats(x)["bulk"])
  worst <- order(ess)[seq_len(min(n_series, ncol(s)))]
  g <- fit$gate

  op <- .bq_par(mfrow = c(length(worst) + 1, 1), mar = c(2, 4, 1.5, 1),
                oma = c(2, 0, 2, 0))
  on.exit(par(op), add = TRUE)
  for (i in worst) {
    plot(s[, i], type = "l", col = cols$dark, xlab = "", ylab = "s_i",
         main = sprintf("%s (bulk ESS %.0f)", colnames(s)[i], ess[i]),
         cex.main = 0.9)
  }
  cg <- fit$align$congruence
  hist(cg, breaks = 30, col = cols$fill, border = cols$grey,
       xlim = c(min(cg, 0.8), 1), xlab = "", ylab = "draws",
       main = sprintf("alignment congruence (mean %.2f)", mean(cg)),
       cex.main = 0.9)
  mtext(sprintf("gate %s: max Rhat %.3f, min ESS %.0f bulk / %.0f tail (%d iterations%s)",
                if (g$converged) "passed" else "NOT MET", g$rhat, g$ess_bulk,
                g$ess_tail, g$iterations,
                if (g$extended) ", warm-extended" else ""),
        outer = TRUE, side = 3, cex = 0.85)
  invisible(fit)
}


#' Posterior-predictive check display
#'
#' @description
#' The replicated distributions behind [check_fit()]: the agreement RMSE
#' against its double-replicate reference, and the observed extra-factor
#' eigenvalue in its replicated distribution.
#'
#' @param x A `bayesqm_checks` from [check_fit()].
#'
#' @return `x`, invisibly.
#'
#' @export
plot_ppc <- function(x) {
  if (!inherits(x, "bayesqm_checks"))
    .bq_abort("plot_ppc() takes a bayesqm_checks from check_fit().")
  cols <- bayesqm_colors()
  op <- .bq_par(mfrow = c(1, 2), mar = c(4, 4, 3, 1))
  on.exit(par(op), add = TRUE)

  a <- x$agreement
  hist(a$ref, breaks = 20, col = cols$fill, border = cols$grey,
       xlim = range(c(a$ref, a$obs)), xlab = "agreement RMSE",
       main = sprintf("Agreement check (p = %.2f)", a$p))
  hist(a$obs, breaks = 20, col = adjustcolor(cols$qual[2], 0.55),
       border = NA, add = TRUE)
  .bq_legend("topright", legend = c("reference", "observed"),
             fill = c(cols$fill, adjustcolor(cols$qual[2], 0.55)),
             border = c(cols$grey, NA), cex = 0.75)

  e <- x$extra_factor
  hist(e$replicated, breaks = 20, col = cols$fill, border = cols$grey,
       xlim = range(c(e$replicated, e$observed)),
       xlab = expression(e[K + 1]),
       main = sprintf("Extra-factor check (percentile %.2f)", e$percentile))
  abline(v = e$observed, col = cols$accent, lwd = 2)
  .bq_legend("topright", legend = c("replicated", "observed"),
             fill = c(cols$fill, NA), border = c(cols$grey, NA),
             lty = c(NA, 1), lwd = c(NA, 2),
             col = c(NA, cols$accent), cex = 0.75)
  invisible(x)
}


#' @rdname plot_loading_posterior
#' @param x,... A `bayesqm_fit` and arguments passed on.
#' @export
plot.bayesqm_fit <- function(x, ...) plot_loading_posterior(x, ...)
