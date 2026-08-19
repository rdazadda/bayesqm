# data.R
# Documentation for the shipped datasets.


#' Childhood obesity Q sorts
#'
#' @description
#' The childhood obesity Q dataset from Akhtar-Danesh (2023): 33
#' participants each force-sorted 42 statements about childhood
#' obesity onto a nine-column grid (quotas 2-4-5-6-8-6-5-4-2, printed
#' values -4 to +4). A real, published panel at typical Q scale, used
#' in the package documentation.
#'
#' @format A [qsort_data] object: the 42 x 33 integer matrix of printed
#'   grid values with statement and participant ids, and the forced
#'   distribution.
#'
#' @source Akhtar-Danesh, N. (2023). Impact of factor rotation on
#'   Q-methodology analysis. \emph{PLOS ONE}, 18(9), e0290728.
#'   \doi{10.1371/journal.pone.0290728}
#'
#' @examples
#' obesity_sorts
#' plot(obesity_sorts, participants = 1:4)
"obesity_sorts"


#' Grizzly bear reintroduction Q sorts
#'
#' @description
#' The grizzly bear reintroduction Q dataset from Easter et al. (2025):
#' 67 participants each force-sorted 41 statements about reintroducing
#' grizzly bears to the North Cascades onto an eleven-column grid
#' (quotas 1-2-3-5-6-7-6-5-3-2-1, printed values -5 to +5). A real,
#' published panel where the two-signal rule selects a two-factor
#' solution, used in the package documentation.
#'
#' @format A [qsort_data] object: the 41 x 67 integer matrix of printed
#'   grid values with statement and participant ids, and the forced
#'   distribution.
#'
#' @source Easter, T. S., Santo, A. R., Sage, A. H., Carter, N. H.,
#'   Chan, K. M. A., & Ransom, J. I. (2025). Divergent values and
#'   perspectives drive three distinct viewpoints on grizzly bear
#'   reintroduction in Washington, the United States. \emph{People and
#'   Nature}, 7, 127--145. \doi{10.1002/pan3.10748}. Data from the
#'   Dryad repository under CC0, \doi{10.5061/dryad.73n5tb369}.
#'
#' @examples
#' grizzly_sorts
#' plot(grizzly_sorts, participants = 1:4)
"grizzly_sorts"
