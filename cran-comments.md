This is the first CRAN submission of bayesqm.

## Test environments

- Windows 11, R 4.6.0 (local)
- GitHub Actions: ubuntu-latest, windows-latest, and macos-latest, on R release, R-devel, and R 4.5.x (oldrel-1)
- win-builder, R-devel
- R-hub v2

## R CMD check results

0 errors | 0 warnings | 1 note

The note has three parts. The first is the standard "New submission" message. The second flags six words in the DESCRIPTION as possibly misspelled: MatchAlign (a post-processing method), Poworoznek, Sivula, and Vehtari (author surnames), and et and al (components of the Latin abbreviation "et al."). All six appear inside the inline DOI citations. The third reports that cmdstanr is suggested but not on a mainstream repository: cmdstanr is published on the Stan project's r-universe, the package declares this in Additional_repositories, and the check confirms cmdstanr is reachable from the declared location.

## Stan and the test suite

bayesqm uses Stan for posterior sampling. cmdstanr is the recommended backend, with rstan supported as a fallback. The integration tests that compile and sample the model live in tests/testthat/test-stan-sampling.R and are guarded by skip_on_cran(), so the CRAN check farm does not need a working Stan toolchain.
