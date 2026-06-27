# Read a hypnogram from file

Imports a staged hypnogram from common formats and returns a tidy tibble
with one row per epoch. The resulting object is the standard input for
all other `hypnoR` functions.

## Usage

``` r
read_hypnogram(
  path,
  format = "auto",
  epoch_sec = 30L,
  tz = "UTC",
  quiet = FALSE
)
```

## Arguments

- path:

  Path to the hypnogram file.

- format:

  One of `"csv"`, `"edf_annotations"`, `"yasa"`, `"compumedics"`,
  `"nox"`, or `"auto"` (default). When `"auto"`, the format is inferred
  from the file extension and header.

- epoch_sec:

  Epoch duration in seconds. Default `30`.

- tz:

  Time zone string passed to
  [`lubridate::as_datetime()`](https://lubridate.tidyverse.org/reference/as_date.html).
  Default `"UTC"`.

- quiet:

  Suppress informational messages. Default `FALSE`.

## Value

A tibble with columns:

- epoch:

  Integer epoch index (1-based).

- time:

  `POSIXct` timestamp for the start of each epoch.

- stage:

  Ordered factor. Level set depends on staging resolution: full AASM
  (`W`, `N1`, `N2`, `N3`, `REM`) or coarse actigraphy-derived (`W`,
  `Sleep`, `Quiet sleep`).

- source:

  Character — the originating device / scorer label, if available in the
  file header.

## Details

`hypnoR` distinguishes two staging resolutions:

- **Full AASM** (5-state): supplied by `mrpheus`.

- **Coarse** (3-state): supplied by `zeitR`.

All downstream metric functions are resolution-agnostic: they compute
what is possible given the available stages and document which metrics
require full AASM staging.

## Examples

``` r
if (FALSE) { # \dontrun{
hyp <- read_hypnogram("night_001.csv")
hyp <- read_hypnogram("night_001.edf", format = "edf_annotations")
} # }
```
