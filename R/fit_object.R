# fit_object.R
# The bayesqm_fit and bayesqm_run S3 classes: constructors that assemble
# qmethod-parallel slots ($brief, $loa, $zsc, $zsc_n, $f_char, $qdc) on
# top of the raw Bayesian quantities, plus their print and summary methods.


#' @keywords internal
#' @noRd
new_bayesqm_fit <- function(call, Y, K, distribution, prob, robust, nu,
                            chains, iter, warmup, backend, priors,
                            Lhat, Lmed, ci_lo, ci_hi,
                            Lambda_draws, F_draws, align_info, hyperparams,
                            loo_el, loo_ps, diag, ppc, delta = NULL) {
  N <- ncol(Y); J <- nrow(Y)

  stmt_ids <- rownames(Y); if (is.null(stmt_ids)) stmt_ids <- paste0("S", seq_len(J))
  part_ids <- colnames(Y); if (is.null(part_ids)) part_ids <- paste0("P", seq_len(N))
  fac_ids  <- paste0("f", seq_len(K))

  dimnames(Lhat) <- dimnames(Lmed) <- dimnames(ci_lo) <- dimnames(ci_hi) <-
    list(part_ids, fac_ids)
  dimnames(Lambda_draws)[[2]] <- part_ids
  dimnames(Lambda_draws)[[3]] <- fac_ids
  dimnames(F_draws)[[2]] <- stmt_ids
  dimnames(F_draws)[[3]] <- fac_ids

  zsc <- .summarize_draws(F_draws, mean)
  dimnames(zsc) <- list(stmt_ids, fac_ids)
  zsc_n <- rank_to_grid(zsc, distribution)

  # Factor characteristics. Strictly Bayesian descriptors only: nload is
  # derived from the posterior dominant-factor probability; eigenvals and
  # expl_var are standard factor-analysis summaries computed from the
  # posterior-mean loading matrix; cor_zsc is the Pearson correlation of
  # posterior-mean z-score columns.
  eigs  <- colSums(Lhat ^ 2)
  dom   <- compute_dominant_prob(Lambda_draws)
  nload <- tabulate(apply(dom, 1, which.max), nbins = K)

  f_char <- list(
    characteristics = data.frame(
      nload     = nload,
      eigenvals = eigs,
      expl_var  = 100 * eigs / N,
      row.names = fac_ids
    ),
    cor_zsc = cor(zsc)
  )

  # Bayesian analogue to qmethod's $flagged: flagged[i, k] is TRUE when
  # factor k is most probably the dominant one for participant i, i.e.
  # P(argmax_k |Lambda[i, k]| = k) > 0.5. The 0.5 cutoff enforces
  # uniqueness (at most one factor can clear it).
  flagged <- dom > 0.5
  dimnames(flagged) <- list(part_ids, fac_ids)

  dom_sign     <- compute_dominant_sign(Lambda_draws)
  names(dom_sign) <- part_ids
  neg_exemplar <- stats::setNames(dom_sign < 0.5, part_ids)

  # Default delta: Bayesian reliability-adjusted critical difference.
  if (is.null(delta) && K >= 2)
    delta <- critical_delta(Lambda_draws, level = 0.05, r0 = 0.80)
  qdc <- compute_qdc(F_draws, distribution, delta = delta)

  brief <- list(
    call         = call,
    date         = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    pkg_version  = tryCatch(utils::packageVersion("bayesqm"),
                            error = function(e) "unknown"),
    K            = K,
    N            = N,
    J            = J,
    family       = if (isTRUE(robust)) "Student-t" else "Gaussian",
    nu           = nu,
    chains       = chains,
    iter         = iter,
    warmup       = warmup,
    post_warmup  = chains * (iter - warmup),
    backend      = backend,
    prob         = prob,
    distribution = distribution,
    delta        = delta,
    priors       = priors
  )
  brief$info <- make_brief_info(brief, diag)

  structure(
    list(
      brief        = brief,
      dataset      = Y,
      distribution = distribution,
      loa          = Lhat,
      loa_median   = Lmed,
      ci_lower     = ci_lo,
      ci_upper     = ci_hi,
      zsc          = zsc,
      zsc_n        = zsc_n,
      f_char       = f_char,
      flagged      = flagged,
      dom_sign     = dom_sign,
      neg_exemplar = neg_exemplar,
      qdc          = qdc,
      Lambda_draws = Lambda_draws,
      F_draws      = F_draws,
      align_info   = align_info,
      hyperparams  = hyperparams,
      loo          = loo_el,
      loo_person   = loo_ps,
      diagnostics  = diag,
      ppc          = ppc
    ),
    class = "bayesqm_fit"
  )
}


