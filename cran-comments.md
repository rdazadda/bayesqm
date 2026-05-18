This is the first CRAN submission of bayesqm.

## Test environments

- Windows 11, R 4.6.0 (local)
- GitHub Actions: ubuntu-latest, windows-latest, and macos-latest, on R release, R-devel, and R 4.5.x (oldrel-1)
- win-builder, R-devel
- R-hub v2

## R CMD check results

Local `R CMD check --as-cran` (R 4.6.0): 0 errors | 0 warnings | 0 notes.

This is a new submission, so CRAN will add the usual "New submission" note. The check will also flag `cmdstanr` as a suggested package that is not on a mainstream repository; that is expected. `cmdstanr` is distributed through the Stan project's r-universe, which the package declares in `Additional_repositories`, and the check confirms it is reachable there. Anything the spell check reports is a correctly spelled author surname from the DOI citations or a standard Q-methodology or Stan term, all kept in `inst/WORDLIST`.

## Stan and the test suite

bayesqm uses Stan for posterior sampling. cmdstanr is the recommended backend, with rstan supported as a fallback. The integration tests that compile and sample the model live in tests/testthat/test-stan-sampling.R and are guarded by skip_on_cran(), so the CRAN check farm does not need a working Stan toolchain.
