# utils.R
# Internal helpers shared across the package. Not exported.


# Apply `fun` over the last two margins of a [Td, dim2, dim3] draws array,
# preserving the dim2 x dim3 matrix shape (avoids the apply() drop-when-K=1
# bug) and propagating dimnames.
.summarize_draws <- function(draws, fun, ...) {
  out <- apply(draws, c(2, 3), fun, ...)
  dim(out) <- dim(draws)[2:3]
  dimnames(out) <- dimnames(draws)[2:3]
  out
}


# Internal stop with a "[bayesqm]" prefix, sprintf semantics, and the
# caller's frame as call.
.bq_abort <- function(fmt, ..., call = sys.call(-1L)) {
  cond <- structure(
    class   = c("bayesqm_error", "error", "condition"),
    list(message = paste0("[bayesqm] ", sprintf(fmt, ...)),
         call    = call))
  stop(cond)
}


assert_bayesqm_fit <- function(x, var_name = deparse(substitute(x))) {
  if (!inherits(x, "bayesqm_fit"))
    .bq_abort("`%s` must be a bayesqm_fit object, not %s.",
              var_name, class(x)[1L])
  invisible(x)
}
