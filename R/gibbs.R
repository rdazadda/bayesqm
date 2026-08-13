# gibbs.R
# The exact partition (rank-order) likelihood engine: quota sort, PX-Gibbs
# sampler with warm-started continuation, and the convergence gate on the
# invariant person spreads s_i.

#' Grid width on the z scale
#'
#' @description
#' The width of one grid column on the standardized score scale,
#' `1 / sd(forced positions)` with the population standard deviation. This
#' is the equivalence-region half-width used for consensus verdicts: a
#' score contrast smaller than one grid column is not expressible in a
#' completed sort.
#'
#' @param distribution Integer vector of forced-distribution counts (the
#'   number of statements allowed in each grid column).
#'
#' @return A single numeric value.
#'
#' @examples
#' delta_grid(c(2, 3, 4, 5, 7, 7, 5, 4, 3, 2))
#'
#' @export
delta_grid <- function(distribution) {
  v <- rep(seq_along(distribution), distribution)
  1 / sqrt(mean((v - mean(v))^2))
}

# rank a utility vector onto the forced grid; ties impossible a.s.
#' @keywords internal
#' @noRd
quota_sort <- function(u, distr) {
  y <- integer(length(u))
  y[order(u)] <- rep(seq_along(distr), distr)
  y
}

# all rows at once; identical to row-wise quota_sort, no RNG involved
#' @keywords internal
#' @noRd
quota_sort_rows <- function(U, distr) {
  Y <- array(0L, dim(U))
  Y[order(row(U), U)] <- rep(rep(seq_along(distr), distr), nrow(U))
  Y
}

# midrank of each category under the quotas; Spearman on quota sorts equals
# Pearson on these recodes
#' @keywords internal
#' @noRd
midranks <- function(distr) {
  hi <- cumsum(distr)
  (hi + c(1, head(hi, -1) + 1)) / 2
}

# inverse-cdf truncated normal; the clamp guards the extreme-tail case where
# both cdf values round to the same double
#' @keywords internal
#' @noRd
rtnorm <- function(m, lo, hi) {
  plo <- pnorm(lo, m, 1); phi <- pnorm(hi, m, 1)
  u <- runif(length(m), plo, phi)
  pmin(pmax(qnorm(pmin(pmax(u, 1e-15), 1 - 1e-15), m, 1), lo), hi)
}

# stepping-out slice sampler (Neal) for one scalar. The shrink loop carries
# an iteration cap: draws are identical on every healthy path, but a
# degenerate spin aborts with a diagnosable error instead of freezing the
# session.
#' @keywords internal
#' @noRd
slice1 <- function(x0, logf, w = 0.5, lower = 1e-6, upper = 50) {
  y <- logf(x0) - rexp(1)
  L <- max(lower, x0 - w * runif(1)); R <- min(upper, L + w)
  while (L > lower && logf(L) > y) L <- max(lower, L - w)
  while (R < upper && logf(R) > y) R <- min(upper, R + w)
  it <- 0L
  repeat {
    x1 <- runif(1, L, R)
    if (logf(x1) > y) return(x1)
    if (x1 < x0) L <- x1 else R <- x1
    it <- it + 1L
    if (it > 2e5)
      stop("slice1: shrink loop exceeded 2e5 iterations (x0=",
           signif(x0, 6), ", y=", signif(y, 6), ")")
  }
}

# start U consistent with the observed sort: Blom scores, random within category
#' @keywords internal
#' @noRd
init_U <- function(Y) {
  N <- nrow(Y); J <- ncol(Y)
  blom <- qnorm(((1:J) - 0.375) / (J + 0.25))
  U <- matrix(0, N, J)
  for (i in 1:N) {
    ord <- order(Y[i, ], stats::runif(J))       # ascending category, random within
    U[i, ord] <- blom
  }
  U
}

