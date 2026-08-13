# summaries.R
# The posterior tables: bounded loadings, flag probabilities with an
# unclassified state, statement scores, quota-respecting factor arrays,
# and the distinguishing/consensus verdicts. Every selected column in
# every table comes from the one fdr_select() path, so claims() and the
# table functions can never disagree.


# selection rule: largest prefix with posterior expected FDR <= q
#' @keywords internal
#' @noRd
fdr_select <- function(p, q = 0.05, floor = NA) {
  keep <- if (is.na(floor)) rep(TRUE, length(p)) else p >= floor
  idx <- order(p, decreasing = TRUE)
  sel <- logical(length(p))
  err <- cumsum(1 - p[idx]) / seq_along(idx)
  ok <- which(err <= q & keep[idx])
  if (length(ok)) sel[idx[seq_len(max(ok))]] <- keep[idx[seq_len(max(ok))]]
  list(selected = sel, expected_false = sum(1 - p[sel]))
}


# per-draw signed flag column per person, 2K + 1 for unclassified. A person
# is a flag candidate for k+/k- in a draw when factor k carries the
# majority of the squared loading AND the bounded loading clears the Brown
# floor 1.96/sqrt(J).
#' @keywords internal
#' @noRd
.flag_draws <- function(fit) {
  d <- fit$draws
  T_ <- dim(d$F)[1]; J <- fit$brief$J; K <- fit$brief$K; N <- fit$brief$N
  floorJ <- 1.96 / sqrt(J)
  colidx <- matrix(NA_integer_, T_, N)
  for (t in seq_len(T_)) {
    F <- matrix(d$F[t, , ], J, K); L <- matrix(d$Lambda[t, , ], N, K)
    S <- crossprod(sweep(F, 2, colMeans(F))) / J
    qv <- L %*% S
    rho <- qv / sqrt(pmax(rowSums(qv * L), 0) + 1)
    L2 <- L^2
    dom <- max.col(L2, ties.method = "first")
    dompass <- L2[cbind(seq_len(N), dom)] >
      (rowSums(L2) - L2[cbind(seq_len(N), dom)])
    r_dom <- rho[cbind(seq_len(N), dom)]
    flagged <- dompass & (abs(r_dom) > floorJ)
    colidx[t, ] <- ifelse(flagged,
                          2L * (dom - 1L) + ifelse(r_dom >= 0, 1L, 2L),
                          2L * K + 1L)
  }
  colidx
}


# phi: N x (2K + 1) matrix of signed flag-candidate probabilities plus the
# unclassified state
#' @keywords internal
#' @noRd
.phi_matrix <- function(fit) {
  d <- fit$draws
  K <- fit$brief$K
  colidx <- .flag_draws(fit)
  phi <- t(apply(colidx, 2, tabulate, nbins = 2L * K + 1L)) / nrow(colidx)
  fac_ids <- dimnames(d$sigma)[[2]]
  colnames(phi) <- c(rbind(paste0(fac_ids, "+"), paste0(fac_ids, "-")),
                     "unclassified")
  rownames(phi) <- dimnames(d$Lambda)[[2]]
  phi
}


# quota arrays per draw: g[t, j, k] is statement j's grid column under
# factor k's scores in draw t
#' @keywords internal
#' @noRd
.g_draws <- function(fit, negative = FALSE) {
  d <- fit$draws
  T_ <- dim(d$F)[1]; J <- fit$brief$J; K <- fit$brief$K
  distr <- fit$distribution
  g <- array(NA_integer_, c(T_, J, K))
  for (t in seq_len(T_)) for (k in seq_len(K))
    g[t, , k] <- quota_sort(if (negative) -d$F[t, , k] else d$F[t, , k], distr)
  g
}


