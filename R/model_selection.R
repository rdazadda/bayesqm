# model_selection.R
# Factor enumeration under the peak-plus-Sivula protocol. The ELPD peak is
# the automated selector; the Sivula parsimony rule is reported alongside
# as a diagnostic, and the gap between them is itself informative.


#' Fit the model across a range of K
#'
#' @description
#' Fits [fit_bayesian()] for K = 1..K_max and reports the ELPD peak
#' (automated adoption), the Sivula (2025) parsimony diagnostic, and a
#' case label (`agree`, `gap`, `reversed`) summarising their
#' relationship. When the two agree the data supports that K; when they
#' disagree the `gap` is itself a reportable finding.
#'
#' @param Y A `qsort_data` object or `J x N` numeric matrix.
#' @param K_max Largest K to try (default 5).
#' @param stan_dir Optional override of the Stan model directory.
#' @param elpd_diff_threshold,se_ratio_threshold Sivula rule thresholds
#'   (paper defaults 4 and 2).
#' @param ... Passed to [fit_bayesian()].
#' @param elpds,loo_list,K_candidates Internal inputs for
#'   `select_k_peak()` and `select_k_sivula()`.
#'
#' @return `run_bayes()` returns a `bayesqm_run` object carrying the
#'   list of fits, the ELPD comparison table, and the peak / Sivula /
#'   case verdict. `select_k_peak()` and `select_k_sivula()` return an
#'   integer K.
#'
#' @name run_bayes
#' @aliases select_k_peak select_k_sivula
#' @export
run_bayes <- function(Y, K_max = 5, stan_dir = NULL,
                      elpd_diff_threshold = 4, se_ratio_threshold = 2, ...) {
  cl <- match.call()
  if (!is.numeric(K_max) || length(K_max) != 1L || K_max < 1L)
    stop("K_max must be a positive integer.")
  K_max <- as.integer(K_max)
  if (inherits(Y, "qsort_data")) Y <- Y$Y
  fits <- vector("list", K_max)
  loo_list <- vector("list", K_max)
  for (k in seq_len(K_max)) {
    fits[[k]] <- tryCatch(
      fit_bayesian(Y, K = k, stan_dir = stan_dir, ...),
      error = function(e) NULL)
    if (!is.null(fits[[k]]$loo)) loo_list[[k]] <- fits[[k]]$loo
  }

  tab <- data.frame(K = seq_len(K_max),
                    elpd = NA_real_, se = NA_real_,
                    delta_elpd = NA_real_, se_delta = NA_real_,
                    ratio = NA_real_)
  for (k in seq_len(K_max)) {
    if (!is.null(fits[[k]]$loo)) {
      tab$elpd[k] <- fits[[k]]$loo$estimates["elpd_loo", "Estimate"]
      tab$se[k]   <- fits[[k]]$loo$estimates["elpd_loo", "SE"]
    }
  }

  # Sequential delta: delta_elpd[k] = elpd[k-1] - elpd[k]; negative values
  # favor the larger K. SE(delta) comes from loo::loo_compare on the pair.
  if (K_max >= 2) {
    for (k in seq.int(2L, K_max)) {
      if (is.null(loo_list[[k - 1]]) || is.null(loo_list[[k]])) next
      comp <- tryCatch(
        loo::loo_compare(list(loo_list[[k - 1]], loo_list[[k]])),
        error = function(e) NULL)
      if (!is.null(comp) && nrow(comp) >= 2) {
        tab$delta_elpd[k] <- tab$elpd[k - 1] - tab$elpd[k]
        tab$se_delta[k]   <- abs(comp[2, "se_diff"])
        if (tab$se_delta[k] > 0)
          tab$ratio[k] <- abs(tab$delta_elpd[k]) / tab$se_delta[k]
      }
    }
  }

  k_peak   <- select_k_peak(tab$elpd, seq_len(K_max))
  k_sivula <- select_k_sivula(tab$elpd, loo_list, seq_len(K_max),
                              elpd_diff_threshold = elpd_diff_threshold,
                              se_ratio_threshold  = se_ratio_threshold)

  case <- if (is.na(k_peak) || is.na(k_sivula)) NA_character_
          else if (k_peak == k_sivula) "agree"
          else if (k_peak >  k_sivula) "gap"
          else                          "reversed"

  new_bayesqm_run(call = cl, fits = fits, tab = tab, loo_list = loo_list,
                  k_peak = k_peak, k_sivula = k_sivula, case = case)
}


#' @rdname run_bayes
#' @export
select_k_peak <- function(elpds, K_candidates) {
  valid <- which(!is.na(elpds))
  if (length(valid) == 0) return(NA_integer_)
  K_candidates[valid[which.max(elpds[valid])]]
}


# Sivula et al. (2025) parsimony diagnostic: starting from the simplest
# candidate, advance to a larger K only if the ELPD difference exceeds
# elpd_diff_threshold AND the |diff| / SE ratio exceeds se_ratio_threshold.
# Paper defaults: 4 and 2.
#' @rdname run_bayes
#' @export
select_k_sivula <- function(elpds, loo_list, K_candidates,
                            elpd_diff_threshold = 4,
                            se_ratio_threshold  = 2) {
  valid <- which(!is.na(elpds))
  if (length(valid) == 0) return(NA_integer_)
  if (length(valid) == 1) return(K_candidates[valid])

  best_idx <- valid[1]
  for (j in valid[-1]) {
    d <- elpds[j] - elpds[best_idx]
    if (d > 0) {
      if (!is.null(loo_list[[best_idx]]) && !is.null(loo_list[[j]])) {
        comp <- tryCatch(
          loo::loo_compare(list(loo_list[[best_idx]], loo_list[[j]])),
          error = function(e) NULL)
        if (!is.null(comp) && nrow(comp) >= 2) {
          se_d <- abs(comp[2, "se_diff"])
          if (se_d > 0) {
            ratio <- abs(comp[2, "elpd_diff"]) / se_d
            if (abs(comp[2, "elpd_diff"]) > elpd_diff_threshold &&
                ratio > se_ratio_threshold) best_idx <- j
          } else if (d > elpd_diff_threshold) best_idx <- j
        } else if (d > elpd_diff_threshold) best_idx <- j
      } else if (d > elpd_diff_threshold) best_idx <- j
    }
  }
  K_candidates[best_idx]
}
