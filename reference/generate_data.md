# Simulate Q-sort data

`generate_data()` is the top-level data-generating function used by the
paper's simulation studies and by package tests. It builds a loading
matrix (`generate_loadings()`), factor scores, noise of the chosen type
(`generate_noise()`), and discretises the continuous signal onto a
forced Q-sort grid (`discretize_to_grid()`). See also
`get_distribution()` for the standard forced-distribution lookup.

## Usage

``` r
generate_data(
  N,
  J,
  K,
  noise_sd = 1,
  error_type = "normal",
  nu = 5,
  contam_prop = 0.1,
  contam_scale = 4,
  loading_type = "simple",
  primary_range = c(0.55, 0.85),
  cross_range = c(-0.15, 0.15),
  seed = NULL
)

generate_loadings(
  N,
  K,
  primary_range = c(0.55, 0.85),
  cross_range = c(-0.15, 0.15),
  type = "simple"
)

generate_noise(
  J,
  N,
  type = "normal",
  sd = 1,
  nu = 5,
  contam_prop = 0.1,
  contam_scale = 4
)

discretize_to_grid(Y_cont, distr)

get_distribution(J)
```

## Arguments

- N, J, K:

  Numbers of participants, statements, and factors.

- noise_sd:

  Residual SD.

- error_type:

  One of `"normal"`, `"t"`, `"contaminated"`.

- nu:

  Degrees of freedom for `error_type = "t"`.

- contam_prop, contam_scale:

  Contamination rate and scale.

- loading_type:

  `"simple"` or `"complex"`.

- primary_range, cross_range, type:

  For `generate_loadings()`.

- seed:

  Optional RNG seed; restored on exit.

- type, sd:

  For `generate_noise()`.

- Y_cont:

  Continuous scores (for `discretize_to_grid()`).

- distr:

  Integer forced-distribution counts.

## Value

`generate_data()` returns a list with `Y`, `Lambda_true`, `F_true`,
`distribution`, `N`, `J`, `K`. The component helpers return their
respective raw objects.
