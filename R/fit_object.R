# fit_object.R
# The bayesqm_fit S3 class for the partition model: constructor, print,
# summary. The fit carries aligned draws, the raw draws (for realignment),
# the sampler state (for extend()), the gate report, and the alignment
# record; tables are computed from it by the compute_* functions.


#' @keywords internal
#' @noRd
new_bayesqm_fit <- function(call, Y, distribution, K, draws, draws_raw,
                            state, gate, align, prob, seed, settings,
                            fac_ids = NULL) {
  N <- ncol(Y); J <- nrow(Y)
  stmt_ids <- rownames(Y); if (is.null(stmt_ids)) stmt_ids <- paste0("S", seq_len(J))
  part_ids <- colnames(Y); if (is.null(part_ids)) part_ids <- paste0("P", seq_len(N))
  if (is.null(fac_ids)) fac_ids <- paste0("f", seq_len(K))

  name_draws <- function(d) {
    dimnames(d$F) <- list(NULL, stmt_ids, fac_ids)
    dimnames(d$Lambda) <- list(NULL, part_ids, fac_ids)
    dimnames(d$sigma) <- list(NULL, fac_ids)
    dimnames(d$s_i) <- list(NULL, part_ids)
    d
  }
  draws <- name_draws(draws)
  if (!is.null(draws_raw)) draws_raw <- name_draws(draws_raw)

  brief <- list(
    call         = call,
    date         = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    pkg_version  = tryCatch(utils::packageVersion("bayesqm"),
                            error = function(e) "unknown"),
    model        = "exact partition (rank-order) likelihood, PX-Gibbs",
    K            = K,
    N            = N,
    J            = J,
    prob         = prob,
    seed         = seed,
    distribution = distribution,
    settings     = settings
  )

  structure(
    list(
      brief        = brief,
      dataset      = Y,
      distribution = distribution,
      draws        = draws,
      draws_raw    = draws_raw,
      state        = state,
      gate         = gate,
      align        = align
    ),
    class = "bayesqm_fit"
  )
}


# bounded loadings rho_ik = (S lambda_i)_k / sqrt(s_i^2 + 1), per draw; a
# deterministic transform of the aligned draws, computed on demand
#' @keywords internal
#' @noRd
.rho_draws <- function(fit) {
  d <- fit$draws
  T_ <- dim(d$F)[1]; J <- fit$brief$J; K <- fit$brief$K; N <- fit$brief$N
  rho <- array(NA_real_, c(T_, N, K), dimnames = dimnames(d$Lambda))
  for (t in seq_len(T_)) {
    F <- matrix(d$F[t, , ], J, K); L <- matrix(d$Lambda[t, , ], N, K)
    S <- crossprod(sweep(F, 2, colMeans(F))) / J
    q <- L %*% S
    rho[t, , ] <- q / sqrt(pmax(rowSums(q * L), 0) + 1)
  }
  rho
}


#' @export
print.bayesqm_fit <- function(x, ...) {
  b <- x$brief; g <- x$gate
  cat("bayesqm fit: ", b$model, "\n", sep = "")
  cat(sprintf("  %d participants, %d statements, %d factor%s; grid %s\n",
              b$N, b$J, b$K, if (b$K > 1) "s" else "",
              paste(b$distribution, collapse = "-")))
  cat(sprintf("  draws: %d kept (%d iterations, burn %d, thin %d%s)\n",
              dim(x$draws$F)[1], g$iterations, b$settings$burn,
              b$settings$thin,
              if (isTRUE(g$extended)) ", warm-extended" else ""))
  gate_line <- sprintf("max Rhat %.3f; min ESS %.0f bulk / %.0f tail",
                       g$rhat, g$ess_bulk, g$ess_tail)
  if (isTRUE(g$converged)) {
    cat("  gate: passed (", gate_line, ")\n", sep = "")
  } else {
    cat("  gate: NOT MET (", gate_line, ") - see extend()\n", sep = "")
  }
  cat(sprintf("  alignment: pivot draw %d, mean congruence %.2f\n",
              x$align$pivot, mean(x$align$congruence)))
  cat("  tables: compute_loadings(), compute_flags(), compute_factor_array(),\n",
      "          compute_qdc(), claims()\n", sep = "")
  invisible(x)
}


#' @export
summary.bayesqm_fit <- function(object, prob = NULL, ...) {
  print(object)
  prob <- if (is.null(prob)) object$brief$prob else prob
  rho <- .rho_draws(object)
  alpha <- 1 - prob
  m <- .summarize_draws(rho, mean)
  lo <- .summarize_draws(rho, quantile, probs = alpha / 2, names = FALSE)
  hi <- .summarize_draws(rho, quantile, probs = 1 - alpha / 2, names = FALSE)
  cat(sprintf("\nBounded loadings (posterior mean, %d%% interval), first %d participants:\n",
              round(100 * prob), min(object$brief$N, 8)))
  show <- seq_len(min(object$brief$N, 8))
  for (i in show) {
    entries <- sprintf("%s % .2f [% .2f, % .2f]",
                       colnames(m), m[i, ], lo[i, ], hi[i, ])
    cat(sprintf("  %-10s %s\n", rownames(m)[i], paste(entries, collapse = "  ")))
  }
  if (object$brief$N > 8)
    cat(sprintf("  ... %d more; compute_loadings() for the full table\n",
                object$brief$N - 8))
  invisible(object)
}