#' @keywords internal
#' @noRd
new_bayesqm_run <- function(call, fits, tab, loo_list, k_peak, k_sivula, case) {
  structure(
    list(
      call     = call,
      fits     = fits,
      tab      = tab,
      loo_list = loo_list,
      k_peak   = k_peak,
      k_sivula = k_sivula,
      case     = case
    ),
    class = "bayesqm_run"
  )
}


# Rank posterior-mean factor scores onto the study's forced distribution.
#' @keywords internal
#' @noRd
rank_to_grid <- function(F_hat, distribution) {
  n_pos <- length(distribution)
  if (n_pos %% 2 == 1) {
    half <- (n_pos - 1) / 2
    grid_vals <- seq(-half, half)
  } else {
    half <- n_pos / 2
    grid_vals <- c(seq(-half, -1), seq(1, half))
  }
  forced <- rep(grid_vals, times = distribution)
  if (length(forced) != nrow(F_hat))
    stop("Distribution counts sum to ", length(forced),
         " but F_hat has ", nrow(F_hat), " statements.")

  out <- matrix(NA_real_, nrow(F_hat), ncol(F_hat),
                dimnames = dimnames(F_hat))
  for (k in seq_len(ncol(F_hat)))
    out[, k] <- forced[rank(F_hat[, k], ties.method = "first")]
  out
}


# Distinguishing / consensus table. One row per statement, in the
# layout of the manuscript supplement: for each viewpoint the
# forced-distribution grid position and the posterior factor score
# (mean) with its 95% credible interval, then the viewpoint divergence
# D_j (median and 95% CrI), pi_D = P(D_j > delta | Y), and
# pi_C = P(D_j < delta | Y). No fixed probability cutoff defines a
# distinguishing or consensus statement; the probabilities are the
# reported quantities.
#' @keywords internal
#' @noRd
compute_qdc <- function(F_draws, distribution, delta, delta_grid = NULL) {
  J <- dim(F_draws)[2]
  K <- dim(F_draws)[3]
  stmt_ids <- dimnames(F_draws)[[2]]
  if (is.null(stmt_ids)) stmt_ids <- paste0("S", seq_len(J))

  zm <- .summarize_draws(F_draws, mean)
  dimnames(zm) <- list(stmt_ids, paste0("f", seq_len(K)))
  grid <- rank_to_grid(zm, distribution)
  zsc  <- compute_zscores(F_draws, prob = 0.95)

  out <- data.frame(statement = stmt_ids, stringsAsFactors = FALSE)
  for (k in seq_len(K)) {
    fk <- paste0("f", k)
    out[[paste0(fk, "_grid")]]  <- unname(grid[, k])
    out[[paste0(fk, "_zsc")]]   <- zsc[[paste0(fk, "_zsc")]]
    out[[paste0(fk, "_lower")]] <- zsc[[paste0(fk, "_lower")]]
    out[[paste0(fk, "_upper")]] <- zsc[[paste0(fk, "_upper")]]
  }

  if (K < 2) {
    out$D_median <- NA_real_
    out$D_lower  <- NA_real_
    out$D_upper  <- NA_real_
    out$pi_D     <- NA_real_
    out$pi_C     <- NA_real_
    rownames(out) <- NULL
    attr(out, "delta") <- delta
    return(out)
  }

  dv <- compute_divergence(F_draws, delta = delta, delta_grid = delta_grid)
  out$D_median <- unname(dv$D_median)
  out$D_lower  <- unname(dv$D_lower)
  out$D_upper  <- unname(dv$D_upper)
  out$pi_D     <- unname(dv$pi_D)
  out$pi_C     <- unname(dv$pi_C)
  rownames(out) <- NULL
  attr(out, "delta") <- delta
  attr(out, "sensitivity") <- dv$sensitivity
  out
}


