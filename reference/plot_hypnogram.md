# Plot a hypnogram

Renders a hypnogram using `ggplot2` and the Circadia Lab colour palette.
Accepts both full AASM and coarse staging; the lane order (deepest sleep
at the bottom, Wake at the top) and colour mapping are set automatically
from the staging levels present in `hypnogram`.

## Usage

``` r
plot_hypnogram(
  hypnogram,
  style = c("step", "capsule"),
  x_axis = c("auto", "time", "hours"),
  date_breaks = "2 hours",
  cycles = NULL,
  colours = NULL,
  title = NULL,
  corner_min = 9
)
```

## Arguments

- hypnogram:

  A `hypnor_hypnogram` object as returned by
  [`new_hypnogram()`](https://hypnor.circadia-lab.uk/reference/new_hypnogram.md)
  or
  [`read_hypnogram()`](https://hypnor.circadia-lab.uk/reference/read_hypnogram.md),
  or any data frame with at minimum `epoch` and `stage` columns – it
  will be passed through
  [`new_hypnogram()`](https://hypnor.circadia-lab.uk/reference/new_hypnogram.md)
  automatically if not already a `hypnor_hypnogram`. Epoch duration is
  read from the object's `epoch_sec` attribute.

- style:

  `"step"` (default) or `"capsule"`:

  `"step"`

  :   Classic clinical step-plot: one line tracing the stage at every
      epoch.

  `"capsule"`

  :   Rounded-pill bars per contiguous stage run, one lane per stage.

- x_axis:

  `"auto"` (default), `"time"`, or `"hours"`:

  `"auto"`

  :   Uses actual clock time (from the `time` column) if `hypnogram`
      carries any non-`NA` timestamps, otherwise falls back to elapsed
      hours since the first epoch.

  `"time"`

  :   Forces clock time; errors if `time` is entirely `NA` (no
      `start_time` was supplied to
      [`new_hypnogram()`](https://hypnor.circadia-lab.uk/reference/new_hypnogram.md)
      or
      [`mrpheus::export_hypnogram()`](https://mrpheus.circadia-lab.uk/reference/export_hypnogram.html)).

  `"hours"`

  :   Forces elapsed hours since the first epoch, regardless of whether
      real timestamps are available.

- date_breaks:

  Only used when plotting clock time. Passed to
  [`ggplot2::scale_x_datetime()`](https://ggplot2.tidyverse.org/reference/scale_date.html)'s
  `date_breaks`. Default `"2 hours"`.

- cycles:

  Optional: the tibble returned by
  [`compute_cycles()`](https://hypnor.circadia-lab.uk/reference/compute_cycles.md).
  When supplied, a dashed vertical line is drawn at the start of each
  cycle.

- colours:

  Named character vector mapping stage labels to hex colours. Defaults
  to a built-in palette drawn from the Circadia Lab colours. Pass your
  own named vector to override.

- title:

  Optional plot title.

- corner_min:

  Only used by `style = "capsule"`. Maximum pill corner radius, in
  minutes. Runs shorter than `2 * corner_min` get a proportionally
  smaller radius (so very brief runs render as fully rounded
  capsule/stadium shapes rather than having oversized corners), longer
  runs are capped at this radius. Default `9`.

## Value

A `ggplot` object.

## Examples

``` r
if (FALSE) { # \dontrun{
hyp <- read_hypnogram("night_001.csv")
plot_hypnogram(hyp)
plot_hypnogram(hyp, cycles = compute_cycles(hyp))
plot_hypnogram(hyp, x_axis = "hours")
plot_hypnogram(hyp, style = "capsule")
} # }
```
