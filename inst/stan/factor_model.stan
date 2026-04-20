// Bayesian factor model for Q-methodology.
// Y = F * Lambda' + E with Normal or Student-t errors.
// Factor columns are standardized per draw to pin the scale; rotational
// ambiguity is resolved post-hoc in R (MatchAlign).

data {
  int<lower=1> N;  // participants
  int<lower=1> M;  // statements
  int<lower=1> K;  // factors
  matrix[M, N] Y;  // Q-sort data, statements x participants

  int<lower=0, upper=1> use_student_t;    // 1 = robust likelihood
  int<lower=0, upper=1> fix_nu;           // 1 = fix nu, 0 = estimate
  real<lower=0> prior_loading_scale;      // default 1.0
  real<lower=0> prior_sigma_scale;        // default 1.0
  real<lower=0> prior_nu_alpha;           // default 2.0
  real<lower=0> prior_nu_beta;            // default 0.1
  real<lower=1> nu_fixed;                 // used when fix_nu = 1
  int<lower=0, upper=1> use_half_cauchy;  // 0 = lognormal on tau, 1 = half-Cauchy
}

transformed data {
  // Center and scale each sort. We keep the shifts and scales so we can
  // return Y_rep on the original Q-sort scale below.
  matrix[M, N] Y_c;
  vector[N] col_means;
  vector[N] col_sds;

  for (n in 1:N) {
    col_means[n] = mean(Y[, n]);
    col_sds[n] = sd(Y[, n]);
    if (col_sds[n] < 1e-6) col_sds[n] = 1.0;
    Y_c[, n] = (Y[, n] - col_means[n]) / col_sds[n];
  }
}

parameters {
  matrix[N, K] Lambda_raw;
  real tau_raw;                         // reshaped into tau below
  matrix[M, K] F_raw;
  real<lower=-5, upper=3> log_sigma;
  real<lower=2, upper=150> nu_raw;      // only used when fix_nu = 0
}

transformed parameters {
  real<lower=0> tau;
  if (use_half_cauchy == 1)
    tau = abs(tau_raw);                            // folded -> half-Cauchy(0, 1)
  else
    tau = exp(-5.0 + 8.0 * inv_logit(tau_raw));    // lognormal, bounded to (~0.007, ~20)

  real<lower=0> sigma = exp(log_sigma);
  real<lower=2> nu    = fix_nu == 1 ? nu_fixed : nu_raw;

  matrix[N, K] Lambda = Lambda_raw;

  // Standardize each factor column to zero mean, unit variance within the
  // draw. This pins the scale so Lambda and F aren't trivially exchangeable.
  matrix[M, K] F;
  for (k in 1:K) {
    real fmean = mean(F_raw[, k]);
    real fsd   = sd(F_raw[, k]);
    if (fsd < 1e-6) fsd = 1.0;
    F[, k] = (F_raw[, k] - fmean) / fsd;
  }
}

model {
  if (use_half_cauchy == 1) {
    tau_raw ~ cauchy(0, 1);
  } else {
    // log_tau = -5 + 8 * inv_logit(tau_raw). Jacobian: 8 * p * (1 - p).
    real p = inv_logit(tau_raw);
    real log_tau = -5.0 + 8.0 * p;
    target += normal_lpdf(log_tau | log(prior_loading_scale), 0.5);
    target += log(8.0) + log(p) + log1m(p);
  }
  log_sigma ~ normal(log(prior_sigma_scale), 0.5);
  to_vector(Lambda_raw) ~ normal(0, tau);
  to_vector(F_raw)      ~ std_normal();
  if (fix_nu == 0)
    nu_raw ~ gamma(prior_nu_alpha, prior_nu_beta);

  matrix[M, N] mu = F * Lambda';
  if (use_student_t == 1)
    to_vector(Y_c) ~ student_t(nu, to_vector(mu), sigma);
  else
    to_vector(Y_c) ~ normal(to_vector(mu), sigma);
}

generated quantities {
  matrix[M, N] Y_rep;
  matrix[M, N] log_lik;
  vector[N] log_lik_person;

  for (n in 1:N) {
    log_lik_person[n] = 0;
    for (m in 1:M) {
      real mu_mn = dot_product(F[m, ], Lambda[n, ]);
      if (use_student_t == 1) {
        log_lik[m, n] = student_t_lpdf(Y_c[m, n] | nu, mu_mn, sigma);
        Y_rep[m, n]   = student_t_rng(nu,
                          mu_mn * col_sds[n] + col_means[n],
                          sigma * col_sds[n]);
      } else {
        log_lik[m, n] = normal_lpdf(Y_c[m, n] | mu_mn, sigma);
        Y_rep[m, n]   = normal_rng(
                          mu_mn * col_sds[n] + col_means[n],
                          sigma * col_sds[n]);
      }
      log_lik_person[n] += log_lik[m, n];
    }
  }
}
