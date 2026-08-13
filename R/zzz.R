# zzz.R
# S3 method registration for generics that live in other packages.
# posterior is in Imports, so its registrations are unconditional; without
# them as_draws_df(fit) would fall back to the default method. ggplot2's
# .data pronoun is referenced inside autoplot; declare it for R CMD check.

utils::globalVariables(".data")

.onLoad <- function(libname, pkgname) {
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

  if (requireNamespace("ggplot2", quietly = TRUE)) {
    ns <- asNamespace("ggplot2")
    registerS3method("autoplot", "bayesqm_fit", autoplot.bayesqm_fit,
                     envir = ns)
    registerS3method("autoplot", "qsort_data", autoplot.qsort_data,
                     envir = ns)
  }
}
