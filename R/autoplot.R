# autoplot.R
# ggplot2 / ggdist adapters for bayesqm objects. These methods are only
# registered when ggplot2 is installed (see .onLoad in zzz.R), so the
# package loads and runs without ggplot2 for users who prefer base R.
#
# The autoplot API is intentionally narrow: one method per object type
# (bayesqm_fit, bayesqm_run) with a `type` argument that selects among
# the canonical views. The rendering uses ggdist's slabinterval idiom
# -- stat_halfeye for densities, stat_pointinterval for forests --
# which is the 2026 Bayesian-publication standard.


.bq_need <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE))
    stop("Package '", pkg,
         "' is required for autoplot(). Install.packages('", pkg, "').",
         call. = FALSE)
}


#' ggplot2 renderings of a bayesqm_fit
#'
#' @description
#' Generic [ggplot2::autoplot()] method for `bayesqm_fit`. Unlike the
#' base-R [plot.bayesqm_fit()], these renderings use
#' `ggdist::stat_pointinterval` and `ggdist::stat_halfeye` for
#' publication-grade posterior summaries.
#'
#' @param object A `bayesqm_fit`.
#' @param type One of `"loadings"`, `"zscores"`, `"membership"`,
#'   `"hyper"`, or `"zscore_posterior"`.
#' @param statement For `type = "zscore_posterior"`, an integer index
#'   or statement name.
#' @param ... Ignored.
#'
#' @return A `ggplot` object.
#'
#' @name autoplot.bayesqm_fit
#' @keywords internal
autoplot.bayesqm_fit <- function(object,
                                 type = c("loadings", "zscores",
                                          "membership", "hyper",
                                          "zscore_posterior"),
                                 statement = NULL, ...) {
  type <- match.arg(type)
  .bq_need("ggplot2")

  switch(type,
    loadings          = .autoplot_loadings(object),
    zscores           = .autoplot_zscores(object),
    membership        = .autoplot_membership(object),
    hyper             = .autoplot_hyper(object),
    zscore_posterior  = .autoplot_zscore_posterior(object, statement))
}


#' ggplot2 rendering of the ELPD curve for a bayesqm_run
#'
#' @description
#' [ggplot2::autoplot()] method for a `bayesqm_run`. Draws ELPD
#' against K with +/- 1.96 SE whiskers and peak / Sivula markers.
#'
#' @param object A `bayesqm_run`.
#' @param ... Ignored.
#'
#' @return A `ggplot` object.
#'
#' @name autoplot.bayesqm_run
#' @keywords internal
autoplot.bayesqm_run <- function(object, ...) {
  .bq_need("ggplot2")
  cols <- bayesqm_colors()

  tab <- object$tab
  lo  <- tab$elpd - 1.96 * tab$se
  hi  <- tab$elpd + 1.96 * tab$se
  df  <- data.frame(K = tab$K, elpd = tab$elpd, lo = lo, hi = hi)

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$K, y = .data$elpd)) +
    ggplot2::geom_errorbar(ggplot2::aes(ymin = .data$lo,
                                        ymax = .data$hi),
                           width = 0.15, linewidth = 0.5) +
    ggplot2::geom_point(shape = 21, fill = "white",
                        colour = cols$dark, size = 3, stroke = 1) +
    ggplot2::scale_x_continuous(breaks = df$K) +
    ggplot2::labs(x = "Number of factors (K)",
                  y = "ELPD (leave-one-out)",
                  title = sprintf("ELPD across K (case: %s)",
                                  object$case %||% "NA")) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank())

  if (!is.na(object$k_peak))
    p <- p + ggplot2::geom_vline(xintercept = object$k_peak,
                                 linewidth = 0.7, colour = cols$dark) +
      ggplot2::annotate("text", x = object$k_peak,
                        y = max(df$hi, na.rm = TRUE),
                        label = " Peak", hjust = 0,
                        colour = cols$dark, size = 3.3)
  if (!is.na(object$k_sivula) && object$k_sivula != object$k_peak)
    p <- p + ggplot2::geom_vline(xintercept = object$k_sivula,
                                 linewidth = 0.7, linetype = 2,
                                 colour = cols$dark) +
      ggplot2::annotate("text", x = object$k_sivula,
                        y = max(df$hi, na.rm = TRUE),
                        label = " Sivula", hjust = 0,
                        colour = cols$dark, size = 3.3)
  p
}


