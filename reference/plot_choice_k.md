# The two-signal choice-of-K display

The whole decision in one strip, one row per ladder rung. The left span
shows the adequacy signal, the extra-factor percentile inside its shaded
band, with a warning ring where the person check found a mutual
unspanned cluster. The right span shows one chip per factor, coloured
when the factor is supported and grey when not, with the reason inside:
`f` means fewer than two selected flags, `d` means no selected
distinguishing statement. Each row ends with its own verdict in words,
the selected row is boxed, and when no K passes both checks the
conclusion is written across the bottom of the plot.

## Usage

``` r
plot_choice_k(x)
```

## Arguments

- x:

  A `bayesqm_selection` from
  [`select_k()`](https://rdazadda.github.io/bayesqm/reference/select_k.md).

## Value

`x`, invisibly.