# PX-Gibbs for the partition likelihood. Y is persons x statements in
# category codes 1..C obeying the quotas. state = NULL starts a fresh chain
# (seed, random init, burn); passing the state returned by an earlier call
# continues that chain instead — no reseed, no burn, and the captured RNG
# state is restored, so a continued chain is draw-for-draw identical to one
# long run even across sessions.
#' @keywords internal
#' @noRd
fit_partition <- function(Y, distr, K,
                          n_iter = 12000, burn = 2000, thin = 5,
                          seed = NULL, sigma_scale = 1, state = NULL,
                          init_scale = 0.1) {
  N <- nrow(Y); J <- ncol(Y); C <- length(distr)
  stopifnot(all(apply(Y, 1, function(r) all(tabulate(r, C) == distr))))
  cat_idx <- lapply(1:C, function(c) lapply(1:N, function(i) which(Y[i, ] == c)))

  if (is.null(state)) {
    if (!is.null(seed)) set.seed(seed)
    U <- init_U(Y)
    F <- matrix(rnorm(J * K, 0, init_scale), J, K)
    L <- matrix(rnorm(N * K, 0, init_scale), N, K)
    sig <- rep(1, K)
  } else {
    burn <- 0
    assign(".Random.seed", state$rng, envir = globalenv())
    U <- state$U; F <- state$F; L <- state$L; sig <- state$sig
  }

  # last keep lands on n_iter when (n_iter - burn) is a multiple of thin, so
  # a continuation block keeps the same phase
  keep <- seq(burn + thin, n_iter, by = thin)
  Fd <- array(NA_real_, c(length(keep), J, K))
  Ld <- array(NA_real_, c(length(keep), N, K))
  Sd <- matrix(NA_real_, length(keep), K)
  inv_spread <- matrix(NA_real_, length(keep), N)   # s_i, invariant diagnostic
  s <- 0L

  for (it in 1:n_iter) {
    # utilities, category by category; the lower bound is the running max of
    # the category just drawn, the upper the current min of the one above
    M <- L %*% t(F)
    for (i in 1:N) {
      ui <- U[i, ]; Mi <- M[i, ]
      lo <- -Inf
      for (c in 1:C) {
        jj <- cat_idx[[c]][[i]]
        hi <- if (c == C) Inf else min(ui[cat_idx[[c + 1]][[i]]])
        vals <- rtnorm(Mi[jj], lo, hi)
        ui[jj] <- vals
        lo <- max(vals)
      }
      U[i, ] <- ui
    }

    # PX working scale, rescale u, then lambda; V does not depend on i
    V <- chol2inv(chol(crossprod(F) + diag(1 / sig^2, K)))
    A <- U %*% F
    r <- rowSums(U^2) - rowSums((A %*% V) * A)
    v <- 1 / sqrt(rgamma(N, shape = J / 2, rate = pmax(r, 1e-12) / 2))
    U <- U / v
    A <- A / v
    cV <- chol(V)
    L <- A %*% V + matrix(rnorm(N * K), N, K) %*% cV

    # statement scores
    Vf <- chol2inv(chol(crossprod(L) + diag(K)))
    F <- t(U) %*% L %*% Vf + matrix(rnorm(J * K), J, K) %*% chol(Vf)

    # sigma_k, slice on the half-normal conditional; the bracket scales
    # with the prior so a wide sigma_scale is never silently truncated
    for (k in 1:K) {
      ssq <- sum(L[, k]^2)
      sig[k] <- slice1(sig[k], function(x)
        -N * log(x) - ssq / (2 * x^2) - x^2 / (2 * sigma_scale^2),
        upper = max(50, 10 * sigma_scale))
    }

    if (it %in% keep) {
      s <- s + 1L
      Fd[s, , ] <- F; Ld[s, , ] <- L; Sd[s, ] <- sig
      Fc <- sweep(F, 2, colMeans(F))
      inv_spread[s, ] <- sqrt(rowSums((L %*% (crossprod(Fc) / J)) * L))
    }
  }
  list(F = Fd, Lambda = Ld, sigma = Sd, s_i = inv_spread,
       state = list(U = U, F = F, L = L, sig = sig,
                    rng = get(".Random.seed", envir = globalenv())),
       N = N, J = J, K = K, distr = distr)
}