.autoplot_loadings <- function(fit) {
  .bq_need("ggdist")
  cols <- bayesqm_colors()

  L <- fit$Lambda_draws
  Td <- dim(L)[1]; N <- dim(L)[2]; K <- dim(L)[3]
  fac_names  <- colnames(fit$loa)
  part_names <- rownames(fit$loa)

  # Sort participants by factor-1 median for a stable y-axis.
  med_f1 <- apply(L[, , 1, drop = FALSE], 2, median)
  ord_names <- part_names[order(med_f1)]

  df <- data.frame(
    value       = as.vector(L),
    draw        = rep(seq_len(Td), times = N * K),
    participant = rep(rep(part_names, each = Td), times = K),
    factor      = rep(fac_names, each = Td * N),
    stringsAsFactors = FALSE
  )
  df$participant <- factor(df$participant, levels = ord_names)
  df$factor      <- factor(df$factor, levels = fac_names)

  brown <- 1.96 / sqrt(fit$brief$J)

  ggplot2::ggplot(df, ggplot2::aes(x = .data$value,
                                   y = .data$participant)) +
    ggplot2::geom_vline(xintercept = 0, linetype = 3,
                        colour = cols$grey) +
    ggplot2::geom_vline(xintercept = c(-brown, brown),
                        linetype = 2, colour = cols$gridgrey) +
    ggdist::stat_pointinterval(
      .width = c(0.5, fit$brief$prob),
      point_colour = cols$dark,
      interval_colour = cols$dark,
      point_fill = "white",
      shape = 21, point_size = 1.8) +
    ggplot2::facet_wrap(~ factor, nrow = 1) +
    ggplot2::labs(x = "Loading", y = NULL) +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                   axis.text.y = ggplot2::element_text(size = 7))
}


.autoplot_zscores <- function(fit) {
  .bq_need("ggdist")
  cols <- bayesqm_colors()

  F <- fit$F_draws
  Td <- dim(F)[1]; J <- dim(F)[2]; K <- dim(F)[3]
  stmt_names <- dimnames(F)[[2]]
  fac_names  <- dimnames(F)[[3]]
  if (is.null(stmt_names)) stmt_names <- paste0("S", seq_len(J))
  if (is.null(fac_names))  fac_names  <- paste0("f", seq_len(K))

  med_f1 <- apply(F[, , 1, drop = FALSE], 2, median)
  ord_names <- stmt_names[order(med_f1)]

  df <- data.frame(
    value     = as.vector(F),
    draw      = rep(seq_len(Td), times = J * K),
    statement = rep(rep(stmt_names, each = Td), times = K),
    factor    = rep(fac_names, each = Td * J),
    stringsAsFactors = FALSE
  )
  df$statement <- factor(df$statement, levels = ord_names)
  df$factor    <- factor(df$factor, levels = fac_names)

  ggplot2::ggplot(df, ggplot2::aes(x = .data$value,
                                   y = .data$statement)) +
    ggplot2::geom_vline(xintercept = 0, linetype = 3,
                        colour = cols$grey) +
    ggdist::stat_pointinterval(
      .width = c(0.5, fit$brief$prob),
      point_colour = cols$dark,
      interval_colour = cols$dark,
      point_fill = "white",
      shape = 21, point_size = 1.8) +
    ggplot2::facet_wrap(~ factor, nrow = 1) +
    ggplot2::labs(x = "z-score", y = NULL) +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                   axis.text.y = ggplot2::element_text(size = 7))
}


