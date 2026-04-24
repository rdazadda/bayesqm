# autoplot.R
# Direct ports of the paper's figure functions (figures_real_data.R),
# plus the ggplot2 autoplot dispatchers for bayesqm_fit / bayesqm_run.
# Methods are registered in .onLoad() only when ggplot2 is installed.


.bq_need <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE))
    stop("Package '", pkg,
         "' is required. Install.packages('", pkg, "').",
         call. = FALSE)
}


# Paper's publication theme.
THEME_PUB <- function() {
  .bq_need("ggplot2")
  ggplot2::theme_bw(base_size = 11) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      legend.position  = "bottom",
      strip.background = ggplot2::element_rect(
        fill = "grey95", color = "grey40", linewidth = 0.3),
      strip.text       = ggplot2::element_text(face = "bold", size = 10),
      plot.title       = ggplot2::element_text(face = "bold", size = 11,
                                               hjust = 0),
      plot.subtitle    = ggplot2::element_text(size = 9, color = "grey30",
                                               hjust = 0)
    )
}


#' Delta-ELPD plot with Sivula band, peak, and adopted-K annotations
#'
#' @description
#' Direct port of the paper's Figure E1 renderer. Draws
#' \eqn{\Delta}ELPD against K with +/- 1.96 SE whiskers, shades the
#' Sivula rejection band (\eqn{|\Delta \mathrm{ELPD}| < 4}), and marks
#' the Sivula-selected K (red triangle), the ELPD peak (blue square),
#' and an optional adopted K (orange diamond).
#'
#' @param run A `bayesqm_run` object.
#' @param title Optional panel title.
#' @param adopted Integer K adopted by the analyst (e.g. the value
#'   reported in a paper). Marked with the orange diamond. `NULL`
#'   suppresses this annotation.
#'
#' @return A `ggplot` object.
#' @export
make_elpd_diff <- function(run, title = NULL, adopted = NULL) {
  stopifnot(inherits(run, "bayesqm_run"))
  .bq_need("ggplot2")

  K_ref  <- run$tab$K[1]
  K_vals <- run$tab$K
  elpd_diff <- numeric(length(K_vals))
  se_diff   <- numeric(length(K_vals))

  for (i in seq_along(K_vals)) {
    k <- K_vals[i]
    elpd_diff[i] <- run$tab$elpd[i] - run$tab$elpd[1]
    if (k != K_ref &&
        !is.null(run$loo_list) &&
        !is.null(run$loo_list[[1]]) &&
        !is.null(run$loo_list[[i]])) {
      comp <- tryCatch(
        loo::loo_compare(list(run$loo_list[[1]], run$loo_list[[i]])),
        error = function(e) NULL)
      if (!is.null(comp) && nrow(comp) >= 2)
        se_diff[i] <- comp[2, "se_diff"]
    }
    if (se_diff[i] == 0 && k != K_ref && !is.na(run$tab$se[i]))
      se_diff[i] <- run$tab$se[i]
  }

  df <- data.frame(K = K_vals, diff = elpd_diff, se = se_diff)
  sel_sivula <- run$k_sivula
  sel_peak   <- K_vals[which.max(elpd_diff)]

  df$role <- ""
  if (!is.na(sel_sivula))
    df$role[df$K == sel_sivula] <- "Sivula"
  df$role[df$K == sel_peak] <- paste0(
    df$role[df$K == sel_peak],
    ifelse(df$role[df$K == sel_peak] == "", "", " / "),
    "Peak")
  if (!is.null(adopted) && adopted %in% df$K)
    df$role[df$K == adopted] <- paste0(
      df$role[df$K == adopted],
      ifelse(df$role[df$K == adopted] == "", "", " / "),
      "Adopted")

  subtitle_parts <- character(0)
  if (!is.na(sel_sivula))
    subtitle_parts <- c(subtitle_parts,
                        sprintf("Sivula-selected K = %d", sel_sivula))
  subtitle_parts <- c(subtitle_parts,
                      sprintf("ELPD peak K = %d", sel_peak))
  if (!is.null(adopted))
    subtitle_parts <- c(subtitle_parts,
                        sprintf("adopted K = %d", adopted))
  subtitle_text <- paste(subtitle_parts, collapse = "; ")

  ymax <- max(df$diff + 1.96 * df$se, 5)
  ymin <- min(df$diff - 1.96 * df$se, -5)
  ymax <- ymax + 0.18 * (ymax - ymin)

  p <- ggplot2::ggplot(df, ggplot2::aes(.data$K, .data$diff)) +
    ggplot2::annotate("rect", xmin = -Inf, xmax = Inf,
                      ymin = -4, ymax = 4,
                      fill = "grey85", alpha = 0.55) +
    ggplot2::annotate("text", x = max(df$K), y = -3.6,
                      label = "list(group('|', Delta*elpd, '|') < 4, ' (Sivula rejects)')",
                      parse = TRUE,
                      hjust = 1, size = 2.8, color = "grey30",
                      fontface = "italic") +
    ggplot2::geom_hline(yintercept = 0, color = "grey60",
                        linewidth = 0.4) +
    ggplot2::geom_line(color = "grey25", linewidth = 0.6) +
    ggplot2::geom_errorbar(
      ggplot2::aes(ymin = .data$diff - 1.96 * .data$se,
                   ymax = .data$diff + 1.96 * .data$se),
      width = 0.10, color = "grey25", linewidth = 0.5) +
    ggplot2::geom_point(size = 3, color = "grey15")

  if (!is.na(sel_sivula))
    p <- p + ggplot2::geom_point(
      data = df[df$K == sel_sivula, ],
      size = 4.5, shape = 17, color = "#d62728")
  if (!is.na(sel_peak) && !identical(sel_peak, sel_sivula))
    p <- p + ggplot2::geom_point(
      data = df[df$K == sel_peak, ],
      size = 4.5, shape = 15, color = "#1f77b4")
  if (!is.null(adopted) && !(adopted %in% c(sel_sivula, sel_peak)))
    p <- p + ggplot2::geom_point(
      data = df[df$K == adopted, ],
      size = 4.5, shape = 18, color = "#ff7f0e")

  p +
    ggplot2::geom_text(data = df[df$role != "", ],
                       ggplot2::aes(label = .data$role),
                       nudge_y = 0.12 * (ymax - ymin),
                       size = 2.8, color = "grey20", fontface = "bold") +
    ggplot2::scale_x_continuous(breaks = K_vals) +
    ggplot2::scale_y_continuous(limits = c(ymin, ymax)) +
    ggplot2::labs(
      x = "Number of factors K",
      y = expression(paste(Delta, "ELPD vs K = 1")),
      title = title, subtitle = subtitle_text) +
    THEME_PUB()
}


