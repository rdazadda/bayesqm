# claims.R
# One posterior false-discovery rule for every claim. claims() assembles
# the four claim families from the same internals the table functions use,
# so a selected column can never disagree across calls.


#' Selected claims at a common false-discovery level
#'
#' @description
#' Selects every claim — participant flags, distinguishing listings,
#' consensus statements, and pairwise stars — by the one posterior
#' false-discovery rule at level `q`, and reports the expected number of
#' false claims per family alongside. The same code path produces the
#' `selected` columns of [compute_flags()] and [compute_qdc()], so the
#' tables and this object always agree.
#'
#' @param fit A `bayesqm_fit`.
#' @param q Posterior expected false-discovery bound (default 0.05).
#' @param flag_floor,cons_floor Selection floors for flags (0.5) and
#'   consensus statements (0.95).
#'
#' @return A `bayesqm_claims` object: selected-only tables `flags`,
#'   `distinguishing`, `consensus`, and `stars`, each with its
#'   `expected_false` count, plus the level `q`.
#'
#' @examples
#' claims(demo_fit())
#'
#' @export
claims <- function(fit, q = 0.05, flag_floor = 0.5, cons_floor = 0.95) {
  assert_bayesqm_fit(fit)
  fl <- .flag_table(fit, q = q, floor = flag_floor)
  flags <- fl[fl$selected, c("participant", "factor", "sign", "flag_prob")]
  rownames(flags) <- NULL

  distinguishing <- consensus <- stars <- NULL
  ef <- c(flags = attr(fl, "expected_false"), distinguishing = 0,
          consensus = 0, stars = 0)
  if (fit$brief$K >= 2) {
    qt <- .qdc_tables(fit, q = q, cons_floor = cons_floor)
    fac_ids <- dimnames(fit$draws$sigma)[[2]]
    pd <- qt$pair_stats$pi_dist
    idx <- which(qt$dist_pub, arr.ind = TRUE)
    distinguishing <- data.frame(
      statement = rownames(pd)[idx[, 1]],
      factor = fac_ids[idx[, 2]],
      dist_prob = pd[idx],
      stringsAsFactors = FALSE
    )
    distinguishing <- distinguishing[order(distinguishing$factor,
                                           -distinguishing$dist_prob), ]
    rownames(distinguishing) <- NULL

    cons_rows <- qt$qdc$verdict == "consensus"
    consensus <- data.frame(statement = qt$qdc$statement[cons_rows],
                            consensus_prob = qt$qdc$consensus_prob[cons_rows],
                            stringsAsFactors = FALSE)
    rownames(consensus) <- NULL

    ct <- qt$contrasts
    stars <- ct[ct$selected,
                c("statement", "pair", "median", "exceed_prob", "stars")]
    rownames(stars) <- NULL
    ef["distinguishing"] <- qt$expected_false["distinguishing"]
    ef["consensus"] <- qt$expected_false["consensus"]
    ef["stars"] <- qt$expected_false["stars"]
  }

  structure(
    list(flags = flags, distinguishing = distinguishing,
         consensus = consensus, stars = stars,
         expected_false = ef, q = q),
    class = "bayesqm_claims"
  )
}


#' @export
print.bayesqm_claims <- function(x, ...) {
  cat(sprintf("Selected claims at q = %.2f (posterior expected FDR):\n", x$q))
  fam <- function(name, tab, unit) {
    n <- if (is.null(tab)) 0L else nrow(tab)
    cat(sprintf("  %-15s %3d %s selected (expected false %.2f)\n",
                name, n, unit, x$expected_false[[name]]))
  }
  fam("flags", x$flags, "participants")
  fam("distinguishing", x$distinguishing, "listings")
  fam("consensus", x$consensus, "statements")
  fam("stars", x$stars, "pairwise")
  invisible(x)
}
