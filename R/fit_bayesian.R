# fit_bayesian.R
# The public fitting interface: strict forced-sort validation, the gated
# PX-Gibbs run, alignment, and warm-started continuation via extend().


# every column must obey the design quotas exactly; the exact likelihood is
# a statement about the sorting event the quotas define
#' @keywords internal
#' @noRd
.assert_forced_sorts <- function(Y, distribution) {
  C <- length(distribution)
  ok <- apply(Y, 2, function(y) all(tabulate(y, C) == distribution))
  if (all(ok)) return(invisible(TRUE))
  bad <- colnames(Y); if (is.null(bad)) bad <- paste0("P", seq_len(ncol(Y)))
  .bq_abort(paste0(
    "the exact rank-order likelihood requires forced sorts matching the ",
    "design grid (%s), and %d sort%s do%s not: %s. Free-distribution ",
    "sorts are outside this model's scope."),
    paste(distribution, collapse = "-"), sum(!ok),
    if (sum(!ok) > 1) "s" else "", if (sum(!ok) > 1) "" else "es",
    paste(bad[!ok], collapse = ", "))
}

# 0.1.0 fitting arguments, caught by name with a migration pointer. The
# caller passes the ORIGINAL call names, because R's partial matching would
# otherwise bind `iter` to `iterations` before the dots ever see it.
#' @keywords internal
#' @noRd
.check_removed_args <- function(supplied) {
  removed <- c(stan_dir = "the Stan model is gone; nothing replaces this",
               robust = "the partition likelihood has no error family to choose",
               nu = "the partition likelihood has no error family to choose",
               chains = "the sampler runs one gated chain; see `iterations`",
               iter = "use `iterations`",
               warmup = "use `burn`",
               adapt_delta = "there is no NUTS tuning; the sampler is Gibbs",
               max_draws = "use `thin`",
               prior_loading_scale = "use `sigma_scale`",
               prior_sigma_scale = "use `sigma_scale`",
               prior_nu_alpha = "the partition likelihood has no nu",
               prior_nu_beta = "the partition likelihood has no nu",
               use_half_cauchy = "the loading-scale prior is half-normal",
               delta = "the critical difference is computed by compute_qdc()")
  hit <- intersect(supplied, names(removed))
  if (length(hit))
    .bq_abort(paste0(
      "`%s` belonged to the 0.1.0 score-scale model, which bayesqm 0.2.0 ",
      "replaces with the exact partition likelihood: %s."),
      hit[1], removed[hit[1]])
}


