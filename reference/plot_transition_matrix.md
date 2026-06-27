# Plot a stage-transition heatmap

Renders the transition probability (or count) matrix returned by
[`compute_transitions()`](https://hypnor.circadia-lab.uk/reference/compute_transitions.md)
as a heatmap using `ggplot2` and `theme_circadia()`.

## Usage

``` r
plot_transition_matrix(
  transitions,
  label_values = TRUE,
  digits = 2L,
  title = NULL
)
```

## Arguments

- transitions:

  The `matrix` element of the list returned by
  [`compute_transitions()`](https://hypnor.circadia-lab.uk/reference/compute_transitions.md).

- label_values:

  If `TRUE` (default), cell values are printed inside each tile.

- digits:

  Number of decimal places for cell labels. Default `2`.

- title:

  Optional plot title.

## Value

A `ggplot` object.

## Examples

``` r
if (FALSE) { # \dontrun{
hyp   <- read_hypnogram("night_001.csv")
trans <- compute_transitions(hyp)
plot_transition_matrix(trans$matrix)
} # }
```