#' Probabilistic dominant-factor panel
#'
#' @description
#' Direct port of the paper's Figure E2 renderer. Draws a blue-gradient
#' heatmap of `P(dominant factor = k)` per participant, with a right-
#' hand "Assignment" strip (orange-red gradient) showing the verdict
#' "Strong / Mod. / Weak F-k" for each participant.
#'
#' @param fit A `bayesqm_fit`.
#' @param title Optional panel title.
#' @param anonymize Logical; when `TRUE`, participants are relabelled
#'   `P01..PNN`.
#'
#' @return A `ggplot` object.
#' @export
make_dominant_panel <- function(fit, title = NULL, anonymize = TRUE) {
  stopifnot(inherits(fit, "bayesqm_fit"))
  .bq_need("ggplot2")
  .bq_need("scales")

  Ld <- fit$Lambda_draws
  Y  <- fit$dataset
  K  <- fit$brief$K
  N  <- ncol(Y)

  prob <- compute_dominant_prob(Ld)

  maxprob    <- apply(prob, 1, max)
  dom_factor <- apply(prob, 1, which.max)
  ord <- order(dom_factor, -maxprob)

  n.strong <- sum(maxprob >  0.80)
  n.mod    <- sum(maxprob >  0.60 & maxprob <= 0.80)
  n.weak   <- sum(maxprob <= 0.60)
  subtitle_text <- sprintf(
    "Strong (max P > 0.80): %d    Moderate (0.60–0.80): %d    Weak (≤ 0.60): %d",
    n.strong, n.mod, n.weak)

  pid <- if (anonymize) sprintf("P%02d", seq_len(N)) else colnames(Y)
  pid_ord <- pid[ord]

  df <- do.call(rbind, lapply(seq_len(K), function(k)
    data.frame(participant = factor(pid, levels = pid_ord),
               col         = paste0("Factor ", k),
               prob        = prob[, k],
               stringsAsFactors = FALSE)))

  conf_label <- "Assignment"
  tier_label <- ifelse(maxprob > 0.80, "Strong",
                ifelse(maxprob > 0.60, "Mod.", "Weak"))
  verdict <- sprintf("%s F%d", tier_label, dom_factor)
  df_conf <- data.frame(
    participant = factor(pid, levels = pid_ord),
    col         = conf_label,
    maxp        = maxprob,
    verdict     = verdict,
    stringsAsFactors = FALSE)

  x_levels <- c(paste0("Factor ", seq_len(K)), conf_label)
  df$col      <- factor(df$col,      levels = x_levels)
  df_conf$col <- factor(df_conf$col, levels = x_levels)

  ggplot2::ggplot() +
    ggplot2::geom_tile(data = df,
                       ggplot2::aes(.data$col, .data$participant,
                                    fill = .data$prob),
                       color = "white", linewidth = 0.4) +
    ggplot2::geom_text(data = df,
                       ggplot2::aes(.data$col, .data$participant,
                                    label = sprintf("%.2f", .data$prob),
                                    color = ifelse(.data$prob > 0.6,
                                                   "white", "grey15")),
                       size = 2.2, show.legend = FALSE) +
    ggplot2::scale_color_identity() +
    ggplot2::scale_fill_gradient2(
      low = "white", mid = "#c6dbef", high = "#08519c",
      midpoint = 0.5, limits = c(0, 1), name = "P(dominant)") +
    ggplot2::geom_tile(
      data = df_conf,
      ggplot2::aes(.data$col, .data$participant),
      fill = scales::gradient_n_pal(
        c("#fff7ec", "#fdbb84", "#d7301f"))(df_conf$maxp),
      color = "white", linewidth = 0.4) +
    ggplot2::geom_text(
      data = df_conf,
      ggplot2::aes(.data$col, .data$participant,
                   label = .data$verdict),
      color = ifelse(df_conf$maxp > 0.75, "white", "grey15"),
      size = 1.9, fontface = "bold", show.legend = FALSE) +
    ggplot2::labs(x = NULL, y = NULL,
                  title = title, subtitle = subtitle_text) +
    ggplot2::theme_minimal(base_size = 9) +
    ggplot2::theme(
      axis.text.y      = ggplot2::element_text(size = 7),
      axis.text.x      = ggplot2::element_text(size = 9),
      panel.grid       = ggplot2::element_blank(),
      plot.title       = ggplot2::element_text(face = "bold", size = 10.5,
                                               hjust = 0),
      plot.subtitle    = ggplot2::element_text(size = 7.8, color = "grey25",
                                               hjust = 0),
      legend.position  = "right")
}


