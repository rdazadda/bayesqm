# estimation.R
# Bayesian Q-factor analysis (Stan + MatchAlign + LOO)


#' Fit a Bayesian Q-methodology factor model
#'
#' @description
#' Fits the low-rank Bayesian factor model to Q-sort data. Samples the
#' posterior with Stan (via \pkg{cmdstanr} or \pkg{rstan}), resolves
#' rotational ambiguity with MatchAlign, and returns a classed
#' `bayesqm_fit` object carrying posterior-mean loadings and factor
#' scores, credible intervals, raw draws, LOO, PPC, and diagnostics.
#'
#' @param Y Either a `qsort_data` object or a `J x N` numeric matrix with
#'   statements as rows and participants as columns.
#' @param K Integer number of factors to extract.
#' @param stan_dir Directory containing `stan/factor_model.stan`. `NULL`
#'   (the default) uses the copy shipped in `inst/stan/`.
#' @param robust Logical; `TRUE` uses a Student-t likelihood, `FALSE`
#'   uses Normal.
#' @param nu Either `"estimate"` (default) to sample the Student-t
#'   degrees of freedom, or a numeric value (e.g. `5`, `Inf`) to fix it.
#' @param chains,iter,warmup NUTS sampler settings.
#' @param seed Optional integer seed for reproducibility.
#' @param adapt_delta NUTS adapt_delta target (default 0.90).
#' @param max_draws Thin post-warmup draws to at most this many before
#'   MatchAlign (default 2000).
#' @param prior_loading_scale,prior_sigma_scale,prior_nu_alpha,prior_nu_beta,use_half_cauchy
#'   Prior hyperparameters (see the Stan model for parameterization).
#' @param prob Credible-interval probability stored on the fit (default 0.95).
#' @param delta Substantive viewpoint separation for the
#'   distinguishing/consensus probabilities. If `NULL` (default) it is
#'   computed as the reliability-adjusted critical difference
#'   ([critical_delta()]); pass a numeric value to override, or use
#'   [suggest_delta()] as an alternative.
#'
#' @return A `bayesqm_fit` object. See [bayesqm-fit-methods] for `print()`
#'   and `summary()`, and [coef.bayesqm_fit()] for the standard R
#'   accessors.
#'
#' @references
#' Poworoznek et al. (2025). Efficiently Resolving Rotational Ambiguity in
#'   Bayesian Matrix Sampling with Matching. *Bayesian Analysis*.
#'
#' @examples
#' \donttest{
#' # Needs a working Stan backend; skipped when cmdstanr/CmdStan is absent.
#' has_stan <- requireNamespace("cmdstanr", quietly = TRUE) &&
#'   !inherits(try(cmdstanr::cmdstan_path(), silent = TRUE), "try-error")
#' if (has_stan) {
#'   sim <- generate_data(N = 8, J = 12, K = 2, seed = 1)
#'   fit <- fit_bayesian(sim$Y, K = 2, chains = 1, iter = 600, warmup = 300)
#'   summary(fit)
#' }
#' }
#'
#' @export
fit_bayesian <- function(Y, K, stan_dir = NULL, robust = TRUE, nu = "estimate",
                         chains = 4, iter = 2000, warmup = 1000,
                         seed = NULL, adapt_delta = 0.90, max_draws = 2000,
                         prior_loading_scale = 1.0, prior_sigma_scale = 1.0,
                         prior_nu_alpha = 2.0, prior_nu_beta = 0.1,
                         use_half_cauchy = FALSE, prob = 0.95,
                         delta = NULL) {
  cl <- match.call()
  if (inherits(Y, "qsort_data")) {
    distribution <- Y$distribution
    Y <- Y$Y
  } else {
    distribution <- infer_distribution(Y)
  }
  N <- ncol(Y); J <- nrow(Y)

  if (is.character(nu) && nu == "estimate") {
    fix_nu <- 0L; nu_fixed <- 5.0
  } else {
    fix_nu <- 1L
    nu_fixed <- if (is.infinite(nu)) 200.0 else max(2.0, as.numeric(nu))
  }

  stan_file <- if (is.null(stan_dir)) {
    sf <- system.file("stan", "factor_model.stan", package = "bayesqm")
    if (!nzchar(sf))
      stop("Cannot locate Stan model. Install bayesqm or pass stan_dir explicitly.")
    sf
  } else {
    file.path(stan_dir, "stan", "factor_model.stan")
  }
  stopifnot(file.exists(stan_file))

  sdata <- list(N = N, M = J, K = K, Y = Y,
                use_student_t = as.integer(robust), fix_nu = fix_nu,
                prior_loading_scale = prior_loading_scale,
                prior_sigma_scale  = prior_sigma_scale,
                prior_nu_alpha     = prior_nu_alpha,
                prior_nu_beta      = prior_nu_beta,
                nu_fixed = nu_fixed,
                use_half_cauchy = as.integer(use_half_cauchy))

  be <- detect_backend()
  fit <- if (be == "cmdstanr")
    sample_cmdstanr(stan_file, sdata, chains, iter, warmup, seed, adapt_delta)
  else
    sample_rstan(stan_file, sdata, chains, iter, warmup, seed, adapt_delta)

  draws <- extract_draws(fit, N, J, K, be)

  # Thin so MatchAlign and the posterior summaries operate on a consistent draw set.
  nt <- dim(draws$Lambda)[1]
  if (nt == 0) stop("Backend returned zero post-warmup draws.")
  if (!is.null(max_draws) && nt > max_draws) {
    keep <- seq(1, nt, by = ceiling(nt / max_draws))
    draws$Lambda <- draws$Lambda[keep, , , drop = FALSE]
    draws$Fmat   <- draws$Fmat[keep, , , drop = FALSE]
    draws$nu     <- draws$nu[keep]
    draws$sigma  <- draws$sigma[keep]
    draws$tau    <- draws$tau[keep]
  }

  aln <- matchalign(draws$Lambda, draws$Fmat)
  Lhat <- .summarize_draws(aln$Lambda, mean)
  Lmed <- .summarize_draws(aln$Lambda, median)
  alpha <- 1 - prob
  ci_lo <- .summarize_draws(aln$Lambda, quantile, probs =     alpha / 2, names = FALSE)
  ci_hi <- .summarize_draws(aln$Lambda, quantile, probs = 1 - alpha / 2, names = FALSE)

  loo_el <- tryCatch(compute_loo(fit, be), error = function(e) NULL)
  loo_ps <- tryCatch(compute_loo_person(fit, be), error = function(e) NULL)
  diag   <- tryCatch(get_diagnostics(fit, be), error = function(e) list())
  ppc    <- tryCatch(compute_ppc(fit, Y, be), error = function(e) list())

  priors <- list(
    loading_scale   = prior_loading_scale,
    sigma_scale     = prior_sigma_scale,
    nu_alpha        = prior_nu_alpha,
    nu_beta         = prior_nu_beta,
    use_half_cauchy = use_half_cauchy
  )

  new_bayesqm_fit(
    call         = cl,
    Y            = Y,
    K            = K,
    distribution = distribution,
    delta        = delta,
    prob         = prob,
    robust       = robust,
    nu           = nu,
    chains       = chains,
    iter         = iter,
    warmup       = warmup,
    backend      = be,
    priors       = priors,
    Lhat         = Lhat,
    Lmed         = Lmed,
    ci_lo        = ci_lo,
    ci_hi        = ci_hi,
    Lambda_draws = aln$Lambda,
    F_draws      = aln$Fmat,
    align_info   = list(congruence = aln$congruence, pivot = aln$pivot),
    hyperparams  = list(nu = draws$nu, sigma = draws$sigma, tau = draws$tau),
    loo_el       = loo_el,
    loo_ps       = loo_ps,
    diag         = diag,
    ppc          = ppc
  )
}


