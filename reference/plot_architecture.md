# Plot sleep architecture as a bar chart

Renders stage durations or percentages as a horizontal bar chart using
`ggplot2` and a Circadia Lab colour palette.

## Usage

``` r
plot_architecture(
  architecture,
  metric = c("duration", "percentage"),
  colours = NULL,
  title = NULL
)
```

## Arguments

- architecture:

  A tibble returned by
  [`compute_sleep_architecture()`](https://hypnor.circadia-lab.uk/reference/compute_sleep_architecture.md)
  – either a single row, or multiple rows for comparing several nights,
  in which case a `night` or `id` column (if present) is used to facet
  the plot into one panel per night.

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
plot_architecture(arch, metric = "percentage")
} # }
```
