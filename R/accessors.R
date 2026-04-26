# accessors.R
# Standard R accessor methods for bayesqm_fit: coef, fitted, residuals,
# nobs, sigma, family, as.matrix, as.array, as.data.frame, update, plus
# posterior_interval() and prior_summary() methods for the rstantools
# generics (imported to avoid shadowing). Methods that depend on optional
# packages (loo, posterior) are registered conditionally in zzz.R's
# .onLoad().


#' Standard R accessors for bayesqm_fit
#'
#' @description
#' S3 methods that make a `bayesqm_fit` behave like a standard R
#' modelling object: `coef()` returns the posterior-mean loadings,
#' `fitted()` the posterior-mean fitted Y on the original Q-sort scale,
#' `residuals()` is `Y - fitted(fit)`, `sigma()` is the posterior-mean
#' residual scale, `nobs()` is the number of participants, and
#' `family()` returns a small `bayesqm_family` list with `$family`,
#' `$link`, and `$nu`. `as.matrix()`, `as.array()`, and `as.data.frame()`
#' return the posterior draws in Stan-style parameter naming
#' (`Lambda[i,k]`, `F[j,k]`, `nu`, `sigma`, `tau`), which the
#' \pkg{posterior}, \pkg{bayesplot}, and \pkg{tidybayes} packages
#' consume natively.
#'
#' `update()` re-fits the model with modified arguments; the original
#' call and stored data are reused.
#'
#' @param object,x A `bayesqm_fit` object.
#' @param row.names,optional Passed to `as.data.frame()`.
#' @param evaluate If `FALSE`, `update()` returns the modified call
#'   without evaluating it.
#' @param ... Further arguments (e.g. arguments for `update()`).
#'
#' @return Depends on the method; see Description.
#'
#' @name bayesqm-fit-accessors
NULL

#' @rdname bayesqm-fit-accessors
#' @export
coef.bayesqm_fit <- function(object, ...) object$loa


#' @rdname bayesqm-fit-accessors
#' @export
fitted.bayesqm_fit <- function(object, ...) {
  # Posterior-mean mu on the standardized scale (zsc %*% t(loa)), then
  # un-standardized to the original Q-sort scale per participant column.
  mu_std <- object$zsc %*% t(object$loa)
  col_mn <- colMeans(object$dataset, na.rm = TRUE)
  col_sd <- apply(object$dataset, 2, sd, na.rm = TRUE)
  out <- sweep(mu_std, 2, col_sd, "*")
  out <- sweep(out, 2, col_mn, "+")
  dimnames(out) <- dimnames(object$dataset)
  out
}


#' @rdname bayesqm-fit-accessors
#' @export
residuals.bayesqm_fit <- function(object, ...) {
  object$dataset - fitted.bayesqm_fit(object)
}


#' @rdname bayesqm-fit-accessors
#' @export
nobs.bayesqm_fit <- function(object, ...) object$brief$N


# sigma is the Student-t scale (not SD): for nu > 2 the marginal SD is
# sigma * sqrt(nu / (nu - 2)).
#' @rdname bayesqm-fit-accessors
#' @export
sigma.bayesqm_fit <- function(object, ...) {
  s <- object$hyperparams$sigma
  if (is.null(s) || all(is.na(s))) NA_real_ else mean(s, na.rm = TRUE)
}


#' @rdname bayesqm-fit-accessors
#' @export
family.bayesqm_fit <- function(object, ...) {
  fam <- list(family = object$brief$family, link = "identity")
  if (object$brief$family == "Student-t") fam$nu <- object$brief$nu
  class(fam) <- "bayesqm_family"
  fam
}


#' @rdname bayesqm-fit-accessors
#' @export
print.bayesqm_family <- function(x, ...) {
  cat(sprintf("Family: %s\n", x$family))
  cat(sprintf("Link:   %s\n", x$link))
  if (!is.null(x$nu)) {
    nu_str <- if (is.character(x$nu) && x$nu == "estimate") "estimated"
              else format(x$nu)
    cat(sprintf("nu:     %s\n", nu_str))
  }
  invisible(x)
}


