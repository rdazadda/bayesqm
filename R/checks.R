# checks.R
# Posterior-predictive model checks and the person check. Replicates
# come from the fitted model's own draws through the same quota-sort engine
# that generated the data; Spearman agreement runs as Pearson on the fixed
# midrank recode, since every sort shares one tie pattern.

#' @keywords internal
#' @noRd
rank_recode <- function(Y, distr) matrix(midranks(distr)[Y], nrow(Y))

#' @keywords internal
#' @noRd
spearman_R <- function(Y, distr) {
  R <- cor(t(rank_recode(Y, distr)))
  R[!is.finite(R)] <- 0; diag(R) <- 1
  R
}

# eigenvalue of the person-correlation matrix one past K
#' @keywords internal
#' @noRd
e_next <- function(Y, distr, K) {
  ev <- eigen(spearman_R(Y, distr), symmetric = TRUE, only.values = TRUE)$values
  if (K + 1 <= length(ev)) ev[K + 1] else NA_real_
}


#' Posterior-predictive checks of the fitted model
#'
#' @description
#' Three checks, each comparing the observed sorts with replicates drawn
#' from the fitted model:
#' the agreement check (T1a) compares the observed person-agreement matrix
#' with replicated ones against a double-replicate reference; the
#' extra-factor check (T1b) locates the observed `(K+1)`-th eigenvalue in
#' its replicated distribution; and the paired-comparison check (T2)
#' compares standardized statement-pair margins, ties counted one half.
#' These are diagnostics to read, not tests to pass.
#'
#' @param fit A `bayesqm_fit`.
#' @param draws Posterior draws used for replication (default 100).
#'
#' @return A `bayesqm_checks` list: `agreement` (`p`), `extra_factor`
#'   (`percentile`), and `paired` (`p`, per-statement `p_j`), with a print
#'   method.
#'
#' @examples
#' check_fit(demo_fit(), draws = 20)
#'
#' @export
check_fit <- function(fit, draws = 100) {
  assert_bayesqm_fit(fit)
  d <- fit$draws
  T_ <- dim(d$F)[1]; N <- fit$brief$N; J <- fit$brief$J; K <- fit$brief$K
  distr <- fit$distribution
  Y <- t(fit$dataset)
  td <- unique(round(seq(1, T_, length.out = min(draws, T_))))

  # T1a: RMSE between observed and replicated agreement matrices, located
  # against a second-replicate reference
  off <- upper.tri(matrix(0, N, N))
  R_obs <- spearman_R(Y, distr)
  rmse <- function(A, B) sqrt(mean((A[off] - B[off])^2))

  # T2: all j < j' margins, ties one half, standardized discrepancy
  pr <- combn(J, 2); a <- pr[1, ]; b <- pr[2, ]
  sel_j <- lapply(seq_len(J), function(j) which(a == j | b == j))
  margins <- function(Ym) colMeans((Ym[, a] > Ym[, b]) + 0.5 * (Ym[, a] == Ym[, b]))
  p_obs <- margins(Y)

  e_obs <- e_next(Y, distr, K)

  t1a_obs <- t1a_ref <- t2o <- t2r <- numeric(length(td))
  e_rep <- numeric(length(td))
  exj <- matrix(NA_real_, length(td), J)
  for (ti in seq_along(td)) {
    t <- td[ti]
    F <- matrix(d$F[t, , ], J, K); L <- matrix(d$Lambda[t, , ], N, K)
    M <- L %*% t(F)
    Y1 <- quota_sort_rows(M + matrix(rnorm(N * J), N, J), distr)
    Y2 <- quota_sort_rows(M + matrix(rnorm(N * J), N, J), distr)
    R1 <- spearman_R(Y1, distr)
    t1a_obs[ti] <- rmse(R_obs, R1)
    t1a_ref[ti] <- rmse(spearman_R(Y2, distr), R1)
    e_rep[ti] <- e_next(Y1, distr, K)
    phat <- colMeans(pnorm((L %*% t(F[a, , drop = FALSE] - F[b, , drop = FALSE])) / sqrt(2)))
    phat <- pmin(pmax(phat, 1e-6), 1 - 1e-6)
    p_rep <- margins(Y1)
    do <- (p_obs - phat)^2 / (phat * (1 - phat))
    dr <- (p_rep - phat)^2 / (phat * (1 - phat))
    t2o[ti] <- sum(do); t2r[ti] <- sum(dr)
    for (j in seq_len(J)) exj[ti, j] <- sum(dr[sel_j[[j]]]) >= sum(do[sel_j[[j]]])
  }

  structure(
    list(agreement = list(p = mean(t1a_ref >= t1a_obs),
                          obs = t1a_obs, ref = t1a_ref),
         extra_factor = list(percentile = mean(e_rep <= e_obs),
                             observed = e_obs, replicated = e_rep),
         paired = list(p = mean(t2r >= t2o),
                       p_j = stats::setNames(colMeans(exj),
                                             dimnames(d$F)[[2]]),
                       obs = t2o, rep = t2r),
         draws = length(td)),
    class = "bayesqm_checks"
  )
}

#' @export
print.bayesqm_checks <- function(x, ...) {
  cat(sprintf("Posterior-predictive checks (%d replicated draws):\n", x$draws))
  cat(sprintf("  agreement check (T1a):        p = %.2f\n", x$agreement$p))
  cat(sprintf("  extra-factor check (T1b):     observed e_(K+1) at percentile %.2f\n",
              x$extra_factor$percentile))
  cat(sprintf("  paired-comparison check (T2): p = %.2f (worst statement %.2f)\n",
              x$paired$p, min(x$paired$p_j)))
  cat("  diagnostics to read, not tests to pass\n")
  invisible(x)
}