# contrast machinery shared by compute_qdc and claims: the posterior
# critical difference delta_kl per pair, exceedance probabilities, the
# joint distinguishing and consensus events, and the contrast intervals.
# prob governs the DISPLAY interval only; the critical difference keeps
# its z_.975.
#' @keywords internal
#' @noRd
.pair_stats <- function(fit, prob = NULL) {
  prob <- if (is.null(prob)) fit$brief$prob else prob
  alpha <- 1 - prob
  d <- fit$draws
  T_ <- dim(d$F)[1]; J <- fit$brief$J; K <- fit$brief$K
  if (K < 2)
    .bq_abort("distinguishing and consensus verdicts need K >= 2 factors.")
  dgrid <- delta_grid(fit$distribution)
  pairs <- combn(K, 2)
  P <- ncol(pairs)
  fac_ids <- dimnames(d$sigma)[[2]]
  pair_ids <- paste(fac_ids[pairs[1, ]], fac_ids[pairs[2, ]], sep = "-")

  delta_kl <- delta_kl99 <- numeric(P)
  pi_pair <- pi_pair99 <- d_med <- d_lo <- d_hi <-
    matrix(NA_real_, J, P, dimnames = list(dimnames(d$F)[[2]], pair_ids))
  exc <- vector("list", P)
  for (p in seq_len(P)) {
    D <- matrix(d$F[, , pairs[1, p]] - d$F[, , pairs[2, p]], T_, J)
    sdj <- apply(D, 2, sd)
    delta_kl[p] <- qnorm(0.975) * mean(sdj)
    delta_kl99[p] <- qnorm(0.995) * mean(sdj)
    exc[[p]] <- abs(D) > delta_kl[p]
    pi_pair[, p] <- colMeans(exc[[p]])
    pi_pair99[, p] <- colMeans(abs(D) > delta_kl99[p])
    qd <- apply(D, 2, quantile, probs = c(alpha / 2, .5, 1 - alpha / 2))
    d_lo[, p] <- qd[1, ]; d_med[, p] <- qd[2, ]; d_hi[, p] <- qd[3, ]
  }
  names(delta_kl) <- names(delta_kl99) <- pair_ids

  slice <- function(k) matrix(d$F[, , k], T_, J)
  mxF <- Reduce(pmax, lapply(seq_len(K), slice))
  mnF <- Reduce(pmin, lapply(seq_len(K), slice))
  pi_cons <- colMeans((mxF - mnF) < dgrid)
  names(pi_cons) <- dimnames(d$F)[[2]]

  pi_dist <- matrix(NA_real_, J, K,
                    dimnames = list(dimnames(d$F)[[2]], fac_ids))
  for (k in seq_len(K)) {
    touch <- which(pairs[1, ] == k | pairs[2, ] == k)
    pi_dist[, k] <- colMeans(Reduce(`&`, exc[touch]))
  }

  list(pairs = pairs, pair_ids = pair_ids, delta_kl = delta_kl,
       delta_kl99 = delta_kl99, delta_grid = dgrid, pi_pair = pi_pair,
       pi_pair99 = pi_pair99, pi_dist = pi_dist, pi_cons = pi_cons,
       d_med = d_med, d_lo = d_lo, d_hi = d_hi)
}


#' Bounded participant loadings with credible intervals
#'
#' @description
#' The correlation-scale loading of the accompanying paper,
#' `rho = (S lambda)_k / sqrt(s^2 + 1)`, summarized per participant and
#' factor, with the posterior-mean person spread `s_i` alongside.
#'
#' @param fit A `bayesqm_fit`.
#' @param prob Credible-interval probability; defaults to the fit's.
#'
#' @return A data frame with one row per participant: `participant`, then
#'   `f{k}_loading`, `f{k}_lower`, `f{k}_upper` per factor, then `spread`
#'   (posterior-mean `s_i`).
#'
#' @examples
#' compute_loadings(demo_fit())
#'
#' @export
compute_loadings <- function(fit, prob = NULL) {
  assert_bayesqm_fit(fit)
  prob <- if (is.null(prob)) fit$brief$prob else prob
  alpha <- 1 - prob
  rho <- .rho_draws(fit)
  m <- .summarize_draws(rho, mean)
  lo <- .summarize_draws(rho, quantile, probs = alpha / 2, names = FALSE)
  hi <- .summarize_draws(rho, quantile, probs = 1 - alpha / 2, names = FALSE)
  out <- data.frame(participant = rownames(m), stringsAsFactors = FALSE)
  for (k in seq_len(ncol(m))) {
    fk <- colnames(m)[k]
    out[[paste0(fk, "_loading")]] <- m[, k]
    out[[paste0(fk, "_lower")]] <- lo[, k]
    out[[paste0(fk, "_upper")]] <- hi[, k]
  }
  out$spread <- colMeans(fit$draws$s_i)
  rownames(out) <- NULL
  out
}