#' Fit the exact partition-likelihood model to forced Q sorts
#'
#' @description
#' Models each completed sort as a forced ordered partition of the
#' statements and samples the posterior of the latent factor model by a
#' parameter-expanded Gibbs sampler. Convergence is gated on
#' rotation-invariant person spreads (rank-normalized split-R-hat and
#' bulk/tail effective sample size); a chain failing the gate is
#' warm-extended at successive doublings up to `max_iterations`. Draws are
#' aligned by MatchAlign with a polarity canon, so defining sorts load
#' positively.
#'
#' @param Y A `qsort_data` object, or a `J x N` numeric matrix of grid
#'   positions with statements as rows and participants as columns. Every
#'   sort must obey the forced distribution exactly.
#' @param K Integer number of factors.
#' @param iterations First-check chain length (default 12000, the settings
#'   frozen in the accompanying paper).
#' @param burn Burn-in iterations (default 2000), paid once; extensions
#'   continue the chain.
#' @param thin Keep every `thin`-th post-burn draw (default 5).
#' @param max_iterations Total-iteration cap for the gated extension ladder
#'   (default 48000).
#' @param seed Optional integer seed; fits are exactly reproducible given
#'   the seed.
#' @param sigma_scale Half-normal prior scale for the per-factor loading
#'   scales (default 1).
#' @param rhat_max,ess_min Gate thresholds (defaults 1.01 and 400).
#' @param prob Credible-interval probability stored on the fit
#'   (default 0.95).
#' @param keep_raw Keep the pre-alignment draws on the fit (default
#'   `TRUE`); required by [extend()] and by realignment under a different
#'   pivot.
#' @param pivot Optional draw index for the alignment pivot; `NULL` (the
#'   default) uses the median-condition-number rule.
#' @param quiet Suppress progress messages (default `FALSE`).
#' @param ... Unused; supplying a removed 0.1.0 argument gives a migration
#'   error.
#'
#' @return A `bayesqm_fit` carrying aligned draws, the gate report, the
#'   alignment record, and (when `keep_raw = TRUE`) the raw draws and
#'   sampler state.
#'
#' @examples
#' fit <- demo_fit()
#' fit
#'
#' @export
fit_bayesian <- function(Y, K, iterations = 12000, burn = 2000, thin = 5,
                         max_iterations = 48000, seed = NULL,
                         sigma_scale = 1, rhat_max = 1.01, ess_min = 400,
                         prob = 0.95, keep_raw = TRUE, pivot = NULL,
                         quiet = FALSE, ...) {
  cl <- match.call()
  .check_removed_args(names(as.list(sys.call()))[-1])
  dots <- list(...)
  if (length(dots))
    .bq_abort("unused argument `%s`.", names(dots)[1])

  if (inherits(Y, "qsort_data")) {
    distribution <- Y$distribution
    Y <- Y$Y
  } else {
    Y <- as.matrix(Y)
    distribution <- infer_distribution(Y)
  }
  if (is.null(distribution) || !length(distribution))
    .bq_abort("no forced distribution: supply qsort_data with a distribution.")
  if (!is.numeric(Y))
    .bq_abort(paste0("Y is not numeric (first column class: %s); drop ID or ",
                     "text columns, or import with read_qsort()/qsort_data()."),
              class(Y[, 1])[1])
  if (anyNA(Y))
    .bq_abort("Y has %d missing entr%s; the partition likelihood needs complete sorts.",
              sum(is.na(Y)), if (sum(is.na(Y)) > 1) "ies" else "y")
  # zero-count columns (some import patterns keep interior zeros) hold no
  # statements by definition; dropping them is a monotone relabeling, and
  # the recode below maps whatever labels the sorts use onto what remains
  if (any(distribution == 0)) {
    if (!quiet)
      message(sprintf("dropping %d zero-count grid column(s) from the distribution",
                      sum(distribution == 0)))
    distribution <- distribution[distribution != 0]
  }
  # printed grid labels (-4..+4, 0-based, or any monotone scheme) are
  # conventional; recode them onto categories 1..C, which changes nothing
  C <- length(distribution)
  vals <- sort(unique(as.vector(Y)))
  if (!all(vals %in% seq_len(C))) {
    if (length(vals) == C) {
      Y <- matrix(match(Y, vals), nrow(Y), ncol(Y), dimnames = dimnames(Y))
      if (!quiet)
        message(sprintf("grid labels %s..%s recoded onto categories 1..%d (a monotone relabeling; the sorts are unchanged)",
                        vals[1], vals[C], C))
    } else {
      .bq_abort(paste0("the sorts use %d distinct values (%s, ...) but the ",
                       "design grid has %d columns; supply sorts on the ",
                       "design's ordered categories."),
                length(vals), paste(utils::head(vals, 4), collapse = ", "), C)
    }
  }
  .assert_forced_sorts(Y, distribution)

  N <- ncol(Y); J <- nrow(Y)
  if (length(K) != 1 || is.na(K) || K != round(K))
    .bq_abort("K must be a single whole number.")
  K <- as.integer(K)
  if (K < 1 || K >= N)
    .bq_abort("K must be at least 1 and smaller than the number of participants (%d).", N)
  if (K >= J)
    .bq_abort("K must be smaller than the number of statements (%d); a %d-statement panel cannot support %d factors.",
              J, J, K)
  for (arg in c("iterations", "burn", "thin", "max_iterations")) {
    v <- get(arg)
    if (length(v) != 1 || is.na(v) || v != round(v) || v < 0)
      .bq_abort("`%s` must be a single non-negative whole number.", arg)
  }
  if (thin < 1) .bq_abort("`thin` must be at least 1.")
  if (iterations <= burn)
    .bq_abort("`iterations` (%d) must exceed `burn` (%d).", iterations, burn)
  if (max_iterations < iterations)
    .bq_abort("`max_iterations` must be at least `iterations`.")
  if (max_iterations >= .Machine$integer.max / 2)
    .bq_abort("`max_iterations` is beyond any sane budget.")
  if ((iterations - burn) %% thin != 0)
    .bq_abort("(iterations - burn) must be a multiple of thin, so the keep grid stays phase-continuous under extension.")

  raw <- fit_partition_gated(t(Y), distribution, K, seed = seed,
                             sigma_scale = sigma_scale,
                             n_iter = iterations, burn = burn, thin = thin,
                             n_max = max_iterations, rhat_max = rhat_max,
                             ess_min = ess_min, quiet = quiet)
  gate <- list(converged = raw$converged, extended = raw$extended,
               iterations = raw$iters, floor = as.integer(iterations),
               cap = as.integer(max_iterations),
               rhat = raw$rhat, ess_bulk = raw$ess, ess_tail = raw$ess_tail,
               rhat_max = rhat_max, ess_min = ess_min)
  if (!gate$converged)
    warning(sprintf(paste0(
      "[bayesqm] the convergence gate was not met at the %d-iteration cap ",
      "(max Rhat %.3f, min ESS %.0f); summaries remain available but read ",
      "them cautiously, and consider extend()."),
      gate$cap, gate$rhat, min(gate$ess_bulk, gate$ess_tail)), call. = FALSE)

  keep_fields <- c("F", "Lambda", "sigma", "s_i")
  raw_draws <- if (keep_raw) raw[keep_fields] else NULL
  pp <- postprocess(raw, pivot = pivot)

  new_bayesqm_fit(
    call = cl, Y = Y, distribution = distribution, K = K,
    draws = pp[keep_fields], draws_raw = raw_draws,
    state = if (keep_raw) raw$state else NULL,
    gate = gate,
    align = list(pivot = pp$pivot, congruence = pp$congruence),
    prob = prob, seed = seed,
    settings = list(burn = as.integer(burn), thin = as.integer(thin),
                    sigma_scale = sigma_scale)
  )
}


