# align.R
# Post-processing applied to saved draws; the sampler state is never
# modified. Conventions (centered, unit-variance score columns, scale pushed
# to the loadings), MatchAlign with a polarity canon, a stabilized final
# orientation, and sigma carried through every rotation.

# center/scale F per draw, counter-scale Lambda and sigma
#' @keywords internal
#' @noRd
apply_conventions <- function(fit) {
  T_ <- dim(fit$F)[1]; K <- fit$K
  for (t in 1:T_) {
    F <- matrix(fit$F[t, , ], ncol = K)
    L <- matrix(fit$Lambda[t, , ], ncol = K)
    F <- sweep(F, 2, colMeans(F))
    d <- sqrt(colMeans(F^2))
    fit$F[t, , ] <- sweep(F, 2, d, "/")
    fit$Lambda[t, , ] <- sweep(L, 2, d, "*")
    fit$sigma[t, ] <- fit$sigma[t, ] * d
  }
  fit
}

# rotate the lambda scale the same way lambda was rotated (diagonal of the
# rotated covariance; exact for permutation/sign, diagonal approx after R)
#' @keywords internal
#' @noRd
rotate_sigma <- function(sig, R)
  sqrt(pmax(diag(t(R) %*% diag(sig^2, length(sig)) %*% R), 0))

#' MatchAlign post-processing for partition-model draws
#'
#' @description
#' Resolves rotational, sign, and label-permutation ambiguity in posterior
#' draws by the MatchAlign procedure of Poworoznek et al. (2025), adapted to
#' the partition model: varimax rotation of the loadings per draw, a pivot
#' draw at the median condition number (overridable), pivot polarity fixed
#' so each factor's loadings skew positive (defining sorts load positively),
#' greedy signed matching of loading columns to the pivot, and a
#' Procrustes rotation. A final pass re-orients every draw to the varimax
#' of the aligned mean loadings, re-signed to positive skew, so the
#' delivered orientation does not inherit one draw's sampling noise. One
#' rotation is applied to loadings and scores alike, and the loading scale
#' `sigma` is carried through.
#'
#' Called for its side effect on the draw arrays of an engine-level fit;
#' users normally receive already-aligned draws from [fit_bayesian()] and
#' need this only to realign under a different pivot.
#'
#' @param fit A fit carrying draw arrays `F` (`[T, J, K]`), `Lambda`
#'   (`[T, N, K]`), `sigma` (`[T, K]`), and `K`.
#' @param pivot Optional draw index to use as the alignment pivot. `NULL`
#'   (the default) selects the draw whose loading condition number sits at
#'   the median.
#'
#' @return The fit with aligned `F`, `Lambda`, and `sigma`, and the chosen
#'   `pivot` index appended.
#'
#' @references
#' Poworoznek, E., Anceschi, N., Ferrari, F., & Dunson, D. (2025).
#'   Efficiently Resolving Rotational Ambiguity in Bayesian Matrix
#'   Sampling with Matching. *Bayesian Analysis*.
#'
#' @export
matchalign <- function(fit, pivot = NULL) {
  if (inherits(fit, "bayesqm_fit")) {
    if (is.null(fit$draws_raw))
      .bq_abort("realigning needs the raw draws; refit with keep_raw = TRUE.")
    b <- fit$brief
    raw <- c(fit$draws_raw, list(N = b$N, J = b$J, K = b$K))
    pp <- postprocess(raw, pivot = pivot)
    keep_fields <- c("F", "Lambda", "sigma", "s_i")
    return(new_bayesqm_fit(
      call = b$call, Y = fit$dataset, distribution = fit$distribution,
      K = b$K, draws = pp[keep_fields], draws_raw = fit$draws_raw,
      state = fit$state, gate = fit$gate,
      align = list(pivot = pp$pivot, congruence = pp$congruence),
      prob = b$prob, seed = b$seed, settings = b$settings,
      fac_ids = dimnames(fit$draws$sigma)[[2]]
    ))
  }
  T_ <- dim(fit$F)[1]; K <- fit$K
  if (K > 1) for (t in 1:T_) {
    R <- stats::varimax(matrix(fit$Lambda[t, , ], ncol = K), normalize = FALSE)$rotmat
    fit$F[t, , ] <- matrix(fit$F[t, , ], ncol = K) %*% R
    fit$Lambda[t, , ] <- matrix(fit$Lambda[t, , ], ncol = K) %*% R
    fit$sigma[t, ] <- rotate_sigma(fit$sigma[t, ], R)
  }
  if (is.null(pivot)) {
    cond <- sapply(1:T_, function(t) {
      d <- svd(matrix(fit$Lambda[t, , ], ncol = K))$d
      d[1] / max(d[K], 1e-12)
    })
    pivot <- which.min(abs(cond - stats::median(cond)))
  }
  # polarity canon on the pivot: positive loading skew per column
  Lp <- matrix(fit$Lambda[pivot, , ], ncol = K)
  Fp <- matrix(fit$F[pivot, , ], ncol = K)
  for (k in 1:K) {
    sk <- sum(Lp[, k]^3)
    if (sk == 0) sk <- sum(Fp[, k]^3)
    if (sk < 0) { Fp[, k] <- -Fp[, k]; Lp[, k] <- -Lp[, k] }
  }
  fit$F[pivot, , ] <- Fp; fit$Lambda[pivot, , ] <- Lp
  congruence <- numeric(T_)
  for (t in 1:T_) {
    F <- matrix(fit$F[t, , ], ncol = K); L <- matrix(fit$Lambda[t, , ], ncol = K)
    if (K > 1) {
      # greedy signed match of loading columns to the pivot, by l2 distance
      dpos <- outer(colSums(L^2), colSums(Lp^2), "+") - 2 * crossprod(L, Lp)
      dneg <- outer(colSums(L^2), colSums(Lp^2), "+") + 2 * crossprod(L, Lp)
      dist <- pmin(dpos, dneg)
      perm <- integer(K); sgn <- numeric(K); avail <- rep(TRUE, K)
      for (b in order(apply(dist, 2, min))) {         # pivot columns, best first
        a <- which.min(ifelse(avail, dist[, b], Inf))
        perm[b] <- a; avail[a] <- FALSE
        sgn[b] <- if (dpos[a, b] <= dneg[a, b]) 1 else -1
      }
      F <- sweep(F[, perm, drop = FALSE], 2, sgn, "*")
      L <- sweep(L[, perm, drop = FALSE], 2, sgn, "*")
      sig <- fit$sigma[t, perm]
      sv <- svd(crossprod(L, Lp))
      R <- sv$u %*% t(sv$v)
      F <- F %*% R; L <- L %*% R
      fit$sigma[t, ] <- rotate_sigma(sig, R)
    } else {
      sgn <- sign(sum(L * Lp)); if (sgn == 0) sgn <- 1
      F <- F * sgn; L <- L * sgn
    }
    fit$F[t, , ] <- F; fit$Lambda[t, , ] <- L
    num <- colSums(L * Lp)
    den <- sqrt(colSums(L^2) * colSums(Lp^2))
    congruence[t] <- mean(abs(num) / pmax(den, 1e-12))
  }
  fit$pivot <- pivot
  fit$congruence <- congruence
  fit
}