#' @keywords internal
#' @noRd
make_brief_info <- function(brief, diag) {
  nu_str <- if (is.character(brief$nu) && brief$nu == "estimate") "estimated"
            else as.character(brief$nu)
  family_str <- if (brief$family == "Student-t")
                  sprintf("Student-t (nu = %s)", nu_str)
                else "Gaussian"

  call_str <- paste(trimws(deparse(brief$call)), collapse = " ")
  if (nchar(call_str) > 72) call_str <- paste0(substr(call_str, 1, 69), "...")

  rhat <- diag$rhat_max
  eb   <- diag$ess_bulk
  et   <- diag$ess_tail
  ndiv <- diag$divergences

  c(
    "Bayesian Q-methodology factor model",
    sprintf("  Call:      %s", call_str),
    sprintf("  Family:    %s", family_str),
    sprintf("  Factors:   K = %d", brief$K),
    sprintf("  Data:      N = %d persons, J = %d statements", brief$N, brief$J),
    sprintf("  Draws:     %d chains x %d post-warmup = %d total",
            brief$chains, brief$iter - brief$warmup, brief$post_warmup),
    sprintf("  Backend:   %s", brief$backend),
    sprintf("  Fitted:    %s", brief$date),
    sprintf("  Max Rhat:  %s",
            if (is.null(rhat) || is.na(rhat)) "NA" else sprintf("%.3f", rhat)),
    sprintf("  Min ESS:   bulk %s / tail %s",
            if (is.null(eb) || is.na(eb)) "NA" else format(round(eb)),
            if (is.null(et) || is.na(et)) "NA" else format(round(et))),
    sprintf("  Divergent: %s",
            if (is.null(ndiv) || is.na(ndiv)) "NA" else as.character(ndiv))
  )
}


#' @keywords internal
#' @noRd
format_loa_ci <- function(med, lo, hi, digits = 2) {
  out <- matrix("", nrow(med), ncol(med),
                dimnames = list(rownames(med), colnames(med)))
  for (i in seq_len(nrow(med)))
    for (k in seq_len(ncol(med)))
      out[i, k] <- sprintf("%.*f [%.*f, %.*f]",
                           digits, med[i, k],
                           digits, lo[i, k],
                           digits, hi[i, k])
  out
}


#' Print and summary methods for bayesqm_fit and bayesqm_run
#'
#' @description
#' `print()` shows a compact, brms-style header with convergence and
#' the first few loadings. `summary()` expands with factor
#' characteristics, the PSIS-LOO estimate, the divergence summary,
#' and the MatchAlign Tucker-phi diagnostic. Both methods
#' exist for `bayesqm_fit` (returned by [fit_bayesian()]) and
#' `bayesqm_run` (returned by [run_bayes()]).
#'
#' @param x,object A `bayesqm_fit` or `bayesqm_run` object.
#' @param digits Number of digits to print.
#' @param length Maximum number of participant rows to show in the
#'   compact loading table.
#' @param ... Unused.
#'
#' @return The input, invisibly.
#'
#' @name bayesqm-fit-methods
#' @aliases print.bayesqm_fit summary.bayesqm_fit print.bayesqm_run summary.bayesqm_run
NULL

#' @rdname bayesqm-fit-methods
#' @export
print.bayesqm_fit <- function(x, digits = 2, length = 10, ...) {
  cat(x$brief$info, sep = "\n")
  cat("\n")

  n_show <- min(length, nrow(x$loa_median))
  ci_pct <- round(100 * x$brief$prob)
  cat(sprintf("Factor loadings (posterior median [%d%% CI], first %d of %d persons):\n",
              ci_pct, n_show, nrow(x$loa_median)))
  disp <- format_loa_ci(x$loa_median, x$ci_lower, x$ci_upper, digits)
  print(noquote(disp[seq_len(n_show), , drop = FALSE]))
  if (nrow(disp) > n_show)
    cat(sprintf("  ... (%d more; see fit$loa_median / fit$ci_lower / fit$ci_upper)\n",
                nrow(disp) - n_show))
  cat("\n")

  cat("Hyperparameters:\n")
  hps <- compute_posterior_scalars(x$hyperparams, prob = x$brief$prob)
  print(format(hps, digits = digits), row.names = FALSE)
  cat("\n")

  cat("Use summary() for factor characteristics, the divergence ",
      "summary, and LOO.\n", sep = "")
  invisible(x)
}