# gate statistics for one person's kept series. The single chain is split
# into two halves and posterior splits each again, giving the four-segment
# rank-normalized (and folded) split-Rhat of Vehtari et al. (2021); ESS uses
# Geyer's (1992) initial monotone sequence truncation. All deterministic, so
# checking mid-chain consumes no RNG.
#' @keywords internal
#' @noRd
conv_stats <- function(x) {
  m <- matrix(x[seq_len(2L * (length(x) %/% 2L))], ncol = 2)
  c(rhat = posterior::rhat(m),
    bulk = posterior::ess_bulk(m),
    tail = posterior::ess_tail(m))
}

# the gate: over persons, max Rhat and min bulk/tail ESS
#' @keywords internal
#' @noRd
check_conv <- function(fit, rhat_max = 1.01, ess_min = 400) {
  st <- apply(fit$s_i, 2, conv_stats)
  rhat <- suppressWarnings(max(st["rhat", ], na.rm = TRUE))
  bulk <- suppressWarnings(min(st["bulk", ], na.rm = TRUE))
  tl   <- suppressWarnings(min(st["tail", ], na.rm = TRUE))
  list(rhat = rhat, ess = bulk, ess_tail = tl,
       ok = is.finite(rhat) && rhat < rhat_max &&
            is.finite(bulk) && bulk >= ess_min &&
            is.finite(tl)   && tl >= ess_min)
}

# append a continuation block to a fit, draw arrays along the draw dimension
#' @keywords internal
#' @noRd
grow_fit <- function(fit, ext) {
  bind3 <- function(a, b) {
    d <- dim(a)
    out <- array(NA_real_, c(d[1] + dim(b)[1], d[2], d[3]))
    out[seq_len(d[1]), , ] <- a
    out[-seq_len(d[1]), , ] <- b
    out
  }
  fit$F <- bind3(fit$F, ext$F)
  fit$Lambda <- bind3(fit$Lambda, ext$Lambda)
  fit$sigma <- rbind(fit$sigma, ext$sigma)
  fit$s_i <- rbind(fit$s_i, ext$s_i)
  fit$state <- ext$state
  fit
}

# gated fit, a fixed-ESS sequential stopping rule: first check at the floor,
# then warm-started doubling of total length until the gate passes or the
# cap. The burn is paid once and no draws are discarded; the gate is always
# recomputed on the entire kept chain. Never errors on nonconvergence — the
# caller reads converged and warns.
#' @keywords internal
#' @noRd
fit_partition_gated <- function(Y, distr, K, seed = NULL, sigma_scale = 1,
                                n_iter = 12000, burn = 2000, thin = 5,
                                n_max = 48000, rhat_max = 1.01, ess_min = 400,
                                init_scale = 0.1, quiet = TRUE) {
  fit <- fit_partition(Y, distr, K, n_iter = n_iter, burn = burn, thin = thin,
                       seed = seed, sigma_scale = sigma_scale,
                       init_scale = init_scale)
  cv <- check_conv(fit, rhat_max, ess_min)
  total <- as.integer(n_iter)
  while (!cv$ok && total < n_max) {
    if (!quiet)
      message(sprintf("gate not met at %d iterations (Rhat %.3f, ESS %.0f); extending to %d",
                      total, cv$rhat, min(cv$ess, cv$ess_tail), 2L * total))
    ext <- fit_partition(Y, distr, K, n_iter = total, burn = 0, thin = thin,
                         sigma_scale = sigma_scale, state = fit$state)
    fit <- grow_fit(fit, ext)
    total <- 2L * total
    cv <- check_conv(fit, rhat_max, ess_min)
  }
  fit$converged <- cv$ok; fit$extended <- total > n_iter; fit$iters <- total
  fit$rhat <- cv$rhat; fit$ess <- cv$ess; fit$ess_tail <- cv$ess_tail
  fit
}
