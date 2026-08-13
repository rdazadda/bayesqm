# Flag probabilities with the unclassified state

One row per participant, one dot per factor at its posterior flag
probability (both poles combined; a minus sign marks a dominant negative
pole), and a grey square for the probability of remaining unclassified.
Filled dots are selected flags, and the dotted rule is the 0.5 selection
floor.

## Usage

``` r
plot_membership(...)

plot_flags(fit, q = 0.05)
```

## Arguments

- ...:

  Passed on.

- fit:

  A `bayesqm_fit`.

- q:

  False-discovery level for the selection marks (default 0.05).

## Value

`fit`, invisibly.
