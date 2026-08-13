# Get or set the bayesqm colour scheme

Every plot in the package reads its palette through `bayesqm_colors()`.
Call `bayesqm_set_colors()` to switch the active scheme for every
subsequent plot. The available built-in schemes are `"sorts"` (default,
the
[`plot_sorts()`](https://rdazadda.github.io/bayesqm/reference/plot_sorts.md)
colour family), `"blue"`, `"teal"`, `"red"`, `"purple"`, and `"grey"`.
For full control, pass a named list with slots `dark`, `accent`, `grey`,
`gridgrey`, and `fill`.

## Usage

``` r
bayesqm_colors()

bayesqm_set_colors(scheme)
```

## Arguments

- scheme:

  Character name of a built-in scheme, or a named list of colours with
  the slot names listed in the description.

## Value

`bayesqm_colors()` returns the active palette as a named list.
`bayesqm_set_colors()` returns the previous scheme name, invisibly.

## Examples

``` r
bayesqm_colors()
#> $dark
#> [1] "#1B4F72"
#> 
#> $accent
#> [1] "#922B21"
#> 
#> $grey
#> [1] "grey40"
#> 
#> $gridgrey
#> [1] "grey75"
#> 
#> $fill
#> [1] "#D6EAF8"
#> 
#> $qual
#> [1] "#2E86C1" "#E67E22" "#17A589" "#6C3483" "#E74C3C" "#922B21" "#F4D03F"
#> [8] "#5D6D7E"
#> 
old <- bayesqm_set_colors("teal")
bayesqm_colors()[["fill"]]
#> [1] "#a8ddb5"
bayesqm_set_colors(old)
```