#' Posterior predictive RMSE ridgeline across K
#'
#' @description
#' Direct port of the paper's Figure E4 renderer. Draws a ridgeline
#' density of the posterior predictive correlation-matrix RMSE
#' (\eqn{RMSE_R}) at every K in `run`, with a median tick per ridge.
#'
#' @param run A `bayesqm_run`.
#' @param title Optional panel title.
#'
#' @return A `ggplot` object.
#' @export
make_ppc_ridge <- function(run, title = NULL) {
  stopifnot(inherits(run, "bayesqm_run"))
  .bq_need("ggplot2")
  .bq_need("ggridges")

  K_vals <- run$tab$K
  rows <- list()
  for (i in seq_along(K_vals)) {
    k <- K_vals[i]
    fit <- run$fits[[i]]
    r <- if (!is.null(fit)) fit$ppc$rmse.r else NULL
    if (!is.null(r) && length(r) > 0)
      rows[[length(rows) + 1]] <- data.frame(
        rmse = r,
        K    = factor(paste0("K = ", k),
                      levels = paste0("K = ", rev(K_vals))),
        stringsAsFactors = FALSE)
  }
  if (length(rows) == 0)
    stop("No posterior predictive draws stored on the run's fits.")
  df <- do.call(rbind, rows)

  meds <- aggregate(rmse ~ K, data = df, median)

  ggplot2::ggplot(df, ggplot2::aes(x = .data$rmse,
                                   y = .data$K,
                                   fill = .data$K)) +
    ggridges::geom_density_ridges(
      alpha = 0.85, rel_min_height = 0.01,
      scale = 1.05, linewidth = 0.35, color = "grey30") +
    ggplot2::geom_point(
      data = meds, ggplot2::aes(x = .data$rmse, y = .data$K),
      shape = 108, size = 6, color = "black",
      inherit.aes = FALSE, stroke = 1.2) +
    ggplot2::scale_fill_viridis_d(option = "viridis",
                                  direction = -1, name = NULL) +
    ggplot2::labs(
      x = expression(RMSE[R] ~ "  (by-person correlation discrepancy, lower is better)"),
      y = NULL, title = title) +
    THEME_PUB() +
    ggplot2::theme(legend.position = "none",
                   axis.text.y = ggplot2::element_text(face = "bold",
                                                      size = 9))
}


