# rename_factors.R
# Relabels every factor-indexed slot on a bayesqm_fit in a single call.


#' Rename factors consistently across a bayesqm_fit
#'
#' @description
#' Replaces the default `f1..fK` factor labels everywhere they appear on
#' the fit: posterior-mean and credible-interval loading matrices, the
#' factor-score matrices, the factor-characteristics table, the
#' correlation matrix, the flagged matrix, the distinguishing /
#' consensus table column names, and the factor dimension of the raw
#' `Lambda_draws` / `F_draws` arrays.
#'
#' @param fit A `bayesqm_fit` object.
#' @param new_names Character vector of length `K` with the new factor
#'   labels.
#'
#' @return The input fit with every factor label replaced.
#'
#' @examples
#' \dontrun{
#' fit <- fit_bayesian(Y, K = 3)
#' fit <- rename_factors(fit, c("tradition", "innovation", "caution"))
#' }
#'
#' @export
rename_factors <- function(fit, new_names) {
  assert_bayesqm_fit(fit)
  K <- fit$brief$K
  if (length(new_names) != K)
    stop("new_names must have length K = ", K, ".")
  new_names <- as.character(new_names)
  if (anyDuplicated(new_names))
    stop("new_names must be unique.")

  old_names <- colnames(fit$loa)
  if (is.null(old_names)) old_names <- paste0("f", seq_len(K))

  # N x K and J x K matrices share the factor dimension along columns.
  for (slot in c("loa", "loa_median", "ci_lower", "ci_upper",
                 "zsc", "zsc_n", "flagged")) {
    if (!is.null(fit[[slot]])) colnames(fit[[slot]]) <- new_names
  }

  # f_char: rename rownames of characteristics and both dims of cor_zsc.
  if (!is.null(fit$f_char)) {
    if (!is.null(fit$f_char$characteristics))
      rownames(fit$f_char$characteristics) <- new_names
    if (!is.null(fit$f_char$cor_zsc))
      dimnames(fit$f_char$cor_zsc) <- list(new_names, new_names)
  }

  # qdc has per-viewpoint columns "f{k}_grid", "f{k}_zsc", "f{k}_lower",
  # "f{k}_upper". Underscore is a regex word character so \b doesn't
  # fence it; match the factor name between start/underscore and
  # underscore/end.
  if (!is.null(fit$qdc) && ncol(fit$qdc) > 2) {
    nm <- names(fit$qdc)
    for (k in seq_len(K))
      nm <- gsub(paste0("(^|_)", old_names[k], "(?=_|$)"),
                 paste0("\\1", new_names[k]),
                 nm, perl = TRUE)
    names(fit$qdc) <- nm
  }

  # Raw draws keep their factor dimension in position 3.
  for (slot in c("Lambda_draws", "F_draws")) {
    if (!is.null(fit[[slot]])) {
      dn <- dimnames(fit[[slot]])
      if (is.null(dn)) dn <- list(NULL, NULL, NULL)
      dn[[3]] <- new_names
      dimnames(fit[[slot]]) <- dn
    }
  }

  if (!is.null(fit$align_info) && !is.null(fit$align_info$congruence))
    colnames(fit$align_info$congruence) <- new_names

  fit
}
