# helpers.R
# Data generation and evaluation utilities for Bayesian Q methodology.


#' Simulate Q-sort data
#'
#' @description
#' `generate_data()` is the top-level data-generating function used
#' by the package's simulation studies and tests. It builds a
#' loading matrix (`generate_loadings()`), factor scores, noise of the
#' chosen type (`generate_noise()`), and discretises the continuous
#' signal onto a forced Q-sort grid (`discretize_to_grid()`). See also
#' `get_distribution()` for the standard forced-distribution lookup.
#'
#' @param N,J,K Numbers of participants, statements, and factors.
#' @param noise_sd Residual SD.
#' @param error_type One of `"normal"`, `"t"`, `"contaminated"`.
#' @param nu Degrees of freedom for `error_type = "t"`.
#' @param contam_prop,contam_scale Contamination rate and scale.
#' @param loading_type `"simple"` or `"complex"`.
#' @param primary_range,cross_range Uniform ranges for primary and
#'   cross-loadings.
#' @param seed Optional RNG seed; restored on exit.
#' @param Y_cont Continuous scores (for `discretize_to_grid()`).
#' @param distr Integer forced-distribution counts.
#' @param type For `generate_noise()`, one of `"normal"`, `"t"`,
#'   `"contaminated"`. For `generate_loadings()`, `"simple"` or
#'   `"complex"`.
#' @param sd Residual SD for `generate_noise()`.
#'
#' @return `generate_data()` returns a list with `Y`, `Lambda_true`,
#'   `F_true`, `distribution`, `N`, `J`, `K`. The component helpers
#'   return their respective raw objects.
#'
#' @name generate_data
#' @aliases generate_loadings generate_noise discretize_to_grid get_distribution
#' @export
generate_data <- function(N, J, K, noise_sd = 1, error_type = "normal",
                          nu = 5, contam_prop = 0.10, contam_scale = 4,
                          loading_type = "simple",
                          primary_range = c(0.55, 0.85),
                          cross_range  = c(-0.15, 0.15),
                          seed = NULL) {
  if (!is.null(seed)) set.seed(seed)

  distr  <- get_distribution(J)
  Lambda <- generate_loadings(N, K, primary_range = primary_range,
                              cross_range = cross_range,
                              type = loading_type)
  Fmat <- matrix(rnorm(J * K), nrow = J, ncol = K)
  mu   <- Fmat %*% t(Lambda)
  E    <- generate_noise(J, N, type = error_type, sd = noise_sd,
                         nu = nu, contam_prop = contam_prop,
                         contam_scale = contam_scale)
  Y <- discretize_to_grid(mu + E, distr)

  list(Y = Y, Lambda_true = Lambda, F_true = Fmat,
       distribution = distr, N = N, J = J, K = K)
}


#' @rdname generate_data
#' @export
generate_loadings <- function(N, K, primary_range = c(0.55, 0.85),
                              cross_range = c(-0.15, 0.15),
                              type = "simple") {
  Lambda <- matrix(0, N, K)
  assignment <- rep(seq_len(K), length.out = N)

  for (i in seq_len(N)) {
    kp <- assignment[i]
    Lambda[i, kp] <- runif(1, primary_range[1], primary_range[2])
    for (k in seq_len(K))
      if (k != kp) Lambda[i, k] <- runif(1, cross_range[1], cross_range[2])
  }

  if (type == "complex" && K >= 2) {
    nc  <- max(1, round(0.20 * N))
    idx <- sample.int(N, nc)
    for (i in idx) {
      kp <- assignment[i]
      ks <- sample(setdiff(seq_len(K), kp), 1)
      Lambda[i, ks] <- runif(1, 0.25, 0.45)
    }
  }

  colnames(Lambda) <- paste0("V", seq_len(K))
  rownames(Lambda) <- paste0("p", seq_len(N))
  Lambda
}


#' @rdname generate_data
#' @export
generate_noise <- function(J, N, type = "normal", sd = 1,
                           nu = 5, contam_prop = 0.10, contam_scale = 4) {
  n <- J * N
  E <- switch(type,
    normal = rnorm(n, 0, sd),
    t = rt(n, df = nu) * sd,
    contaminated = {
      is_outlier <- rbinom(n, 1, contam_prop)
      ifelse(is_outlier == 1, rnorm(n, 0, contam_scale * sd), rnorm(n, 0, sd))
    },
    stop("Unknown error type: ", type)
  )
  matrix(E, nrow = J, ncol = N)
}


