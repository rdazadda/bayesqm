# Helpers for the Stan-sampling integration tests. These are skipped on
# CRAN and in environments without a Stan backend; when they do run, they
# exercise the full fit_bayesian() pipeline on small synthetic data.

skip_if_no_stan <- function() {
  has_cmdstan <- requireNamespace("cmdstanr", quietly = TRUE) &&
    !inherits(try(cmdstanr::cmdstan_path(), silent = TRUE), "try-error")
  has_rstan <- requireNamespace("rstan", quietly = TRUE)
  if (!has_cmdstan && !has_rstan)
    testthat::skip("Neither cmdstanr nor rstan is available.")
}

# Tiny synthetic Q-sort with a recoverable 2-factor structure. Kept small on
# purpose so the Stan compile + sampling finishes within a minute or two.
make_stan_test_data <- function(N = 15, J = 12, K = 2, seed = 1L) {
  set.seed(seed)
  generate_data(N = N, J = J, K = K, noise_sd = 0.3,
                error_type = "normal", seed = seed)
}

# Common low-iter sampler settings that are enough to produce a
# well-formed fit object without being expensive.
stan_fast <- list(chains = 2, iter = 400, warmup = 200, max_draws = 300,
                  adapt_delta = 0.85)
