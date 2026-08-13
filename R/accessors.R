# accessors.R
# Standard R accessors and draws-ecosystem bridges for the bayesqm_fit.
# Parameter names in the flat draw representation follow the Stan-style
# convention: Lambda[i,k], F[j,k], sigma[k], s_i[i].


# flatten the aligned draw arrays into a T x P matrix with bracketed names
#' @keywords internal
#' @noRd
flatten_draws_to_matrix <- function(fit) {
  d <- fit$draws
  T_ <- dim(d$F)[1]
  N <- fit$brief$N; J <- fit$brief$J; K <- fit$brief$K
  cols <- c(
    outer(seq_len(N), seq_len(K), function(i, k) sprintf("Lambda[%d,%d]", i, k)),
    outer(seq_len(J), seq_len(K), function(j, k) sprintf("F[%d,%d]", j, k)),
    sprintf("sigma[%d]", seq_len(K)),
    sprintf("s_i[%d]", seq_len(N))
  )
  m <- cbind(matrix(d$Lambda, T_, N * K),
             matrix(d$F, T_, J * K),
             matrix(d$sigma, T_, K),
             matrix(d$s_i, T_, N))
  colnames(m) <- cols
  m
}


#' Posterior-mean bounded loadings
#'
#' @param object A `bayesqm_fit`.
#' @param ... Unused.
#' @return An `N x K` matrix of posterior-mean bounded loadings (the
#'   correlation-scale loading of the accompanying paper).
#' @export
coef.bayesqm_fit <- function(object, ...) {
  .summarize_draws(.rho_draws(object), mean)
}

#' Posterior-mean reconstruction on the utility scale
#'
#' @param object A `bayesqm_fit`.
#' @param ... Unused.
#' @return A `J x N` matrix of posterior-mean latent utilities
#'   `F Lambda'`.
#' @export
fitted.bayesqm_fit <- function(object, ...) {
  Fm <- .summarize_draws(object$draws$F, mean)
  Lm <- .summarize_draws(object$draws$Lambda, mean)
  out <- Fm %*% t(Lm)
  dimnames(out) <- dimnames(object$dataset)
  out
}

#' @export
residuals.bayesqm_fit <- function(object, ...) {
  .bq_abort(paste0(
    "a rank likelihood has no residual scale: the data are the ordering ",
    "events themselves. Use check_fit() for posterior-predictive checks."))
}

#' @export
nobs.bayesqm_fit <- function(object, ...) object$brief$N

#' Posterior-mean loading scales
#'
#' @param object A `bayesqm_fit`.
#' @param ... Unused.
#' @return Named numeric vector of posterior-mean `sigma_k`.
#' @export
sigma.bayesqm_fit <- function(object, ...) {
  out <- colMeans(object$draws$sigma)
  names(out) <- dimnames(object$draws$sigma)[[2]]
  out
}

#' @export
family.bayesqm_fit <- function(object, ...) {
  structure(list(family = "exact partition (rank-order) likelihood",
                 link = "latent Gaussian utilities"),
            class = "bayesqm_family")
}

#' @export
print.bayesqm_family <- function(x, ...) {
  cat("Family:", x$family, "\n")
  cat("Link:  ", x$link, "\n")
  invisible(x)
}

#' @export
as.matrix.bayesqm_fit <- function(x, ...) flatten_draws_to_matrix(x)

#' @export
as.array.bayesqm_fit <- function(x, ...) {
  m <- flatten_draws_to_matrix(x)
  array(m, c(nrow(m), 1L, ncol(m)),
        dimnames = list(NULL, NULL, colnames(m)))
}

#' @export
as.data.frame.bayesqm_fit <- function(x, ...) {
  as.data.frame(flatten_draws_to_matrix(x))
}

#' @export
update.bayesqm_fit <- function(object, ...) {
  cl <- object$brief$call
  # the fit carries its data, so refitting never depends on the original
  # data object still existing in the caller's session
  cl$Y <- qsort_data(object$dataset, distribution = object$distribution,
                     validate = FALSE)
  new_args <- list(...)
  for (nm in names(new_args)) cl[[nm]] <- new_args[[nm]]
  eval(cl, parent.frame())
}


#' Posterior interval generic
#'
#' @description
#' Generic for posterior credible intervals, defined here so the package
#' needs no Stan-ecosystem dependency. Compatible with the generic of the
#' same name in \pkg{rstantools}.
#'
#' @param object A fitted model object.
#' @param ... Passed to methods.
#'
#' @return See the method documentation.
#' @export
posterior_interval <- function(object, ...) UseMethod("posterior_interval")