#' Factor characteristics
#'
#' @description
#' The per-factor block of the accompanying paper: modal and mean number
#' of defining sorts per posterior draw with a credible interval, the
#' selected flag count, the mean posterior spread of the statement
#' scores, and the mean replicate reliability
#' `R_i = s_i^2 / (1 + s_i^2)` of the flagged participants. The
#' statement-score correlations between factors ride along as an
#' attribute.
#'
#' @param fit A `bayesqm_fit`.
#' @param prob Credible-interval probability for the defining-sort counts
#'   (default 0.90).
#' @param q,floor The flag rule fixing the flagged set, as in
#'   [compute_flags()].
#'
#' @return A data frame with one row per factor: `factor`, `flagged`
#'   (selected flags), `defining_modal`, `defining_mean`,
#'   `defining_lower`, `defining_upper`, `score_spread`, and
#'   `reliability`. Attribute `score_correlations` holds the posterior
#'   mean K x K correlation matrix of the statement scores.
#'
#' @examples
#' factor_characteristics(demo_fit())
#'
#' @export
factor_characteristics <- function(fit, prob = 0.90, q = 0.05, floor = 0.5) {
  assert_bayesqm_fit(fit)
  d <- fit$draws
  T_ <- dim(d$F)[1]; J <- fit$brief$J; K <- fit$brief$K
  fac_ids <- dimnames(d$sigma)[[2]]
  alpha <- 1 - prob

  colidx <- .flag_draws(fit)
  counts <- vapply(seq_len(K), function(k)
    rowSums(colidx == 2L * k - 1L | colidx == 2L * k), numeric(T_))

  fl <- .flag_table(fit, q = q, floor = floor)
  rel_i <- colMeans(d$s_i^2 / (1 + d$s_i^2))

  Csum <- matrix(0, K, K)
  for (t in seq_len(T_)) Csum <- Csum + cor(matrix(d$F[t, , ], J, K))
  score_cor <- Csum / T_
  dimnames(score_cor) <- list(fac_ids, fac_ids)

  qs <- apply(counts, 2, quantile, probs = c(alpha / 2, 1 - alpha / 2))
  out <- data.frame(factor = fac_ids, stringsAsFactors = FALSE)
  out$flagged <- vapply(fac_ids, function(f)
    sum(fl$selected & fl$factor == f), integer(1))
  out$defining_modal <- vapply(seq_len(K), function(k) {
    tb <- table(counts[, k])
    as.integer(names(tb)[which.max(tb)])
  }, integer(1))
  out$defining_mean <- colMeans(counts)
  out$defining_lower <- qs[1, ]
  out$defining_upper <- qs[2, ]
  out$score_spread <- vapply(seq_len(K), function(k)
    mean(apply(matrix(d$F[, , k], T_, J), 2, sd)), numeric(1))
  out$reliability <- vapply(fac_ids, function(f) {
    idx <- which(fl$selected & fl$factor == f)
    if (length(idx)) mean(rel_i[idx]) else NA_real_
  }, numeric(1))
  rownames(out) <- NULL
  attr(out, "score_correlations") <- score_cor
  out
}


# the flag table both compute_flags() and claims() serve from
#' @keywords internal
#' @noRd
.flag_table <- function(fit, q, floor) {
  phi <- .phi_matrix(fit)
  K <- fit$brief$K; N <- fit$brief$N
  cand <- phi[, -(2 * K + 1), drop = FALSE]
  res <- fdr_select(as.vector(cand), q = q, floor = floor)
  selmat <- matrix(res$selected, nrow = N)
  best <- apply(cand, 1, which.max)
  fac_ids <- dimnames(fit$draws$sigma)[[2]]
  out <- data.frame(
    participant = rownames(phi),
    factor = fac_ids[ceiling(best / 2)],
    sign = ifelse(best %% 2 == 1, 1, -1),
    flag_prob = cand[cbind(seq_len(N), best)],
    unclassified_prob = phi[, 2 * K + 1],
    selected = rowSums(selmat) > 0,
    stringsAsFactors = FALSE
  )
  rownames(out) <- NULL
  attr(out, "expected_false") <- res$expected_false
  attr(out, "phi") <- phi
  out
}

