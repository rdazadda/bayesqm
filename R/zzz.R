# zzz.R
# Conditional S3 method registration for generics that live in Suggests
# packages. Without this, calling loo(fit) or as_draws_df(fit) would fall
# back to the default method even after the user loads loo / posterior.


.onLoad <- function(libname, pkgname) {
  if (requireNamespace("loo", quietly = TRUE))
    registerS3method("loo", "bayesqm_fit",
                     loo.bayesqm_fit, envir = asNamespace("loo"))

  if (requireNamespace("posterior", quietly = TRUE)) {
    ns <- asNamespace("posterior")
    registerS3method("as_draws",        "bayesqm_fit",
                     as_draws.bayesqm_fit,        envir = ns)
    registerS3method("as_draws_df",     "bayesqm_fit",
                     as_draws_df.bayesqm_fit,     envir = ns)
    registerS3method("as_draws_matrix", "bayesqm_fit",
                     as_draws_matrix.bayesqm_fit, envir = ns)
    registerS3method("as_draws_array",  "bayesqm_fit",
                     as_draws_array.bayesqm_fit,  envir = ns)
    registerS3method("as_draws_rvars",  "bayesqm_fit",
                     as_draws_rvars.bayesqm_fit,  envir = ns)
    registerS3method("as_draws_list",   "bayesqm_fit",
                     as_draws_list.bayesqm_fit,   envir = ns)
    registerS3method("ndraws",          "bayesqm_fit",
                     ndraws.bayesqm_fit,          envir = ns)
  }

  if (requireNamespace("ggplot2", quietly = TRUE)) {
    ns <- asNamespace("ggplot2")
    registerS3method("autoplot", "bayesqm_fit",
                     autoplot.bayesqm_fit, envir = ns)
    registerS3method("autoplot", "bayesqm_run",
                     autoplot.bayesqm_run, envir = ns)
  }
}