#' @keywords internal
#' @noRd
detect_backend <- function() {
  if (requireNamespace("cmdstanr", quietly = TRUE)) {
    ok <- tryCatch({ cmdstanr::cmdstan_path(); TRUE }, error = function(e) FALSE)
    if (ok) return("cmdstanr")
  }
  if (requireNamespace("rstan", quietly = TRUE)) return("rstan")
  stop("Need cmdstanr or rstan.")
}

#' @keywords internal
#' @noRd
sample_cmdstanr <- function(sf, data, chains, iter, warmup, seed, ad) {
  cache <- file.path(tempdir(), "stan_cache")
  if (!dir.exists(cache)) dir.create(cache, recursive = TRUE)
  ext <- if (.Platform$OS.type == "windows") ".exe" else ""
  exe <- file.path(cache, paste0(tools::file_path_sans_ext(basename(sf)), ext))
  mod <- cmdstanr::cmdstan_model(sf, exe_file = exe)

  # Isolate sampler CSVs in a per-call directory under tempdir(). The default
  # output_dir is tempdir() itself; on Windows that namespace can be touched
  # by other processes (snapshot tests, antivirus, GC) between sampling and
  # the post-hoc CSV read, leading to spurious "file does not exist" errors.
  out_dir <- tempfile("bq_stan_")
  dir.create(out_dir, recursive = TRUE)

  mod$sample(data = data, chains = chains,
             parallel_chains = min(chains, max(1, parallel::detectCores() - 1)),
             iter_warmup = warmup, iter_sampling = iter - warmup,
             seed = seed, refresh = max(100, (iter - warmup) %/% 5),
             show_messages = FALSE, adapt_delta = ad, max_treedepth = 12,
             output_dir = out_dir)
}