#' Flag probabilities with an explicit unclassified state
#'
#' @description
#' For each participant, the posterior probability that the classical flag
#' rule fires on each signed factor, with the probability of remaining
#' unclassified alongside. Selected flags come from all signed
#' candidates by the posterior false-discovery rule at level `q`.
#'
#' @param fit A `bayesqm_fit`.
#' @param q Posterior expected false-discovery bound (default 0.05).
#' @param floor Minimum flag probability a candidate needs before it can
#'   be selected (default 0.5, so at most one signed flag per participant).
#'
#' @return A data frame with one row per participant: modal signed
#'   candidate (`factor`, `sign`), its probability `flag_prob`,
#'   `unclassified_prob`, and `selected`. The full probability matrix is
#'   attached as `attr(, "phi")` and the expected number of false
#'   selected flags as `attr(, "expected_false")`.
#'
#' @examples
#' compute_flags(demo_fit())
#'
#' @export
compute_flags <- function(fit, q = 0.05, floor = 0.5) {
  assert_bayesqm_fit(fit)
  out <- .flag_table(fit, q = q, floor = floor)
  thr <- 1.96 / sqrt(fit$brief$J)
  if (thr > 0.8)
    message(sprintf(paste0(
      "with J = %d statements the descriptive cut-off 1.96/sqrt(J) = %.2f ",
      "sits near the ceiling of the bounded loading scale, so flags can ",
      "rarely fire at this statement count"), fit$brief$J, thr))
  out
}


#' Statement scores with credible intervals
#'
#' @param fit A `bayesqm_fit`.
#' @param prob Credible-interval probability; defaults to the fit's.
#'
#' @return A data frame with one row per statement: `statement`, then
#'   `f{k}_zsc`, `f{k}_lower`, `f{k}_upper` per factor.
#'
#' @examples
#' compute_zscores(demo_fit())
#'
#' @export
compute_zscores <- function(fit, prob = NULL) {
  assert_bayesqm_fit(fit)
  prob <- if (is.null(prob)) fit$brief$prob else prob
  alpha <- 1 - prob
  Fd <- fit$draws$F
  m <- .summarize_draws(Fd, mean)
  lo <- .summarize_draws(Fd, quantile, probs = alpha / 2, names = FALSE)
  hi <- .summarize_draws(Fd, quantile, probs = 1 - alpha / 2, names = FALSE)
  out <- data.frame(statement = rownames(m), stringsAsFactors = FALSE)
  for (k in seq_len(ncol(m))) {
    fk <- colnames(m)[k]
    out[[paste0(fk, "_zsc")]] <- m[, k]
    out[[paste0(fk, "_lower")]] <- lo[, k]
    out[[paste0(fk, "_upper")]] <- hi[, k]
  }
  rownames(out) <- NULL
  out
}