#' ggplot2 renderings of a bayesqm_fit
#'
#' @description
#' Generic [ggplot2::autoplot()] method for `bayesqm_fit`. Dispatches
#' to the paper-figure renderer when `type = "membership"`; uses
#' `ggdist::stat_pointinterval` / `stat_halfeye` for the remaining
#' views.
#'
#' @param object A `bayesqm_fit`.
#' @param type One of `"loadings"`, `"zscores"`, `"membership"`,
#'   `"hyper"`, or `"zscore_posterior"`.
#' @param statement For `type = "zscore_posterior"`, an integer index
#'   or statement name.
#' @param ... Passed to the underlying figure function (e.g. `title`,
#'   `anonymize` for membership).
#'
#' @return A `ggplot` object.
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
    loadings         = .autoplot_loadings(object),
    zscores          = .autoplot_zscores(object),
    membership       = make_dominant_panel(object, ...),
    hyper            = .autoplot_hyper(object),
    zscore_posterior = .autoplot_zscore_posterior(object, statement))
}


#' ggplot2 renderings of a bayesqm_run
#'
#' @description
#' Generic [ggplot2::autoplot()] method for `bayesqm_run`. Dispatches
#' to the paper-figure renderers for ELPD (`type = "elpd"`, default)
#' and posterior-predictive RMSE ridgeline (`type = "ppc"`).
#'
#' @param object A `bayesqm_run`.
#' @param type One of `"elpd"` or `"ppc"`.
#' @param ... Passed to the underlying figure function (e.g.
#'   `adopted`, `title`).
#'
#' @return A `ggplot` object.
#' @name autoplot.bayesqm_run
#' @keywords internal
autoplot.bayesqm_run <- function(object, type = c("elpd", "ppc"), ...) {
  type <- match.arg(type)
  .bq_need("ggplot2")
  switch(type,
    elpd = make_elpd_diff(object, ...),
    ppc  = make_ppc_ridge(object, ...))
}


.autoplot_loadings <- function(fit) {
  .bq_need("ggdist")
  cols <- bayesqm_colors()

  L <- fit$Lambda_draws
  Td <- dim(L)[1]; N <- dim(L)[2]; K <- dim(L)[3]
  fac_names  <- colnames(fit$loa)
  part_names <- rownames(fit$loa)

  med_f1 <- apply(L[, , 1, drop = FALSE], 2, median)
  ord_names <- part_names[order(med_f1)]

  df <- data.frame(
    value       = as.vector(L),
    draw        = rep(seq_len(Td), times = N * K),
    participant = rep(rep(part_names, each = Td), times = K),
    factor      = rep(fac_names, each = Td * N),
    stringsAsFactors = FALSE)
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
    stringsAsFactors = FALSE)
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
    stringsAsFactors = FALSE)
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


`%||%` <- function(a, b) if (is.null(a)) b else a