#' The person check against mixed-replication bands
#'
#' @description
#' For each participant, the model-agreement statistic `m` (mean over
#' draws of the best absolute Spearman agreement with any factor array)
#' and the person-agreement statistic `w` (best absolute agreement with
#' any other sort), each located against bands from mixed replicates
#' (fresh persons drawn from the fitted model). Verdicts: `fits`,
#' `no_shared` (below the model band, inside the person band),
#' `unspanned` (below the model band but above the person band, a shared
#' viewpoint the fitted factors do not span), and `atypical`. Unspanned
#' persons name their nearest partner.
#'
#' @param fit A `bayesqm_fit`.
#' @param draws Draw grid for the arrays (default 60).
#' @param mixes Mixed replicates for the bands (default 150).
#'
#' @return A `bayesqm_persons` data frame: `participant`, `m`, `w`,
#'   `partner`, `verdict`, with the band limits attached as attributes.
#'
#' @examples
#' check_persons(demo_fit(), draws = 20, mixes = 40)
#'
#' @export
check_persons <- function(fit, draws = 60, mixes = 150) {
  assert_bayesqm_fit(fit)
  d <- fit$draws
  T_ <- dim(d$F)[1]; N <- fit$brief$N; J <- fit$brief$J; K <- fit$brief$K
  distr <- fit$distribution
  Y <- t(fit$dataset)
  td <- unique(round(seq(1, T_, length.out = min(draws, T_))))
  nd <- length(td)
  Yr <- rank_recode(Y, distr)

  AR <- matrix(0, J, K * nd)
  for (ti in seq_len(nd)) for (k in seq_len(K))
    AR[, (ti - 1) * K + k] <- midranks(distr)[quota_sort(d$F[td[ti], , k], distr)]
  draw_of <- rep(seq_len(nd), each = K)
  max_by_draw <- function(v) tapply(abs(v), draw_of, max)
  CC <- cor(t(Yr), AR)
  m_i <- vapply(seq_len(N), function(i) mean(max_by_draw(CC[i, ])), numeric(1))
  W <- abs(cor(t(Yr))); diag(W) <- NA
  w_i <- apply(W, 1, max, na.rm = TRUE)
  w_part <- apply(W, 1, which.max)

  mix_m <- numeric(mixes); mixw <- matrix(NA_real_, mixes, N)
  for (bb in seq_len(mixes)) {
    t <- td[((bb - 1) %% nd) + 1]
    F <- matrix(d$F[t, , ], J, K)
    lam <- rnorm(K, 0, d$sigma[t, ])
    ymix <- midranks(distr)[quota_sort(as.vector(F %*% lam) + rnorm(J), distr)]
    cc <- as.vector(cor(ymix, AR))
    mix_m[bb] <- mean(max_by_draw(cc))
    mixw[bb, ] <- abs(as.vector(cor(ymix, t(Yr))))
  }
  band_m <- quantile(mix_m, c(0.05, 0.95))
  band_w <- t(vapply(seq_len(N), function(i)
    quantile(apply(mixw[, -i, drop = FALSE], 1, max), c(0.05, 0.95)),
    numeric(2)))

  verdict <- rep("fits", N)
  low_m <- m_i < band_m[1]
  verdict[low_m & w_i > band_w[, 2]] <- "unspanned"
  verdict[low_m & w_i <= band_w[, 2] & w_i >= band_w[, 1]] <- "no_shared"
  verdict[low_m & w_i < band_w[, 1]] <- "atypical"

  ids <- dimnames(d$Lambda)[[2]]
  if (anyDuplicated(ids))
    message("participant names are not unique; partner references use the column index")
  out <- data.frame(participant = ids, m = m_i, w = w_i,
                    partner = ids[w_part], partner_index = w_part,
                    verdict = verdict, stringsAsFactors = FALSE)
  rownames(out) <- NULL
  attr(out, "band_m") <- band_m
  attr(out, "band_w") <- band_w
  class(out) <- c("bayesqm_persons", "data.frame")
  out
}

#' @export
print.bayesqm_persons <- function(x, ...) {
  counts <- table(factor(x$verdict,
                         levels = c("fits", "no_shared", "unspanned", "atypical")))
  cat("Person check:",
      paste(sprintf("%s %d", names(counts), counts), collapse = ", "), "\n")
  unsp <- x$participant[x$verdict == "unspanned"]
  if (length(unsp)) {
    cat("  unspanned persons and their nearest partners:\n")
    for (i in which(x$verdict == "unspanned"))
      cat(sprintf("    %s -> %s (w = %.2f)\n", x$participant[i],
                  x$partner[i], x$w[i]))
  }
  print.data.frame(x, digits = 2, row.names = FALSE)
  invisible(x)
}

# Algorithm 2's T3 co-fire condition: two or more unspanned persons that
# point at each other as nearest partners (mutual)
#' @keywords internal
#' @noRd
unspanned_cluster <- function(pc) {
  idx <- which(pc$verdict == "unspanned")
  pi_ <- if (!is.null(pc$partner_index)) pc$partner_index
         else match(pc$partner, pc$participant)
  length(idx) >= 2 && any(vapply(idx, function(i)
    pi_[i] %in% idx && pi_[pi_[i]] == i, logical(1)))
}