#' Quota-respecting factor arrays
#'
#' @description
#' The reported array for each factor: statements sorted onto the design
#' grid by their posterior column probabilities (mean grid column,
#' tie-broken by posterior-mean score), which is quota-exact by
#' construction. When the \pkg{clue} package is installed, a footrule
#' assignment cross-check is computed and its disagreement rate attached.
#'
#' @param fit A `bayesqm_fit`.
#' @param negative Also return the negative-pole arrays (default `FALSE`);
#'   on a symmetric grid the mirror is exact.
#'
#' @return A data frame with one row per statement: `statement`, then
#'   `f{k}_grid` per factor (and `f{k}_grid_neg` when `negative = TRUE`).
#'   `attr(, "footrule_disagreement")` gives the share of cells where the
#'   footrule assignment differs (`NA` without \pkg{clue}).
#'
#' @examples
#' compute_factor_array(demo_fit())
#'
#' @export
compute_factor_array <- function(fit, negative = FALSE) {
  assert_bayesqm_fit(fit)
  distr <- fit$distribution
  J <- fit$brief$J; K <- fit$brief$K
  C <- length(distr)
  g <- .g_draws(fit)
  cbar <- apply(g, c(2, 3), mean)
  Fm <- .summarize_draws(fit$draws$F, mean)
  slots <- rep(seq_len(C), distr)
  Ahat <- matrix(NA_integer_, J, K)
  for (k in seq_len(K)) {
    o <- order(cbar[, k], Fm[, k])          # tie-break by posterior mean score
    Ahat[o, k] <- slots
  }

  fr <- NA_real_
  if (requireNamespace("clue", quietly = TRUE)) {
    Afr <- matrix(NA_integer_, J, K)
    for (k in seq_len(K)) {
      cost <- vapply(slots, function(a) colMeans(abs(g[, , k] - a)), numeric(J))
      Afr[, k] <- slots[clue::solve_LSAP(cost)]
    }
    fr <- mean(Afr != Ahat)
  }

  out <- data.frame(statement = dimnames(fit$draws$F)[[2]],
                    stringsAsFactors = FALSE)
  fac_ids <- dimnames(fit$draws$sigma)[[2]]
  certainty <- matrix(NA_real_, J, K,
                      dimnames = list(out$statement, fac_ids))
  for (k in seq_len(K)) {
    out[[paste0(fac_ids[k], "_grid")]] <- Ahat[, k]
    certainty[, k] <- vapply(seq_len(J), function(j)
      mean(g[, j, k] == Ahat[j, k]), numeric(1))
  }

  if (negative) {
    if (all(distr == rev(distr))) {
      for (k in seq_len(K))
        out[[paste0(fac_ids[k], "_grid_neg")]] <- (C + 1L) - Ahat[, k]
    } else {
      gn <- .g_draws(fit, negative = TRUE)
      cbn <- apply(gn, c(2, 3), mean)
      for (k in seq_len(K)) {
        An <- integer(J)
        o <- order(cbn[, k], -Fm[, k])
        An[o] <- slots
        out[[paste0(fac_ids[k], "_grid_neg")]] <- An
      }
    }
  }
  rownames(out) <- NULL
  attr(out, "footrule_disagreement") <- fr
  attr(out, "certainty") <- certainty
  out
}


# the verdict tables compute_qdc() and claims() serve from
#' @keywords internal
#' @noRd
.qdc_tables <- function(fit, q, cons_floor, prob = NULL) {
  ps <- .pair_stats(fit, prob = prob)
  J <- fit$brief$J; K <- fit$brief$K
  fac_ids <- dimnames(fit$draws$sigma)[[2]]
  stmt_ids <- dimnames(fit$draws$F)[[2]]

  dl <- fdr_select(as.vector(ps$pi_dist), q = q)
  dist_pub <- matrix(dl$selected, J, K)
  cl <- fdr_select(ps$pi_cons, q = q, floor = cons_floor)
  sl <- fdr_select(as.vector(ps$pi_pair), q = q)
  star_pub <- matrix(sl$selected, J, ncol(ps$pi_pair))
  sl99 <- fdr_select(as.vector(ps$pi_pair99), q = q)
  star99 <- star_pub & matrix(sl99$selected, J, ncol(ps$pi_pair))

  # column placements per draw give the on-grid counterpart per pair
  g <- .g_draws(fit)
  p_grid <- matrix(NA_real_, J, ncol(ps$pi_pair))
  for (p in seq_len(ncol(ps$pi_pair)))
    p_grid[, p] <- colMeans(abs(g[, , ps$pairs[1, p]] -
                                g[, , ps$pairs[2, p]]) >= 1)

  verdict <- character(J)
  for (j in seq_len(J)) {
    dk <- which(dist_pub[j, ])
    verdict[j] <-
      if (length(dk)) paste0("distinguishing (",
                             paste(fac_ids[dk], collapse = ", "), ")")
      else if (cl$selected[j]) "consensus"
      else "indeterminate"
  }

  qdc <- data.frame(statement = stmt_ids, stringsAsFactors = FALSE)
  for (k in seq_len(K))
    qdc[[paste0(fac_ids[k], "_dist_prob")]] <- ps$pi_dist[, k]
  qdc$consensus_prob <- ps$pi_cons
  qdc$verdict <- verdict
  rownames(qdc) <- NULL

  contrasts <- data.frame(
    statement = rep(stmt_ids, ncol(ps$pi_pair)),
    pair = rep(ps$pair_ids, each = J),
    median = as.vector(ps$d_med),
    lower = as.vector(ps$d_lo),
    upper = as.vector(ps$d_hi),
    exceed_prob = as.vector(ps$pi_pair),
    diff_column_prob = as.vector(p_grid),
    selected = as.vector(star_pub),
    stars = ifelse(as.vector(star99), "**",
                   ifelse(as.vector(star_pub), "*", "")),
    stringsAsFactors = FALSE
  )

  list(qdc = qdc, contrasts = contrasts, pair_stats = ps,
       dist_pub = dist_pub, cons_pub = cl$selected,
       expected_false = c(distinguishing = dl$expected_false,
                          consensus = cl$expected_false,
                          stars = sl$expected_false))
}

