# Plot sleep architecture as a bar chart

Renders stage durations or percentages as a horizontal bar chart using
`ggplot2` and `theme_circadia()`.

## Usage

``` r
plot_architecture(
  architecture,
  metric = "duration",
  colours = NULL,
  title = NULL
)
```

## Arguments

- architecture:

  A one-row tibble returned by
  [`compute_sleep_architecture()`](https://hypnor.circadia-lab.uk/reference/compute_sleep_architecture.md),
  or a multi-row tibble for comparing multiple nights (requires a
  `night` or `id` grouping column).

- metric:

  `"duration"` (minutes, default) or `"percentage"` of TST.

- colours:

  Named character vector of stage colours. See
  [`plot_hypnogram()`](https://hypnor.circadia-lab.uk/reference/plot_hypnogram.md)
  for defaults.

- title:

  Optional plot title.

## Value

A `ggplot` object.

## Examples

``` r
if (FALSE) { # \dontrun{
hyp  <- read_hypnogram("night_001.csv")
arch <- compute_sleep_architecture(hyp)
plot_architecture(arch)
} # }
```
