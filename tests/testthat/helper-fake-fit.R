# Helpers for test files: construct a synthetic bayesqm_fit object without
# running Stan. Every accessor, print method, and summary function should
# work against a fit built this way.

make_fake_draws <- function(N = 6, J = 10, K = 2, T = 200, seed = 1L) {
  set.seed(seed)
  Lambda <- array(rnorm(T * N * K, sd = 0.5), c(T, N, K))
  Fmat   <- array(rnorm(T * J * K), c(T, J, K))
  list(
    Lambda = Lambda,
    Fmat   = Fmat,
    nu     = abs(rnorm(T, mean = 20,  sd = 5)),
    sigma  = abs(rnorm(T, mean = 0.5, sd = 0.1)),
    tau    = abs(rnorm(T, mean = 0.5, sd = 0.1))
  )
}

make_fake_fit <- function(N = 6, J = 10, K = 2, T = 200, seed = 1L) {
  dr <- make_fake_draws(N, J, K, T, seed)

  L_mean <- apply(dr$Lambda, c(2, 3), mean); dim(L_mean) <- c(N, K)
  F_mean <- apply(dr$Fmat,   c(2, 3), mean); dim(F_mean) <- c(J, K)
  Y_cont <- F_mean %*% t(L_mean) + matrix(rnorm(J * N, 0, 0.1), J, N)

  distr <- get_distribution(J)
  Y     <- discretize_to_grid(Y_cont, distr)
  rownames(Y) <- paste0("S", seq_len(J))
  colnames(Y) <- paste0("P", seq_len(N))

  dm    <- c(N, K)
  Lhat  <- apply(dr$Lambda, c(2, 3), mean);   dim(Lhat) <- dm
  Lmed  <- apply(dr$Lambda, c(2, 3), median); dim(Lmed) <- dm
  alpha <- 0.05
  ci_lo <- apply(dr$Lambda, c(2, 3), quantile, probs =     alpha / 2)
  ci_hi <- apply(dr$Lambda, c(2, 3), quantile, probs = 1 - alpha / 2)
  dim(ci_lo) <- dm; dim(ci_hi) <- dm

  priors <- list(
    loading_scale   = 1.0,
    sigma_scale     = 1.0,
    nu_alpha        = 2.0,
    nu_beta         = 0.1,
    use_half_cauchy = FALSE
  )

  bayesqm:::new_bayesqm_fit(
    call         = call("fit_bayesian", Y = quote(Y), K = K),
    Y            = Y,
    K            = K,
    distribution = distr,
    prob         = 0.95,
    robust       = TRUE,
    nu           = "estimate",
    chains       = 2,
    iter         = 400,
    warmup       = 200,
    backend      = "test",
    priors       = priors,
    Lhat         = Lhat,
    Lmed         = Lmed,
    ci_lo        = ci_lo,
    ci_hi        = ci_hi,
    Lambda_draws = dr$Lambda,
    F_draws      = dr$Fmat,
    align_info   = list(congruence = matrix(1, T, K), pivot = 1L),
    hyperparams  = list(nu = dr$nu, sigma = dr$sigma, tau = dr$tau),
    loo_el       = NULL,
    loo_ps       = NULL,
    diag         = list(rhat_max = 1.01, ess_bulk = 800,
                        ess_tail = 900, divergences = 0L),
    ppc          = list(rmse.r = abs(rnorm(T, 0.3, 0.05)))
  )
}
