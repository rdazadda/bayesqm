This is a version update, 0.1.0 to 0.2.0.

## What changed

0.2.0 replaces the model and the sampler. The score-scale factor model
fitted in Stan is gone, and the package now models the forced Q sort as
an ordered partition through an exact rank-order likelihood, fitted by a
parameter-expanded Gibbs sampler written in R with no compiled
code. Stan, cmdstanr, and
rstan are no longer used or suggested, so the Additional_repositories
field and the backend guards from the 0.1.0 submission are gone with
them. The user-facing changes are documented in NEWS.md.

The two datasets that ship with the package are small published Q
sorts, a few kilobytes each, redistributed under CC0 (Dryad) and CC-BY
(PLOS ONE) with sources credited on their help pages.

## Test environments

- Windows 11, R 4.6.0 (local)
- GitHub Actions: ubuntu-latest, windows-latest, and macos-latest, on R
  release, R-devel, and oldrel-1
- win-builder, R-devel

## R CMD check results

Local `R CMD check --as-cran` (R 4.6.0): 0 errors | 0 warnings | 0 notes.

## Reverse dependencies

There are none.