# re-orient every draw to the varimax of the aligned-mean loadings,
# polarity re-fixed there; only the common orientation moves
#' @keywords internal
#' @noRd
stabilize_orientation <- function(fit) {
  K <- fit$K
  if (K < 2) return(fit)
  T_ <- dim(fit$F)[1]
  Lm <- apply(fit$Lambda, c(2, 3), mean)
  R <- stats::varimax(Lm, normalize = FALSE)$rotmat
  Lr <- Lm %*% R
  sgn <- vapply(1:K, function(k) {
    sk <- sum(Lr[, k]^3)
    if (sk == 0) 1 else sign(sk)
  }, numeric(1))
  R <- sweep(R, 2, sgn, "*")
  for (t in 1:T_) {
    fit$F[t, , ] <- matrix(fit$F[t, , ], ncol = K) %*% R
    fit$Lambda[t, , ] <- matrix(fit$Lambda[t, , ], ncol = K) %*% R
    fit$sigma[t, ] <- rotate_sigma(fit$sigma[t, ], R)
  }
  fit
}

# conventions -> align -> stable orientation -> conventions; the last pass
# restores exact unit-sd columns so f_jk keeps its z-score reading
#' @keywords internal
#' @noRd
postprocess <- function(fit, pivot = NULL)
  apply_conventions(stabilize_orientation(
    matchalign(apply_conventions(fit), pivot = pivot)))