#' Credible intervals for bayesqm_fit parameters
#'
#' @description
#' Posterior credible intervals for any subset of parameters in a
#' `bayesqm_fit`. Method for [posterior_interval()].
#'
#' @param object A `bayesqm_fit`.
#' @param prob Coverage probability (default 0.95).
#' @param pars Optional character vector of exact parameter names.
#' @param regex_pars Optional regex; matching parameter names are included
#'   in addition to those named in `pars`.
#' @param ... Unused.
#'
#' @return A matrix with one row per parameter and two columns for the
#'   lower and upper interval bounds.
#'
#' @method posterior_interval bayesqm_fit
#' @export
posterior_interval.bayesqm_fit <- function(object, prob = 0.95,
                                           pars = NULL, regex_pars = NULL,
                                           ...) {
  m <- flatten_draws_to_matrix(object)
  if (!is.null(pars) || !is.null(regex_pars)) {
    keep <- logical(ncol(m))
    if (!is.null(pars))       keep <- keep | (colnames(m) %in% pars)
    if (!is.null(regex_pars)) keep <- keep | grepl(regex_pars, colnames(m))
    if (!any(keep)) .bq_abort("no parameters matched pars / regex_pars.")
    m <- m[, keep, drop = FALSE]
  }
  alpha <- 1 - prob
  out <- t(apply(m, 2, quantile, probs = c(alpha / 2, 1 - alpha / 2),
                 names = FALSE, na.rm = TRUE))
  colnames(out) <- sprintf("%.1f%%", 100 * c(alpha / 2, 1 - alpha / 2))
  out
}


#' Prior summary generic
#'
#' @description
#' Generic for summarizing the priors a model was fit with, defined here so
#' the package needs no Stan-ecosystem dependency. Compatible with the
#' generic of the same name in \pkg{rstantools}.
#'
#' @param object A fitted model object.
#' @param ... Passed to methods.
#'
#' @return See the method documentation.
#' @export
prior_summary <- function(object, ...) UseMethod("prior_summary")

#' Prior summary for a bayesqm_fit
#'
#' @description
#' The partition model's priors, as a printable `bayesqm_prior` object.
#' Method for [prior_summary()].
#'
#' @param object A `bayesqm_fit`.
#' @param ... Unused.
#'
#' @return A `bayesqm_prior` data frame with columns `parameter` and
#'   `prior`.
#'
#' @method prior_summary bayesqm_fit
#' @export
prior_summary.bayesqm_fit <- function(object, ...) {
  sc <- object$brief$settings$sigma_scale
  out <- data.frame(
    parameter = c("f_jk (statement scores)",
                  "lambda_ik (loadings)",
                  "sigma_k (loading scales)"),
    prior = c("Normal(0, 1), column conventions applied to draws",
              "Normal(0, sigma_k^2)",
              sprintf("half-Normal(0, %g)", sc)),
    stringsAsFactors = FALSE
  )
  class(out) <- c("bayesqm_prior", "data.frame")
  out
}

#' @export
print.bayesqm_prior <- function(x, ...) {
  cat("Priors of the partition model:\n")
  for (r in seq_len(nrow(x)))
    cat(sprintf("  %-26s %s\n", x$parameter[r], x$prior[r]))
  invisible(x)
}


# posterior-package bridge; registered in .onLoad when posterior is present
#' @keywords internal
#' @noRd
as_draws.bayesqm_fit <- function(x, ...) {
  posterior::as_draws_matrix(flatten_draws_to_matrix(x))
}

#' @keywords internal
#' @noRd
as_draws_df.bayesqm_fit <- function(x, ...) {
  posterior::as_draws_df(flatten_draws_to_matrix(x))
}

#' @keywords internal
#' @noRd
as_draws_matrix.bayesqm_fit <- function(x, ...) {
  posterior::as_draws_matrix(flatten_draws_to_matrix(x))
}

#' @keywords internal
#' @noRd
as_draws_array.bayesqm_fit <- function(x, ...) {
  posterior::as_draws_array(as.array(x))
}

#' @keywords internal
#' @noRd
as_draws_rvars.bayesqm_fit <- function(x, ...) {
  posterior::as_draws_rvars(as_draws_df.bayesqm_fit(x))
}

#' @keywords internal
#' @noRd
as_draws_list.bayesqm_fit <- function(x, ...) {
  posterior::as_draws_list(as_draws_df.bayesqm_fit(x))
}

#' @keywords internal
#' @noRd
ndraws.bayesqm_fit <- function(x, ...) dim(x$draws$F)[1]