#' @keywords internal
#' @noRd
sample_rstan <- function(sf, data, chains, iter, warmup, seed, ad) {
  rstan::stan(file = sf, data = data, chains = chains,
              iter = iter, warmup = warmup,
              cores = min(chains, max(1, parallel::detectCores() - 1)),
              seed = seed, refresh = max(100, (iter - warmup) %/% 5),
              control = list(adapt_delta = ad, max_treedepth = 12))
}

# Pull a Stan-indexed parameter (e.g. "Lambda[i,k]") out of a draws data
# frame and reshape it into a [draws, dim_lengths[1], dim_lengths[2]] array.
# Returns NULL if no columns of that parameter are present in `dd`.
#' @keywords internal
#' @noRd
extract_indexed <- function(dd, name, dim_lengths) {
  cols <- grep(paste0("^", name, "\\["), names(dd), value = TRUE)
  if (length(cols) == 0L) return(NULL)
  m <- regmatches(cols, regexec(paste0(name, "\\[(\\d+),(\\d+)\\]"), cols))
  ix <- do.call(rbind, lapply(m, function(x) as.integer(x[2:3])))
  out <- array(NA_real_, c(nrow(dd), dim_lengths))
  for (j in seq_along(cols))
    out[, ix[j, 1], ix[j, 2]] <- dd[[cols[j]]]
  out
}


#' @keywords internal
#' @noRd
extract_draws <- function(fit, N, J, K, be) {
  if (be == "cmdstanr") {
    dd <- as.data.frame(fit$draws(format = "df"))
    nd <- nrow(dd)
    Lambda <- extract_indexed(dd, "Lambda", c(N, K))
    Fmat   <- extract_indexed(dd, "F",      c(J, K))
    if (is.null(Lambda)) Lambda <- array(NA_real_, c(nd, N, K))
    if (is.null(Fmat))   Fmat   <- array(NA_real_, c(nd, J, K))
    nu    <- if ("nu" %in% names(dd)) dd[["nu"]] else rep(NA_real_, nd)
    sigma <- if ("sigma" %in% names(dd)) dd[["sigma"]] else rep(NA_real_, nd)
    tau   <- if ("tau" %in% names(dd)) dd[["tau"]] else rep(NA_real_, nd)
  } else {
    post <- rstan::extract(fit)
    Lambda <- post$Lambda
    Fmat <- post[["F"]]
    nd <- dim(Lambda)[1]
    nu    <- if ("nu" %in% names(post)) post$nu else rep(NA_real_, nd)
    sigma <- if ("sigma" %in% names(post)) post$sigma else rep(NA_real_, nd)
    tau   <- if ("tau" %in% names(post)) post$tau else rep(NA_real_, nd)
  }
  list(Lambda = Lambda, Fmat = Fmat, nu = nu, sigma = sigma, tau = tau)
}

#' @keywords internal
#' @noRd
compute_loo <- function(fit, be) {
  if (!requireNamespace("loo", quietly = TRUE)) return(NULL)
  ll <- if (be == "cmdstanr") fit$draws("log_lik", format = "array")
        else loo::extract_log_lik(fit, parameter_name = "log_lik")
  loo::loo(ll)
}

#' @keywords internal
#' @noRd
compute_loo_person <- function(fit, be) {
  if (!requireNamespace("loo", quietly = TRUE)) return(NULL)
  ll <- if (be == "cmdstanr") fit$draws("log_lik_person", format = "matrix")
        else as.matrix(fit, pars = "log_lik_person")
  loo::loo(ll)
}