#' Distinguishing and consensus verdicts
#'
#' @description
#' The statement verdict table. Distinguishing-for-a-factor is the joint
#' event that every contrast touching that factor exceeds the posterior
#' critical difference `delta_kl` (computed from the posterior spread of
#' the score contrasts); consensus is the equivalence event that all
#' scores sit within one grid column ([delta_grid()]) of each other. Both
#' families are selected through the posterior false-discovery rule, and a
#' statement can be distinguishing, consensus, or indeterminate.
#'
#' @param fit A `bayesqm_fit` with `K >= 2`.
#' @param q Posterior expected false-discovery bound (default 0.05).
#' @param cons_floor Minimum consensus probability before a statement can
#'   be selected as consensus (default 0.95).
#' @param prob Credible-interval probability for the contrast intervals;
#'   defaults to the fit's. The critical difference itself keeps its
#'   z_0.975 definition regardless.
#'
#' @return A data frame with one row per statement: per-factor
#'   distinguishing probabilities, `consensus_prob`, and the `verdict`.
#'   Attributes: `delta_kl` and `delta_kl99` (per pair), `delta_grid`,
#'   `contrasts` (the per-pair contrast table with intervals, the
#'   probability `diff_column_prob` that the two viewpoints place the
#'   statement in different grid columns, and `stars`, `*` for selected
#'   claims and `**` for those that also clear the `z_0.995` critical
#'   difference at probability .99), and `expected_false` per family.
#'
#' @examples
#' compute_qdc(demo_fit())
#'
#' @export
compute_qdc <- function(fit, q = 0.05, cons_floor = 0.95, prob = NULL) {
  assert_bayesqm_fit(fit)
  qt <- .qdc_tables(fit, q = q, cons_floor = cons_floor, prob = prob)
  out <- qt$qdc
  attr(out, "delta_kl") <- qt$pair_stats$delta_kl
  attr(out, "delta_kl99") <- qt$pair_stats$delta_kl99
  attr(out, "delta_grid") <- qt$pair_stats$delta_grid
  attr(out, "contrasts") <- qt$contrasts
  attr(out, "expected_false") <- qt$expected_false
  out
}


#' Extreme-placement probabilities per statement and factor
#'
#' @description
#' The crib sheet: for each statement and factor, the posterior
#' probability of landing in the top or bottom grid column of that
#' factor's array, and of carrying the highest or lowest score across
#' factors.
#'
#' @param fit A `bayesqm_fit`.
#'
#' @return A long data frame: `statement`, `factor`, `p_top`, `p_bottom`,
#'   `p_highest`, `p_lowest`.
#'
#' @examples
#' head(crib_sheet(demo_fit()))
#'
#' @export
crib_sheet <- function(fit) {
  assert_bayesqm_fit(fit)
  d <- fit$draws
  T_ <- dim(d$F)[1]; J <- fit$brief$J; K <- fit$brief$K
  C <- length(fit$distribution)
  g <- .g_draws(fit)
  fac_ids <- dimnames(d$sigma)[[2]]
  stmt_ids <- dimnames(d$F)[[2]]
  slice <- function(k) matrix(d$F[, , k], T_, J)
  out <- vector("list", K)
  for (k in seq_len(K)) {
    others <- setdiff(seq_len(K), k)
    hi <- lo <- rep(NA_real_, J)
    if (length(others)) {
      mx <- Reduce(pmax, lapply(others, slice))
      mn <- Reduce(pmin, lapply(others, slice))
      hi <- colMeans(slice(k) > mx)
      lo <- colMeans(slice(k) < mn)
    }
    out[[k]] <- data.frame(
      statement = stmt_ids, factor = fac_ids[k],
      p_top = colMeans(g[, , k] == C),
      p_bottom = colMeans(g[, , k] == 1),
      p_highest = hi, p_lowest = lo,
      stringsAsFactors = FALSE
    )
  }
  out <- do.call(rbind, out)
  rownames(out) <- NULL
  out
}
