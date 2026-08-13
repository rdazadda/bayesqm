# Rename the factors

Replaces the `f1 ... fK` labels with substantive names everywhere the
fit carries them, so every downstream table and plot uses the new names.

## Usage

``` r
rename_factors(fit, new_names)
```

## Arguments

- fit:

  A `bayesqm_fit`.

- new_names:

  Character vector of length `K`.

## Value

The renamed fit.