#' @rdname generate_data
#' @export
discretize_to_grid <- function(Y_cont, distr) {
  J <- nrow(Y_cont); N <- ncol(Y_cont)
  n_pos <- length(distr)

  if (n_pos %% 2 == 1) {
    half <- (n_pos - 1) / 2
    grid_vals <- seq(-half, half)
  } else {
    half <- n_pos / 2
    grid_vals <- c(seq(-half, -1), seq(1, half))
  }
  scores <- rep(grid_vals, times = distr)

  if (sum(distr) != J)
    stop("Forced distribution must sum to J. Got ", sum(distr), " for J = ", J)

  Y <- matrix(NA_integer_, J, N)
  for (n in seq_len(N)) {
    rnk    <- rank(Y_cont[, n], ties.method = "random")
    Y[, n] <- scores[rnk]
  }
  Y
}


#' @rdname generate_data
#' @export
get_distribution <- function(J) {
  tbl <- list(
    "9"  = c(1, 1, 2, 1, 2, 1, 1),
    "13" = c(1, 1, 2, 2, 3, 2, 1, 1),
    "15" = c(1, 2, 2, 3, 3, 2, 2),
    "19" = c(1, 2, 2, 3, 3, 3, 2, 2, 1),
    "20" = c(1, 2, 2, 3, 4, 3, 2, 2, 1),
    "23" = c(1, 2, 3, 3, 4, 3, 3, 2, 2),
    "30" = c(2, 3, 3, 4, 6, 4, 3, 3, 2),
    "33" = c(1, 3, 4, 5, 5, 5, 4, 3, 3),
    "34" = c(2, 3, 4, 5, 6, 5, 4, 3, 2),
    "40" = c(2, 3, 4, 5, 6, 6, 5, 4, 3, 2),
    "42" = c(2, 3, 4, 5, 7, 7, 5, 4, 3, 2),
    "47" = c(2, 3, 4, 5, 6, 7, 6, 5, 4, 3, 2),
    "48" = c(2, 3, 4, 5, 7, 6, 7, 5, 4, 3, 2),
    "60" = c(2, 4, 5, 7, 8, 8, 8, 7, 5, 4, 2)
  )
  key <- as.character(J)
  if (key %in% names(tbl)) return(tbl[[key]])

  for (w in c(7, 9, 11, 5, 13)) {
    hw   <- (w - 1) / 2
    base <- c(seq_len(hw), hw + 1, rev(seq_len(hw)))
    if (J >= sum(base)) {
      base[(w + 1) / 2] <- base[(w + 1) / 2] + (J - sum(base))
      return(base)
    }
  }

  d <- rep(J %/% 7, 7)
  d[4] <- d[4] + (J - sum(d))
  d
}


#' Simulation-study assessment helpers
#'
#' @description
#' `assess_recovery()` compares a point estimate and optional posterior
#' draws to a known loading truth, returning RMSE, per-factor RMSE,
#' bias, Tucker's congruence, credible-interval coverage, width, and
#' Gneiting-Raftery interval score. `assess_classification()` compares
#' a logical flag matrix to the true factor assignments using optimal
#' permutation matching.
#'
#' @param Lambda_hat Estimated loading matrix (N x K).
#' @param Lambda_true True loading matrix.
#' @param Lambda_draws Optional array of shape `[T, N, K]` of posterior
#'   draws, used for coverage / interval metrics.
#' @param prob Credible-interval probability.
#' @param flags Logical matrix of factor assignments.
#'
#' @return `assess_recovery()` returns a list of metrics;
#'   `assess_classification()` returns a list with `accuracy` and
#'   `per_factor`.
#'
#' @name assess_recovery
#' @aliases assess_classification
#' @export
assess_recovery <- function(Lambda_hat, Lambda_true, Lambda_draws = NULL,
                            prob = 0.95) {
  K <- ncol(Lambda_true)
  L_aligned <- procrustes_rotation(Lambda_hat, Lambda_true)

  diff     <- L_aligned - Lambda_true
  rmse     <- sqrt(mean(diff^2))
  rmse_fac <- sqrt(colMeans(diff^2))
  bias     <- mean(diff)
  bias_fac <- colMeans(diff)

  tuck <- numeric(K)
  for (k in seq_len(K))
    tuck[k] <- tucker_congruence(L_aligned[, k], Lambda_true[, k])

  coverage <- ci_width <- is_score <- NA_real_
  ci_lo <- ci_hi <- NULL

  if (!is.null(Lambda_draws)) {
    nd <- dim(Lambda_draws)[1]
    alpha <- 1 - prob

    # Single Procrustes from posterior mean to truth, applied to all draws
    R <- attr(procrustes_rotation(Lambda_hat, Lambda_true), "rotation")
    aligned_draws <- Lambda_draws
    for (s in seq_len(nd))
      aligned_draws[s, , ] <- Lambda_draws[s, , ] %*% R

    dm <- dim(aligned_draws)[2:3]
    ci_lo <- apply(aligned_draws, c(2, 3), quantile, probs =     alpha / 2)
    ci_hi <- apply(aligned_draws, c(2, 3), quantile, probs = 1 - alpha / 2)
    dim(ci_lo) <- dm; dim(ci_hi) <- dm

    inside   <- (Lambda_true >= ci_lo) & (Lambda_true <= ci_hi)
    coverage <- mean(inside)
    ci_width <- mean(ci_hi - ci_lo)

    # Interval score (Gneiting & Raftery, 2007)
    is_score <- mean((ci_hi - ci_lo) +
                     (2 / alpha) * pmax(ci_lo - Lambda_true, 0) +
                     (2 / alpha) * pmax(Lambda_true - ci_hi, 0))
  }

  list(rmse = rmse, rmse_factor = rmse_fac,
       bias = bias, bias_factor = bias_fac,
       tucker = tuck, ci_lower = ci_lo, ci_upper = ci_hi,
       coverage = coverage, ci_width = ci_width,
       interval_score = is_score)
}


