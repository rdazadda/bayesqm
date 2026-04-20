# fit_object.R
# The bayesqm_fit and bayesqm_run S3 classes: constructors that assemble
# qmethod-parallel slots ($brief, $loa, $zsc, $zsc_n, $f_char, $qdc) on
# top of the raw Bayesian quantities, plus the print and summary methods
# that shape the first impression users get at the console.


#' @keywords internal
#' @noRd
new_bayesqm_fit <- function(call, Y, K, distribution, prob, robust, nu,
                            chains, iter, warmup, backend, priors,
                            Lhat, Lmed, ci_lo, ci_hi,
                            Lambda_draws, F_draws, align_info, hyperparams,
                            loo_el, loo_ps, diag, ppc) {
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

  zsc <- apply(F_draws, c(2, 3), mean)
  dim(zsc) <- dim(F_draws)[2:3]
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

  qdc <- compute_qdc(F_draws, delta = 1.0, threshold = 0.95)

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


# Distinguishing / consensus table. A factor k is "distinguished" at
# statement j when every pair involving k clears the probability threshold.
# The dist.and.cons label is "Distinguishes all" (every factor), "Consensus"
# (every pair falls below 1 - threshold), or "Distinguishes f1, f3..." (the
# subset of factors that stand apart from all others); "" otherwise.
#' @keywords internal
#' @noRd
compute_qdc <- function(F_draws, delta = 1.0, threshold = 0.95) {
  J <- dim(F_draws)[2]
  K <- dim(F_draws)[3]
  stmt_ids <- dimnames(F_draws)[[2]]
  if (is.null(stmt_ids)) stmt_ids <- paste0("S", seq_len(J))
  if (K < 2)
    return(data.frame(statement = stmt_ids,
                      dist.and.cons = NA_character_,
                      stringsAsFactors = FALSE))

  Td <- dim(F_draws)[1]
  F_hat <- apply(F_draws, c(2, 3), mean)
  dim(F_hat) <- dim(F_draws)[2:3]
  pairs <- combn(K, 2)
  n_pairs <- ncol(pairs)

  diffs <- probs <- matrix(0, J, n_pairs)
  pair_names <- character(n_pairs)
  for (p in seq_len(n_pairs)) {
    k <- pairs[1, p]; ell <- pairs[2, p]
    pair_names[p] <- paste0("f", k, "_f", ell)
    diffs[, p] <- F_hat[, k] - F_hat[, ell]
    dif <- matrix(F_draws[, , k] - F_draws[, , ell], nrow = Td, ncol = J)
    probs[, p] <- colMeans(abs(dif) > delta)
  }

  per_factor_dist <- matrix(FALSE, J, K)
  for (k in seq_len(K)) {
    k_pairs <- which(pairs[1, ] == k | pairs[2, ] == k)
    per_factor_dist[, k] <- apply(probs[, k_pairs, drop = FALSE], 1,
                                  function(row) all(row >= threshold))
  }

  label <- vapply(seq_len(J), function(j) {
    dist_fac <- which(per_factor_dist[j, ])
    if (length(dist_fac) == K)
      "Distinguishes all"
    else if (length(dist_fac) > 0)
      paste0("Distinguishes ", paste0("f", dist_fac, collapse = ", "))
    else if (all(probs[j, ] <= 1 - threshold))
      "Consensus"
    else
      ""
  }, character(1))

  out <- data.frame(statement = stmt_ids, dist.and.cons = label,
                    stringsAsFactors = FALSE)
  for (p in seq_len(n_pairs)) {
    out[[paste0(pair_names[p], "_diff")]] <- diffs[, p]
    out[[paste0(pair_names[p], "_prob")]] <- probs[, p]
  }
  rownames(out) <- NULL
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
#' characteristics, the PSIS-LOO estimate, the distinguishing/consensus
#' count, and the MatchAlign Tucker-phi diagnostic. Both methods
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

  cat("Use summary() for factor characteristics, distinguishing/consensus ",
      "tables, and LOO.\n", sep = "")
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

  if (!is.null(object$qdc$dist.and.cons)) {
    tab <- table(object$qdc$dist.and.cons)
    if (length(tab) > 0) {
      cat("Distinguishing / consensus statements (delta = 1.0, p > 0.95):\n")
      for (nm in names(tab))
        if (nchar(nm) > 0)
          cat(sprintf("  %-24s %d\n", nm, tab[[nm]]))
      cat("\n")
    }
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
    cat("\nCase 'gap': adopt k_peak if corroborated by external evidence, ",
        "else fall back to k_sivula for parsimony.\n", sep = "")

  invisible(x)
}


#' @rdname bayesqm-fit-methods
#' @export
summary.bayesqm_run <- function(object, ...) {
  print(object)
  cat("\nFits (bayesqm_fit objects) are stored in $fits, indexed by K.\n")
  invisible(object)
}
