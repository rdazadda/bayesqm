# ladder.R
# The two-signal choice of K: fit a ladder of K, judge each rung on
# posterior-predictive adequacy (extra-factor check in the central band,
# no mutual unspanned cluster) and on parsimony (every factor supported:
# at least two selected flags and one selected distinguishing listing),
# and select the smallest adequate K with all factors supported.
# select_k() reads only stored per-rung summaries, so it re-runs at
# another q without refitting.


#' Fit the model over a ladder of K
#'
#' @description
#' Fits [fit_bayesian()] at each K in the ladder and stores, per rung, the
#' fit together with the adequacy and support evidence that
#' [select_k()] consumes. Expect roughly one full fit's runtime per rung;
#' a message up front says how many rungs are coming.
#'
#' @param Y As in [fit_bayesian()].
#' @param K_max Largest K to fit. `NULL` (default) uses
#'   `min(6, floor(N / 3))`, capped at 3 when `N <= 12` — with a dozen
#'   sorts or fewer, the data cannot formally discriminate adjacent K.
#' @param K_min Smallest K to fit (default 2).
#' @param q False-discovery level for the support evidence stored on
#'   each rung (default 0.05); [select_k()] can re-select at another q.
#' @param screen_draws,screen_mixes Budget for the per-rung person
#'   check (defaults 30 and 60; the cluster signal needs no more).
#' @param quiet Suppress per-rung messages (default `FALSE`).
#' @param ... Passed to [fit_bayesian()] (iterations, seed, ...).
#'
#' @return A `bayesqm_ladder`: the per-rung fits and evidence.
#'
#' @export
fit_ladder <- function(Y, K_max = NULL, K_min = 2, q = 0.05,
                       screen_draws = 30, screen_mixes = 60,
                       quiet = FALSE, ...) {
  qd <- if (inherits(Y, "qsort_data")) Y
        else qsort_data(as.matrix(Y), validate = FALSE)
  N <- ncol(qd$Y)
  if (is.null(K_max))
    K_max <- if (N <= 12) min(3, N - 1) else min(6, floor(N / 3))
  ks <- seq.int(K_min, K_max)
  if (!length(ks) || K_max < K_min)
    .bq_abort("empty ladder: K_max (%d) is below K_min (%d).", K_max, K_min)
  if (!quiet)
    message(sprintf(
      "fitting %d rungs (K = %s); expect roughly one fit's runtime per rung",
      length(ks), paste(range(ks), collapse = "..")))

  rungs <- vector("list", length(ks))
  for (i in seq_along(ks)) {
    K <- ks[i]
    if (!quiet) message(sprintf("K = %d ...", K))
    fit <- fit_bayesian(qd, K = K, quiet = TRUE, ...)
    pc <- check_persons(fit, draws = screen_draws, mixes = screen_mixes)
    ck <- check_fit(fit, draws = 50)
    cl <- claims(fit, q = q)
    fac_ids <- dimnames(fit$draws$sigma)[[2]]
    supported <- vapply(fac_ids, function(f)
      sum(cl$flags$factor == f) >= 2 &&
        any(cl$distinguishing$factor == f), logical(1))
    rungs[[i]] <- list(
      K = K, fit = fit,
      t1b = ck$extra_factor$percentile,
      cluster = unspanned_cluster(pc),
      supported = supported,
      converged = fit$gate$converged,
      flags = cl$flags, distinguishing = cl$distinguishing
    )
  }
  structure(list(K = ks, rungs = rungs, q = q, N = N),
            class = "bayesqm_ladder")
}


