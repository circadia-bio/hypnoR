# Plot a hypnogram

Renders a classic stage-over-time hypnogram using `ggplot2` and
`theme_circadia()`. Accepts both full AASM and coarse staging; the
y-axis order and colour mapping are set automatically from the staging
resolution detected in `hypnogram`.

## Usage

``` r
plot_hypnogram(
  hypnogram,
  epoch_sec = 30L,
  colours = NULL,
  show_cycles = FALSE,
  title = NULL
)
```

## Arguments

- hypnogram:

  A tibble returned by
  [`read_hypnogram()`](https://hypnor.circadia-lab.uk/reference/read_hypnogram.md).

- epoch_sec:

  Epoch duration in seconds, used to construct the time axis. Default
  `30`.

- colours:

  Named character vector mapping stage labels to hex colours. Defaults
  to the Circadia Lab palette via `circadia::domain_colour_for()`, if
  available, otherwise a built-in fallback.

- show_cycles:

  If `TRUE` and cycle information is available (a `cycle` column is
  present in `hypnogram`), cycle boundaries are overlaid as vertical
  dashed lines. Default `FALSE`.

- title:

  Optional plot title.

## Value

A `ggplot` object.

## Examples

``` r
if (FALSE) { # \dontrun{
hyp <- read_hypnogram("night_001.csv")
plot_hypnogram(hyp)
} # }
```
