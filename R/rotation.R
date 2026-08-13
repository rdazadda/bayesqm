# rotation.R
# Judgmental rotation and factor bookkeeping. Orientation after alignment
# is a reporting choice, as rotation is in classical Q: every aligned draw
# receives the same analyst-specified rotation, so posterior uncertainty
# propagates through the rotated summaries.


#' Rotate every aligned draw toward a target
#'
#' @description
#' Judgmental rotation: each aligned draw's statement scores are rotated
#' toward an analyst-specified target by Procrustes, and the loadings
#' receive the same rotation (its inverse transpose when `oblique = TRUE`),
#' so the latent utilities every draw implies are unchanged. Summaries
#' computed from the returned fit are summaries of the rotated solution,
#' with full posterior uncertainty.
#'
#' @param fit A `bayesqm_fit`.
#' @param target A `J x K` numeric matrix of target scores (for example, a
#'   hand-edited copy of the posterior-mean scores).
#' @param oblique Allow an oblique (non-orthogonal) rotation
#'   (default `FALSE`).
#'
#' @return The fit with rotated draws; `fit$align$rotated` records the
#'   call.
#'
#' @export
rotate_factors <- function(fit, target, oblique = FALSE) {
  assert_bayesqm_fit(fit)
  target <- as.matrix(target)
  J <- fit$brief$J; K <- fit$brief$K
  if (!all(dim(target) == c(J, K)))
    .bq_abort("target must be a %d x %d matrix of statement scores.", J, K)
  d <- fit$draws
  T_ <- dim(d$F)[1]
  for (t in seq_len(T_)) {
    F <- matrix(d$F[t, , ], J, K)
    L <- matrix(d$Lambda[t, , ], fit$brief$N, K)
    if (oblique) {
      R <- solve(crossprod(F), crossprod(F, target))
      Li <- L %*% t(solve(R))
    } else {
      sv <- svd(crossprod(F, target))
      R <- sv$u %*% t(sv$v)
      Li <- L %*% R
    }
    d$F[t, , ] <- F %*% R
    d$Lambda[t, , ] <- Li
    d$sigma[t, ] <- rotate_sigma(fit$draws$sigma[t, ], R)
  }
  fit$draws <- d
  fit$align$rotated <- if (oblique) "oblique target" else "orthogonal target"
  fit
}


#' Flip the pole of one factor
#'
#' @description
#' Reverses the sign of one factor's scores and loadings in every draw.
#' The polarity canon orients factors so defining sorts load positively;
#' this is the judgmental override.
#'
#' @param fit A `bayesqm_fit`.
#' @param factor Factor index or `"f2"`-style name.
#'
#' @return The fit with the factor's pole reversed.
#'
#' @export
flip_factor <- function(fit, factor) {
  assert_bayesqm_fit(fit)
  fac_ids <- dimnames(fit$draws$sigma)[[2]]
  k <- if (is.character(factor)) match(factor, fac_ids) else as.integer(factor)
  if (is.na(k) || k < 1 || k > fit$brief$K) .bq_abort("no such factor.")
  fit$draws$F[, , k] <- -fit$draws$F[, , k]
  fit$draws$Lambda[, , k] <- -fit$draws$Lambda[, , k]
  fit
}


#' Rename the factors
#'
#' @description
#' Replaces the `f1 ... fK` labels with substantive names everywhere the
#' fit carries them, so every downstream table and plot uses the new
#' names.
#'
#' @param fit A `bayesqm_fit`.
#' @param new_names Character vector of length `K`.
#'
#' @return The renamed fit.
#'
#' @export
rename_factors <- function(fit, new_names) {
  assert_bayesqm_fit(fit)
  K <- fit$brief$K
  if (length(new_names) != K || anyDuplicated(new_names))
    .bq_abort("new_names must be %d distinct names.", K)
  new_names <- as.character(new_names)
  relabel <- function(d) {
    if (is.null(d)) return(NULL)
    dimnames(d$F)[[3]] <- new_names
    dimnames(d$Lambda)[[3]] <- new_names
    dimnames(d$sigma)[[2]] <- new_names
    d
  }
  fit$draws <- relabel(fit$draws)
  fit$draws_raw <- relabel(fit$draws_raw)
  fit
}