#' @rdname bayesqm-fit-methods
#' @export
summary.bayesqm_fit <- function(object, digits = 3, ...) {
  cat(object$brief$info, sep = "\n")
  cat("\n")

  cat("Factor characteristics:\n")
  fc <- object$f_char$characteristics
  fc$eigenvals <- round(fc$eigenvals, digits)
  fc$expl_var  <- round(fc$expl_var,  2)
  print(fc)
  cat("\n")

  cat("Hyperparameters (posterior summary):\n")
  hps <- compute_posterior_scalars(object$hyperparams, prob = object$brief$prob)
  print(format(hps, digits = digits), row.names = FALSE)
  cat("\n")

  if (!is.null(object$loo)) {
    elpd <- object$loo$estimates["elpd_loo", "Estimate"]
    se   <- object$loo$estimates["elpd_loo", "SE"]
    pk   <- object$loo$diagnostics$pareto_k
    pct  <- if (length(pk)) mean(pk > 0.7, na.rm = TRUE) else NA_real_
    cat(sprintf("PSIS-LOO (element-wise): ELPD = %.1f (SE %.1f); %s k > 0.7\n",
                elpd, se,
                if (is.na(pct)) "NA" else sprintf("%.1f%%", 100 * pct)))
    cat("\n")
  }

  if (!is.null(object$qdc) && nrow(object$qdc) > 0 &&
      !all(is.na(object$qdc$D_median))) {
    q <- object$qdc
    d <- object$brief$delta
    cat("Divergence summary:\n")
    cat(sprintf("  posterior median D_j ranges %.2f to %.2f\n",
                min(q$D_median), max(q$D_median)))
    if (is.null(d) || all(is.na(q$pi_D))) {
      cat("  delta not specified; supply delta for distinguishing/consensus probabilities\n")
    } else {
      cat(sprintf("  delta = %.2f (reliability-adjusted critical difference)\n", d))
      cat(sprintf("  statements with P(D_j > delta | Y) >= 0.95: %d of %d\n",
                  sum(q$pi_D >= 0.95), nrow(q)))
      cat(sprintf("  strongest consensus, max P(D_j < delta | Y): %.2f\n",
                  max(q$pi_C)))
    }
    if (!is.null(object$neg_exemplar))
      cat(sprintf("  negative exemplars, P(dominant loading > 0 | Y) < 0.5: %d of %d\n",
                  sum(object$neg_exemplar), length(object$neg_exemplar)))
    cat("\n")
  }

  align <- object$align_info$congruence
  if (!is.null(align)) {
    mean_tucker <- colMeans(align, na.rm = TRUE)
    cat("MatchAlign diagnostics (mean Tucker phi per factor):\n  ")
    cat(sprintf("%s = %.3f  ", colnames(object$loa), mean_tucker), sep = "")
    cat("\n")
  }

  invisible(object)
}


#' @rdname bayesqm-fit-methods
#' @export
print.bayesqm_run <- function(x, digits = 2, ...) {
  K_min <- min(x$tab$K); K_max <- max(x$tab$K)
  case_expl <- switch(as.character(x$case),
    "agree"    = "ELPD peak and Sivula agree",
    "gap"      = "ELPD peak > Sivula (weak discrimination between adjacent models)",
    "reversed" = "ELPD peak < Sivula (rare)",
    "no cases evaluated")

  cat("Bayesian Q-methodology: multi-K comparison\n")
  cat(sprintf("  K range:      %d..%d\n", K_min, K_max))
  cat(sprintf("  ELPD peak:    K = %s  (automated adoption)\n",
              x$k_peak %||% "NA"))
  cat(sprintf("  Sivula rule:  K = %s  (parsimony diagnostic)\n",
              x$k_sivula %||% "NA"))
  cat(sprintf("  Case:         %s  (%s)\n\n",
              x$case %||% "NA", case_expl))

  cat("LOO comparison:\n")
  disp <- x$tab
  for (col in c("elpd", "se", "delta_elpd", "se_delta", "ratio"))
    if (col %in% names(disp))
      disp[[col]] <- ifelse(is.na(disp[[col]]), "",
                            formatC(disp[[col]], format = "f", digits = digits))
  print(disp, row.names = FALSE)

  if (!is.na(x$case) && x$case == "gap")
    cat("\nCase 'gap': k_peak is adopted; Sivula is reported as a ",
        "parsimony diagnostic only.\n", sep = "")

  invisible(x)
}


#' @rdname bayesqm-fit-methods
#' @export
summary.bayesqm_run <- function(object, ...) {
  print(object)
  cat("\nFits (bayesqm_fit objects) are stored in $fits, indexed by K.\n")
  invisible(object)
}