.autoplot_membership <- function(fit) {
  cols <- bayesqm_colors()

  prob <- compute_dominant_prob(fit$Lambda_draws)
  tier <- classify_membership(fit$Lambda_draws)

  ord <- order(tier$dominant_factor,
               as.integer(tier$tier),
               -tier$max_prob)
  prob <- prob[ord, , drop = FALSE]
  tier <- tier[ord, , drop = FALSE]

  df <- data.frame(
    participant = rep(rownames(prob), times = ncol(prob)),
    factor      = rep(colnames(prob), each = nrow(prob)),
    probability = as.vector(prob),
    stringsAsFactors = FALSE
  )
  df$participant <- factor(df$participant, levels = rownames(prob))
  df$factor      <- factor(df$factor,      levels = colnames(prob))

  ggplot2::ggplot(df, ggplot2::aes(x = .data$factor,
                                   y = .data$participant,
                                   fill = .data$probability)) +
    ggplot2::geom_tile(colour = "white", linewidth = 0.3) +
    ggplot2::scale_fill_gradientn(
      colours = c(cols$light, cols$mid, cols$dark),
      limits = c(0, 1),
      name = "P(dominant)") +
    ggplot2::labs(x = NULL, y = NULL,
                  title = "Dominant-factor posterior probability") +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(panel.grid = ggplot2::element_blank(),
                   axis.text.y = ggplot2::element_text(size = 7))
}


.autoplot_hyper <- function(fit) {
  .bq_need("ggdist")
  cols <- bayesqm_colors()

  hp <- fit$hyperparams
  avail <- c("nu", "sigma", "tau")
  avail <- avail[vapply(avail, function(p) {
    v <- hp[[p]]
    !is.null(v) && sum(is.finite(v)) >= 2L
  }, logical(1))]

  if (length(avail) == 0L)
    stop("No non-empty hyperparameter draws to plot.")

  df <- do.call(rbind, lapply(avail, function(p) {
    v <- hp[[p]]
    v <- v[is.finite(v)]
    data.frame(parameter = p, value = v, stringsAsFactors = FALSE)
  }))
  df$parameter <- factor(df$parameter, levels = avail)

  ggplot2::ggplot(df, ggplot2::aes(x = .data$value,
                                   y = .data$parameter)) +
    ggdist::stat_halfeye(
      .width = c(0.5, fit$brief$prob),
      fill = cols$fill,
      slab_colour = cols$dark,
      slab_linewidth = 0.4,
      interval_colour = cols$dark,
      point_colour = cols$dark) +
    ggplot2::labs(x = NULL, y = NULL,
                  title = "Hyperparameter posteriors") +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank())
}


.autoplot_zscore_posterior <- function(fit, statement) {
  .bq_need("ggdist")
  cols <- bayesqm_colors()

  if (is.null(statement))
    stop("statement is required for type = 'zscore_posterior'.")

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

  df <- data.frame(
    factor = rep(fac_names, each = dim(F)[1]),
    value  = as.vector(F[, j, ]),
    stringsAsFactors = FALSE
  )
  df$factor <- factor(df$factor, levels = fac_names)

  ggplot2::ggplot(df, ggplot2::aes(x = .data$value,
                                   y = .data$factor)) +
    ggplot2::geom_vline(xintercept = 0, linetype = 3,
                        colour = cols$grey) +
    ggdist::stat_halfeye(
      .width = c(0.5, fit$brief$prob),
      fill = cols$fill,
      slab_colour = cols$dark,
      slab_linewidth = 0.4,
      interval_colour = cols$dark,
      point_colour = cols$dark) +
    ggplot2::labs(x = "z-score", y = NULL,
                  title = sprintf("Posterior z-score: %s",
                                  stmt_names[j])) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank())
}


# Tiny null-coalesce to match the one already used in import.R; avoids
# an extra dependency.
`%||%` <- function(a, b) if (is.null(a)) b else a