#' Choose K by the two-signal rule
#'
#' @description
#' Signal one is posterior-predictive adequacy: the extra-factor check
#' sits inside the central band and the person check shows no mutual
#' unspanned cluster. Signal two is parsimony: every factor is supported,
#' meaning at least two selected flags and at least one selected
#' distinguishing listing. The selection is the smallest adequate K with
#' all factors supported. When no factor is supported at any rung the
#' verdict separates two opposite situations: a panel sharing nothing (no
#' factor ever attracts two flags) and a panel so unanimous that flags
#' abound but no statement distinguishes any pair — a single shared
#' viewpoint, reported as such. When adequacy and support never coincide,
#' both candidate solutions are reported rather than forcing a winner.
#'
#' @param ladder A `bayesqm_ladder`.
#' @param q Re-select the support evidence at this level; `NULL` (the
#'   default) keeps the level the ladder stored.
#' @param band Central adequacy band for the extra-factor percentile
#'   (default `c(0.05, 0.95)`).
#'
#' @return A `bayesqm_selection` with the verdict, the per-rung evidence
#'   table, and the selected `K` (or `NA`).
#'
#' @export
select_k <- function(ladder, q = NULL, band = c(0.05, 0.95)) {
  if (!inherits(ladder, "bayesqm_ladder"))
    .bq_abort("`ladder` must come from fit_ladder().")
  rungs <- ladder$rungs
  if (!is.null(q) && q != ladder$q) {
    for (i in seq_along(rungs)) {
      cl <- claims(rungs[[i]]$fit, q = q)
      fac_ids <- dimnames(rungs[[i]]$fit$draws$sigma)[[2]]
      rungs[[i]]$flags <- cl$flags
      rungs[[i]]$distinguishing <- cl$distinguishing
      rungs[[i]]$supported <- vapply(fac_ids, function(f)
        sum(cl$flags$factor == f) >= 2 &&
          any(cl$distinguishing$factor == f), logical(1))
    }
  }

  # per-factor evidence behind every support verdict, for the display
  detail <- do.call(rbind, lapply(rungs, function(r) {
    fac_ids <- dimnames(r$fit$draws$sigma)[[2]]
    data.frame(
      K = r$K, factor = seq_along(fac_ids),
      flags = vapply(fac_ids, function(f)
        sum(r$flags$factor == f), integer(1)),
      has_dist = vapply(fac_ids, function(f)
        any(r$distinguishing$factor == f), logical(1)),
      supported = r$supported, row.names = NULL
    )
  }))

  tab <- data.frame(
    K = ladder$K,
    converged = vapply(rungs, function(r) r$converged, logical(1)),
    extra_factor = vapply(rungs, function(r) r$t1b, numeric(1)),
    cluster = vapply(rungs, function(r) r$cluster, logical(1)),
    adequate = NA, factors_supported = vapply(rungs, function(r)
      sum(r$supported), integer(1)),
    all_supported = vapply(rungs, function(r) all(r$supported), logical(1))
  )
  tab$adequate <- tab$extra_factor >= band[1] & tab$extra_factor <= band[2] &
    !tab$cluster

  sel <- which(tab$adequate & tab$all_supported)
  K_star <- if (length(sel)) ladder$K[min(sel)] else NA_integer_

  verdict <-
    if (!any(unlist(lapply(rungs, function(r) r$supported)))) {
      # nothing supported can mean two opposite things: a panel sharing
      # nothing, or a panel so unanimous that no statement distinguishes
      # any pair of factors
      if (any(detail$flags >= 2) && !any(detail$has_dist)) "single_viewpoint"
      else "no_shared_structure"
    }
    else if (!is.na(K_star)) "selected"
    else if (any(tab$adequate) && any(tab$all_supported)) "tension"
    else if (any(tab$adequate)) "adequate_but_unsupported"
    else "no_adequate_rung"

  structure(
    list(K = K_star, verdict = verdict, table = tab, detail = detail,
         band = band, q = if (is.null(q)) ladder$q else q),
    class = "bayesqm_selection"
  )
}

#' @export
print.bayesqm_selection <- function(x, ...) {
  cat(sprintf("Choice of K, two-signal rule (q = %.2f, band %.2f-%.2f):\n",
              x$q, x$band[1], x$band[2]))
  print(x$table, digits = 2, row.names = FALSE)
  msg <- switch(x$verdict,
    selected = sprintf("selected K = %d: the smallest adequate rung with every factor supported.", x$K),
    single_viewpoint = "factors attract flags but no statement distinguishes any pair: the panel shares a single viewpoint. Report the one-factor solution (fit_bayesian with K = 1).",
    no_shared_structure = "no factor is supported at any rung: the data show no shared structure to factor.",
    tension = "adequacy and support never coincide; report both candidate solutions rather than forcing one.",
    adequate_but_unsupported = "adequate rungs exist but some factor is never supported there; the parsimony rule withholds a selection.",
    no_adequate_rung = "no rung passes the adequacy signal; look at the extra-factor percentiles and the person check."
  )
  cat("  ", msg, "\n", sep = "")
  invisible(x)
}


#' PSIS-LOO across the ladder, as directional corroboration
#'
#' @description
#' Person-level GHK log-likelihoods per rung, fed to PSIS-LOO. Reported as
#' directional corroboration only: with typical Q panels (N well below
#' 100), differences in expected log predictive density between adjacent K
#' have unreliable standard errors. The GHK seeds are common across rungs,
#' so comparisons are common-random-number paired.
#'
#' @param ladder A `bayesqm_ladder`.
#' @param draws,R As in [loglik_person()].
#'
#' @return A data frame: `K`, `elpd_loo`, `se`, `max_pareto_k`.
#'
#' @export
loo_ladder <- function(ladder, draws = 100, R = 64) {
  if (!inherits(ladder, "bayesqm_ladder"))
    .bq_abort("`ladder` must come from fit_ladder().")
  if (!requireNamespace("loo", quietly = TRUE))
    .bq_abort("loo_ladder() needs the loo package.")
  out <- lapply(ladder$rungs, function(r) {
    ll <- loglik_person(r$fit, draws = draws, R = R, seed = 1)
    lo <- suppressWarnings(loo::loo(ll))
    data.frame(K = r$K,
               elpd_loo = lo$estimates["elpd_loo", "Estimate"],
               se = lo$estimates["elpd_loo", "SE"],
               max_pareto_k = max(loo::pareto_k_values(lo)))
  })
  out <- do.call(rbind, out)
  message("directional corroboration only: elpd differences at N below ~100 have unreliable standard errors")
  out
}