#' @keywords internal
#' @noRd
get_diagnostics <- function(fit, be) {
  out <- list()
  smin <- function(x) if (!length(x) || all(is.na(x))) NA_real_ else min(x, na.rm = TRUE)
  smax <- function(x) if (!length(x) || all(is.na(x))) NA_real_ else max(x, na.rm = TRUE)

  # only identified params; Lambda/F have rotational ambiguity
  idp <- c("log_sigma", "tau", "sigma",
           "nu_raw", "nu", "lp__", "log_lik", "log_lik_person")

  if (be == "cmdstanr") {
    ds <- fit$diagnostic_summary()
    out$divergences <- sum(ds$num_divergent)
    sm <- fit$summary()
    keep <- gsub("\\[.*", "", sm$variable) %in% idp
    out$rhat_max <- smax(sm$rhat[keep])
    out$ess_bulk <- smin(sm$ess_bulk[keep])
    out$ess_tail <- smin(sm$ess_tail[keep])
  } else {
    sm <- rstan::summary(fit)$summary
    keep <- gsub("\\[.*", "", rownames(sm)) %in% idp
    si <- sm[keep, , drop = FALSE]
    rc <- intersect(c("Rhat", "rhat"), colnames(si))
    out$rhat_max <- if (length(rc)) smax(si[, rc[1]]) else NA_real_
    bc <- intersect(c("ess_bulk", "Bulk_ESS", "n_eff"), colnames(si))
    tc <- intersect(c("ess_tail", "Tail_ESS", "n_eff"), colnames(si))
    out$ess_bulk <- if (length(bc)) smin(si[, bc[1]]) else NA_real_
    out$ess_tail <- if (length(tc)) smin(si[, tc[1]]) else NA_real_
    sp <- rstan::get_sampler_params(fit, inc_warmup = FALSE)
    out$divergences <- sum(sapply(sp, function(x) sum(x[, "divergent__"])))
  }
  out
}

#' @keywords internal
#' @noRd
compute_ppc <- function(fit, Y, be) {
  J <- nrow(Y); N <- ncol(Y)
  if (be == "cmdstanr") {
    yrep_mat <- as.matrix(fit$draws("Y_rep", format = "draws_matrix"))
    nd <- nrow(yrep_mat)
    Yrep <- array(yrep_mat, c(nd, J, N))
  } else {
    post <- rstan::extract(fit)
    Yrep <- post$Y_rep
    nd <- dim(Yrep)[1]
  }
  cor.obs <- cor(Y)
  ut <- upper.tri(cor.obs)
  cor.obs.ut <- cor.obs[ut]
  rmse.r <- numeric(nd)
  for (t in seq_len(nd)) {
    cor.rep <- cor(Yrep[t, , ])
    rmse.r[t] <- sqrt(mean((cor.obs.ut - cor.rep[ut])^2))
  }
  list(rmse.r = rmse.r)
}