#' @rdname assess_recovery
#' @export
assess_classification <- function(flags, Lambda_true) {
  N <- nrow(Lambda_true); K <- ncol(Lambda_true)
  true_assign <- apply(abs(Lambda_true), 1, which.max)

  if (is.null(flags) || all(!flags))
    return(list(accuracy = 0, per_factor = rep(0, K)))

  est <- apply(flags, 1, function(row) {
    w <- which(row)
    if (length(w) == 1) w else if (length(w) == 0) NA_integer_ else w[1]
  })

  # Align estimated labels to true labels via optimal permutation
  conf <- matrix(0, K, K)
  valid <- !is.na(est)
  for (i in which(valid))
    conf[est[i], true_assign[i]] <- conf[est[i], true_assign[i]] + 1

  if (requireNamespace("lpSolve", quietly = TRUE)) {
    sol  <- lpSolve::lp.assign(max(conf + 1) - conf)
    perm <- apply(sol$solution, 1, which.max)
  } else {
    perm <- integer(K); used <- logical(K)
    for (k in seq_len(K)) {
      bj <- 0; bv <- -1
      for (j in seq_len(K))
        if (!used[j] && conf[k, j] > bv) { bv <- conf[k, j]; bj <- j }
      perm[k] <- bj; used[bj] <- TRUE
    }
  }

  ea <- rep(NA_integer_, N)
  ea[valid] <- perm[est[valid]]
  matched <- !is.na(ea) & (ea == true_assign)

  pf <- numeric(K)
  for (k in seq_len(K)) {
    idx   <- which(true_assign == k)
    pf[k] <- mean(matched[idx], na.rm = TRUE)
  }

  list(accuracy = mean(matched, na.rm = TRUE), per_factor = pf)
}


#' Tucker's congruence and orthogonal Procrustes rotation
#'
#' @description
#' Linear-algebra utilities shared by MatchAlign and the recovery
#' assessments. `tucker_congruence(x, y)` computes `sum(x*y) /
#' sqrt(sum(x^2) * sum(y^2))`. `procrustes_rotation(X, Target)` finds
#' the orthogonal `R` minimising `||X R - Target||_F` and returns
#' `X %*% R` with `R` attached as attribute `"rotation"`.
#'
#' @param x,y Numeric vectors (for Tucker).
#' @param X,Target Matrices (for Procrustes).
#' @return Tucker returns a scalar; Procrustes returns the rotated
#'   matrix with a `"rotation"` attribute.
#' @name tucker_congruence
#' @aliases procrustes_rotation
#' @export
tucker_congruence <- function(x, y) {
  d <- sqrt(sum(x^2) * sum(y^2))
  if (d < 1e-12) NA_real_ else sum(x * y) / d
}


#' @rdname tucker_congruence
#' @export
procrustes_rotation <- function(X, Target) {
  X <- as.matrix(X); Target <- as.matrix(Target)
  sv  <- svd(t(X) %*% Target)
  R   <- sv$u %*% t(sv$v)
  out <- X %*% R
  attr(out, "rotation") <- R
  out
}
