# Probabilistic dominant-factor panel

Draws a blue-gradient heatmap of `P(dominant factor = k)` per
participant, with a right-hand "Assignment" strip (orange-red gradient)
showing the verdict "Strong / Mod. / Weak F-k" for each participant.

## Usage

``` r
make_dominant_panel(fit, title = NULL, anonymize = TRUE)
```

## Arguments

- fit:

  A `bayesqm_fit`.

- title:

  Optional panel title.

- anonymize:

  Logical; when `TRUE`, participants are relabelled `P01..PNN`.

## Value

A `ggplot` object.