#' Continue sampling a fitted chain
#'
#' @description
#' Warm-extends the fitted chain by further iterations and re-runs the
#' convergence gate and the alignment on the grown draw set. The extension
#' restores the sampler's saved random-number state, so the result is
#' draw-for-draw identical to having run one longer chain, whatever
#' happened in the session in between.
#'
#' @param fit A `bayesqm_fit` created with `keep_raw = TRUE`.
#' @param iterations Additional iterations; `NULL` (the default) doubles
#'   the chain. Must be a multiple of the fit's `thin`.
#' @param pivot,quiet As in [fit_bayesian()].
#'
#' @return The extended `bayesqm_fit`.
#'
#' @export
extend <- function(fit, iterations = NULL, pivot = NULL, quiet = FALSE) {
  assert_bayesqm_fit(fit)
  if (is.null(fit$draws_raw) || is.null(fit$state))
    .bq_abort("extend() needs the raw draws and sampler state; refit with keep_raw = TRUE.")
  b <- fit$brief
  thin <- b$settings$thin
  if (is.null(iterations)) iterations <- fit$gate$iterations
  if (iterations %% thin != 0)
    .bq_abort("iterations must be a multiple of thin (%d).", thin)

  raw <- c(fit$draws_raw,
           list(state = fit$state, N = b$N, J = b$J, K = b$K,
                distr = fit$distribution))
  ext <- fit_partition(t(fit$dataset), fit$distribution, b$K,
                       n_iter = iterations, burn = 0, thin = thin,
                       sigma_scale = b$settings$sigma_scale,
                       state = fit$state)
  raw <- grow_fit(raw, ext)
  cv <- check_conv(raw, fit$gate$rhat_max, fit$gate$ess_min)

  gate <- fit$gate
  gate$converged <- cv$ok
  gate$extended <- TRUE
  gate$iterations <- gate$iterations + as.integer(iterations)
  gate$rhat <- cv$rhat; gate$ess_bulk <- cv$ess; gate$ess_tail <- cv$ess_tail
  if (!quiet)
    message(sprintf("extended to %d iterations; gate %s (max Rhat %.3f, min ESS %.0f)",
                    gate$iterations, if (cv$ok) "passed" else "still not met",
                    cv$rhat, min(cv$ess, cv$ess_tail)))

  if (!is.null(fit$align$rotated))
    warning("[bayesqm] extension re-aligns the grown chain canonically; the ",
            "judgmental rotation is not carried over - re-apply ",
            "rotate_factors() (or flip_factor()) on the extended fit.",
            call. = FALSE)

  keep_fields <- c("F", "Lambda", "sigma", "s_i")
  raw_draws <- raw[keep_fields]
  pp <- postprocess(raw, pivot = pivot)

  new_bayesqm_fit(
    call = b$call, Y = fit$dataset, distribution = fit$distribution,
    K = b$K, draws = pp[keep_fields], draws_raw = raw_draws,
    state = raw$state, gate = gate,
    align = list(pivot = pp$pivot, congruence = pp$congruence),
    prob = b$prob, seed = b$seed, settings = b$settings,
    fac_ids = dimnames(fit$draws$sigma)[[2]]
  )
}