# as.matrix(fit) returns a T x P draws matrix with Stan-style column names
# (Lambda[i,k], F[j,k], nu, sigma, tau). Chains are merged during MatchAlign
# post-processing, so the "chain" dimension of as.array(fit) is synthetic:
# trace plots work, but convergence diagnostics should be read from
# fit$diagnostics (which was computed before chain merging).
#' @rdname bayesqm-fit-accessors
#' @export
as.matrix.bayesqm_fit <- function(x, ...) flatten_draws_to_matrix(x)


#' @rdname bayesqm-fit-accessors
#' @export
as.array.bayesqm_fit <- function(x, ...) {
  m <- as.matrix.bayesqm_fit(x)
  array(m, dim = c(nrow(m), 1L, ncol(m)),
        dimnames = list(iteration = NULL, chain = "1", variable = colnames(m)))
}


#' @rdname bayesqm-fit-accessors
#' @export
as.data.frame.bayesqm_fit <- function(x, row.names = NULL, optional = FALSE, ...) {
  as.data.frame(as.matrix.bayesqm_fit(x), row.names = row.names,
                optional = optional)
}


#' @keywords internal
#' @noRd
flatten_draws_to_matrix <- function(x) {
  Td <- dim(x$Lambda_draws)[1]
  N  <- dim(x$Lambda_draws)[2]
  K  <- dim(x$Lambda_draws)[3]
  J  <- dim(x$F_draws)[2]

  L <- matrix(x$Lambda_draws, Td, N * K)
  colnames(L) <- paste0("Lambda[",
                        rep(seq_len(N), K), ",",
                        rep(seq_len(K), each = N), "]")

  Fm <- matrix(x$F_draws, Td, J * K)
  colnames(Fm) <- paste0("F[",
                         rep(seq_len(J), K), ",",
                         rep(seq_len(K), each = J), "]")

  scalars <- cbind(nu    = x$hyperparams$nu,
                   sigma = x$hyperparams$sigma,
                   tau   = x$hyperparams$tau)

  out <- cbind(L, Fm, scalars)
  # Drop columns that are entirely NA (e.g. nu when fix_nu was used and
  # the backend didn't emit the parameter).
  all_na <- vapply(seq_len(ncol(out)),
                   function(j) all(is.na(out[, j])), logical(1))
  out[, !all_na, drop = FALSE]
}


#' @rdname bayesqm-fit-accessors
#' @export
update.bayesqm_fit <- function(object, ..., evaluate = TRUE) {
  cl <- object$brief$call
  new_args <- list(...)
  for (nm in names(new_args))
    cl[[nm]] <- new_args[[nm]]
  # Replace Y in the call with a bare symbol; the new fit's recorded call
  # will read `fit_bayesian(Y = Y, ...)` instead of embedding the data
  # matrix inline.
  cl$Y <- as.name("Y")
  if (!evaluate) return(cl)

  env <- new.env(parent = parent.frame())
  env$Y <- qsort_data(object$dataset, distribution = object$distribution,
                      validate = FALSE)
  eval(cl, envir = env)
}


#' Credible intervals for bayesqm_fit parameters
#'
#' @description
#' Posterior credible intervals for any subset of parameters in a
#' `bayesqm_fit`. Method for [rstantools::posterior_interval()].
#'
#' @param object A `bayesqm_fit`.
#' @param prob Coverage probability (default 0.95).
#' @param pars Optional character vector of exact parameter names.
#' @param regex_pars Optional regex; matching parameter names are included
#'   in addition to those named in `pars`.
#' @param ... Unused.
#'
#' @return A matrix with one row per parameter and two columns for the
#'   lower and upper interval bounds (as percent strings).
#'
#' @method posterior_interval bayesqm_fit
#' @export
posterior_interval.bayesqm_fit <- function(object, prob = 0.95,
                                           pars = NULL, regex_pars = NULL,
                                           ...) {
  m <- as.matrix.bayesqm_fit(object)
  if (!is.null(pars) || !is.null(regex_pars)) {
    keep <- logical(ncol(m))
    if (!is.null(pars))       keep <- keep | (colnames(m) %in% pars)
    if (!is.null(regex_pars)) keep <- keep | grepl(regex_pars, colnames(m))
    if (!any(keep)) stop("No parameters matched pars / regex_pars.")
    m <- m[, keep, drop = FALSE]
  }
  alpha <- 1 - prob
  out <- t(apply(m, 2, quantile, probs = c(alpha / 2, 1 - alpha / 2),
                 names = FALSE, na.rm = TRUE))
  colnames(out) <- sprintf("%.1f%%", 100 * c(alpha / 2, 1 - alpha / 2))
  out
}