#' MatchAlign post-processing for Bayesian factor draws
#'
#' @description
#' Resolves rotational, sign, and label-permutation ambiguity in posterior
#' draws of a factor model by the three-step MatchAlign procedure of
#' Poworoznek et al. (2025): varimax rotation per draw, median-condition
#' pivot selection, greedy L2 signed-permutation matching, and Procrustes
#' rotation.
#'
#' @param Lambda_draws Array of shape `[T, N, K]` of loading draws.
#' @param F_draws Array of shape `[T, J, K]` of factor-score draws.
#'
#' @return A list with aligned `Lambda` and `Fmat` arrays, a
#'   `congruence` matrix of per-draw Tucker-phi per factor, and the
#'   `pivot` index used.
#'
#' @references
#' Poworoznek, E., Anceschi, N., Ferrari, F., & Dunson, D. (2025).
#'   Efficiently Resolving Rotational Ambiguity in Bayesian Matrix
#'   Sampling with Matching. *Bayesian Analysis*.
#'
#' @export
matchalign <- function(Lambda_draws, F_draws) {
  nd <- dim(Lambda_draws)[1]
  N  <- dim(Lambda_draws)[2]
  K  <- dim(Lambda_draws)[3]
  J  <- dim(F_draws)[2]

  rL <- array(NA_real_, dim(Lambda_draws))
  rF <- array(NA_real_, dim(F_draws))
  kap <- numeric(nd)
  cng <- matrix(NA_real_, nd, K)

  has.gpa <- K > 1 && requireNamespace("GPArotation", quietly = TRUE)
  if (K > 1 && !has.gpa) warning("GPArotation not available; varimax step skipped")

  # Step 1: Varimax orthogonalization per draw
  for (s in seq_len(nd)) {
    Ls <- Lambda_draws[s, , , drop = FALSE]; dim(Ls) <- c(N, K)
    Fs <- F_draws[s, , , drop = FALSE];      dim(Fs) <- c(J, K)
    if (has.gpa) {
      rot <- tryCatch(GPArotation::Varimax(Ls, normalize = FALSE), error = function(e) NULL)
      if (!is.null(rot)) { Ls <- rot$loadings; Fs <- Fs %*% rot$Th }
    }
    rL[s, , ] <- Ls; rF[s, , ] <- Fs
    d <- svd(Ls, nu = 0, nv = 0)$d
    kap[s] <- if (min(d) <= 1e-12) Inf else max(d)/min(d)
  }

  # Step 2: Pivot selection via median condition number
  if (any(is.finite(kap)))
    piv <- which.min(abs(kap - median(kap[is.finite(kap)])))
  else piv <- 1L
  Lp <- rL[piv, , , drop = FALSE]; dim(Lp) <- c(N, K)

  # Step 3: signed-permutation matching to pivot. For K > 1, the K x K
  # assignment problem is solved with lpSolve when available; falls back
  # to a greedy K^2 sweep otherwise.
  has.lp <- K > 1 && requireNamespace("lpSolve", quietly = TRUE)

  for (s in seq_len(nd)) {
    Ls <- rL[s, , , drop = FALSE]; dim(Ls) <- c(N, K)
    Fs <- rF[s, , , drop = FALSE]; dim(Fs) <- c(J, K)

    if (K == 1) {
      if (sum((Ls[, 1] + Lp[, 1])^2) < sum((Ls[, 1] - Lp[, 1])^2)) {
        Ls[, 1] <- -Ls[, 1]; Fs[, 1] <- -Fs[, 1]
      }
    } else {
      cost <- matrix(NA_real_, K, K)
      sgn_mat <- matrix(1L, K, K)
      for (k in seq_len(K)) for (j in seq_len(K)) {
        d.pos <- sum((Ls[, j] - Lp[, k])^2)
        d.neg <- sum((Ls[, j] + Lp[, k])^2)
        if (d.neg < d.pos) {
          cost[k, j] <- d.neg; sgn_mat[k, j] <- -1L
        } else {
          cost[k, j] <- d.pos
        }
      }

      if (has.lp) {
        sol  <- lpSolve::lp.assign(cost)$solution
        perm <- apply(sol, 1, which.max)
      } else {
        perm <- integer(K); used <- logical(K)
        for (k in seq_len(K)) {
          best.dist <- Inf; best.j <- 0L
          for (j in seq_len(K)) {
            if (used[j]) next
            if (cost[k, j] < best.dist) {
              best.dist <- cost[k, j]; best.j <- j
            }
          }
          perm[k] <- best.j; used[best.j] <- TRUE
        }
      }
      sgn <- sgn_mat[cbind(seq_len(K), perm)]

      Ls <- Ls[, perm, drop = FALSE]
      Fs <- Fs[, perm, drop = FALSE]
      for (k in seq_len(K)) { Ls[, k] <- Ls[, k] * sgn[k]; Fs[, k] <- Fs[, k] * sgn[k] }

      # Procrustes rotation to resolve residual rotational misalignment
      sv <- svd(t(Ls) %*% Lp)
      Rp <- sv$u %*% t(sv$v)
      Ls <- Ls %*% Rp; Fs <- Fs %*% Rp
    }

    rL[s, , ] <- Ls; rF[s, , ] <- Fs

    for (k in seq_len(K)) {
      num <- sum(Ls[, k] * Lp[, k])
      den <- sqrt(sum(Ls[, k]^2) * sum(Lp[, k]^2))
      cng[s, k] <- if (den > 1e-12) num/den else NA_real_
    }
  }
  list(Lambda = rL, Fmat = rF, congruence = cng, pivot = piv)
}
