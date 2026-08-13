# autoplot.R
# ggplot2 versions of the flagship views, registered on ggplot2's
# autoplot generic in .onLoad. ggplot2 is a soft dependency; the base
# plot_* functions carry every view regardless.

#' @keywords internal
#' @noRd
autoplot.bayesqm_fit <- function(object,
                                 type = c("loadings", "flags", "contrasts",
                                          "array"),
                                 ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    .bq_abort("autoplot needs ggplot2; the base plot_* functions do not.")
  type <- match.arg(type)
  cols <- bayesqm_colors()
  fac_ids <- dimnames(object$draws$sigma)[[2]]
  K <- object$brief$K
  kq <- cols$qual[(seq_len(K) - 1) %% length(cols$qual) + 1]
  qual <- stats::setNames(kq, fac_ids)

  if (type == "loadings") {
    lo <- compute_loadings(object)
    long <- do.call(rbind, lapply(fac_ids, function(f)
      data.frame(participant = lo$participant, factor = f,
                 loading = lo[[paste0(f, "_loading")]],
                 lower = lo[[paste0(f, "_lower")]],
                 upper = lo[[paste0(f, "_upper")]])))
    p <- ggplot2::ggplot(long, ggplot2::aes(
           x = .data$loading, y = .data$participant,
           colour = .data$factor, shape = .data$factor)) +
      ggplot2::geom_vline(xintercept = 0, colour = cols$grey) +
      ggplot2::geom_errorbar(ggplot2::aes(xmin = .data$lower,
                                          xmax = .data$upper),
                             width = 0, orientation = "y",
                             position = ggplot2::position_dodge(0.6)) +
      ggplot2::geom_point(position = ggplot2::position_dodge(0.6)) +
      ggplot2::scale_colour_manual(values = qual) +
      ggplot2::xlim(-1, 1) +
      ggplot2::labs(x = "bounded loading", y = NULL)
    return(p)
  }

  if (type == "flags") {
    fl <- compute_flags(object, ...)
    phi <- attr(fl, "phi")
    long <- data.frame(
      participant = rep(rownames(phi), ncol(phi)),
      state = rep(colnames(phi), each = nrow(phi)),
      prob = as.vector(phi))
    long$state <- factor(long$state, levels = rev(colnames(phi)))
    fill <- c(stats::setNames(rep(kq, each = 2),
                              colnames(phi)[seq_len(2 * K)]),
              unclassified = cols$gridgrey)
    p <- ggplot2::ggplot(long, ggplot2::aes(
           x = .data$prob, y = .data$participant, fill = .data$state)) +
      ggplot2::geom_col(colour = "white", linewidth = 0.2) +
      ggplot2::scale_fill_manual(values = fill) +
      ggplot2::labs(x = "posterior probability", y = NULL, fill = NULL)
    return(p)
  }

  if (type == "contrasts") {
    qdc <- compute_qdc(object, ...)
    ct <- attr(qdc, "contrasts")
    dkl <- attr(qdc, "delta_kl")
    dg <- attr(qdc, "delta_grid")
    verdict <- ifelse(grepl("^distinguishing", qdc$verdict), "distinguishing",
                      qdc$verdict)
    ct$verdict <- verdict[match(ct$statement, qdc$statement)]
    p <- ggplot2::ggplot(ct, ggplot2::aes(
           x = .data$median, y = stats::reorder(.data$statement, .data$median),
           colour = .data$verdict)) +
      ggplot2::annotate("rect", xmin = -dg, xmax = dg, ymin = -Inf,
                        ymax = Inf, fill = cols$fill, alpha = 0.4) +
      ggplot2::geom_vline(data = data.frame(pair = rep(names(dkl), each = 2),
                                            x = as.vector(rbind(-dkl, dkl))),
                          ggplot2::aes(xintercept = .data$x),
                          colour = cols$accent, linetype = 2) +
      ggplot2::geom_errorbar(ggplot2::aes(xmin = .data$lower,
                                          xmax = .data$upper),
                             width = 0, orientation = "y") +
      ggplot2::geom_point() +
      ggplot2::facet_wrap(~pair) +
      ggplot2::scale_colour_manual(values = c(
        distinguishing = .bq_verdict[["distinguishing"]],
        consensus = .bq_verdict[["consensus"]],
        indeterminate = .bq_verdict[["indeterminate"]])) +
      ggplot2::labs(x = "score contrast", y = NULL, colour = NULL)
    return(p)
  }

  # array
  ar <- compute_factor_array(object)
  cert <- attr(ar, "certainty")
  long <- do.call(rbind, lapply(seq_len(K), function(k) {
    slot <- ar[[paste0(fac_ids[k], "_grid")]]
    height <- stats::ave(slot, slot, FUN = seq_along)
    data.frame(statement = ar$statement, factor = fac_ids[k],
               column = slot, height = height,
               certainty = cert[, k])
  }))
  p <- ggplot2::ggplot(long, ggplot2::aes(
         x = .data$column, y = .data$height, fill = .data$certainty)) +
    ggplot2::geom_tile(colour = cols$grey, width = 0.9, height = 0.9) +
    ggplot2::geom_text(ggplot2::aes(label = .data$statement), size = 2.6) +
    ggplot2::scale_fill_gradientn(colours = .bq_certainty,
                                  limits = c(0, 1)) +
    ggplot2::facet_wrap(~factor) +
    ggplot2::labs(x = "grid column", y = NULL, fill = "certainty") +
    ggplot2::theme(axis.text.y = ggplot2::element_blank(),
                   axis.ticks.y = ggplot2::element_blank())
  p
}