#' Prior summary for a bayesqm_fit
#'
#' @description
#' Returns the priors actually used when the model was fit, as a
#' printable `bayesqm_prior` object. Method for
#' [rstantools::prior_summary()].
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
  p <- object$brief$priors
  if (is.null(p))
    stop("This fit has no stored priors. Refit with the current bayesqm version.")

  tau_line <- if (isTRUE(p$use_half_cauchy))
    "tau ~ half-Cauchy(0, 1)"
  else
    sprintf("log(tau) ~ Normal(log(%.2f), 0.5), mapped to (~0.007, ~20)",
            p$loading_scale)

  out <- data.frame(
    parameter = c("tau (loading scale)",
                  "sigma (residual scale)",
                  "nu (Student-t df)",
                  "Lambda[i, k] (loadings)",
                  "F[j, k] (factor scores)"),
    prior = c(
      tau_line,
      sprintf("log(sigma) ~ Normal(log(%.2f), 0.5), truncated to [-5, 3]",
              p$sigma_scale),
      sprintf("nu ~ Gamma(%.1f, %.2f) truncated to [2, 150]",
              p$nu_alpha, p$nu_beta),
      "Lambda[i, k] | tau ~ Normal(0, tau)",
      "F_raw[j, k] ~ N(0, 1), standardized per draw to zero mean, unit variance"
    ),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  class(out) <- c("bayesqm_prior", "data.frame")
  out
}


#' @rdname prior_summary.bayesqm_fit
#' @param x A `bayesqm_prior` object.
#' @export
print.bayesqm_prior <- function(x, ...) {
  cat("bayesqm priors\n\n")
  print.data.frame(x, row.names = FALSE, right = FALSE)
  invisible(x)
}


# loo method. Registered conditionally in .onLoad() so the package loads
# without the 'loo' package installed.
#' @keywords internal
#' @noRd
loo.bayesqm_fit <- function(x, ...) {
  if (is.null(x$loo))
    stop("No element-wise LOO stored on this fit.")
  x$loo
}


# posterior draws-frame method. Registered conditionally in .onLoad().
#' @keywords internal
#' @noRd
as_draws_df.bayesqm_fit <- function(x, ...) {
  if (!requireNamespace("posterior", quietly = TRUE))
    stop("Package 'posterior' is required for as_draws_df().")
  posterior::as_draws_df(as.matrix.bayesqm_fit(x))
}


#' @keywords internal
#' @noRd
as_draws_matrix.bayesqm_fit <- function(x, ...) {
  if (!requireNamespace("posterior", quietly = TRUE))
    stop("Package 'posterior' is required for as_draws_matrix().")
  posterior::as_draws_matrix(as.matrix.bayesqm_fit(x))
}


#' @keywords internal
#' @noRd
as_draws_array.bayesqm_fit <- function(x, ...) {
  if (!requireNamespace("posterior", quietly = TRUE))
    stop("Package 'posterior' is required for as_draws_array().")
  posterior::as_draws_array(as.array.bayesqm_fit(x))
}


#' @keywords internal
#' @noRd
as_draws_rvars.bayesqm_fit <- function(x, ...) {
  if (!requireNamespace("posterior", quietly = TRUE))
    stop("Package 'posterior' is required for as_draws_rvars().")
  posterior::as_draws_rvars(as_draws_array.bayesqm_fit(x))
}


#' @keywords internal
#' @noRd
as_draws_list.bayesqm_fit <- function(x, ...) {
  if (!requireNamespace("posterior", quietly = TRUE))
    stop("Package 'posterior' is required for as_draws_list().")
  posterior::as_draws_list(as_draws_array.bayesqm_fit(x))
}


#' @keywords internal
#' @noRd
as_draws.bayesqm_fit <- function(x, ...) as_draws_df.bayesqm_fit(x)


#' @keywords internal
#' @noRd
ndraws.bayesqm_fit <- function(x, ...) dim(x$Lambda_draws)[1]
