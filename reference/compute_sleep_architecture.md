# Compute sleep architecture metrics

Derives standard sleep architecture summary statistics from a staged
hypnogram. All metrics are resolution-agnostic: the function computes
every metric that is possible given the available staging levels and
returns `NA` for metrics that require stages not present at the detected
resolution (e.g. REM/SWS latency and AASM stage percentages require a
full AASM hypnogram).

## Usage

``` r
compute_sleep_architecture(hypnogram, lights_off = NULL, lights_on = NULL)
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
  automatically if not already a `hypnor_hypnogram`. Epoch duration and
  staging resolution are read from the object's `epoch_sec` and
  `resolution` attributes.

- lights_off, lights_on:

  Optional `POSIXct` timestamps for lights-off and lights-on. When both
  are supplied, `hypnogram` is first restricted to this window via
  [`window_hypnogram()`](https://hypnor.circadia-lab.uk/reference/window_hypnogram.md)
  – every metric (`TST`, `SOL`, `WASO`, stage percentages, everything)
  is computed relative to the window, not just `TIB`/`SE`. Otherwise
  `TIB` defaults to the full span of `hypnogram` as passed in (first to
  last epoch).

## Value

A one-row tibble with columns:

- tst_min:

  Total sleep time (minutes).

- tib_min:

  Time in bed (minutes).

- se_pct:

  Sleep efficiency (percent) = TST / TIB \* 100.

- sol_min:

  Sleep onset latency (minutes). `NA` if no sleep epoch is present.

- waso_min:

  Wake after sleep onset (minutes): wake epochs between the first and
  last sleep epoch. `NA` if no sleep epoch is present.

- rem_lat_min:

  REM latency from sleep onset (minutes). `NA` for coarse hypnograms or
  if no REM epoch is present.

- sws_lat_min:

  SWS (N3) latency from sleep onset (minutes). `NA` for coarse
  hypnograms or if no N3 epoch is present.

- pct_n1,pct_n2,pct_n3,pct_rem:

  Stage percentages of TST. `NA` for coarse hypnograms.

- pct_sleep,pct_quiet_sleep:

  Stage percentages of TST for coarse hypnograms. `NA` for full AASM
  hypnograms.

- staging_resolution:

  `"aasm"` or `"coarse"`.

## Details

Sleep onset is defined as the first epoch with any non-`"W"` stage –
this applies uniformly to full AASM hypnograms (where `N1` counts as
sleep onset) and coarse hypnograms (where `"Sleep"` or `"Quiet sleep"`
both count).

## Examples

``` r
if (FALSE) { # \dontrun{
hyp <- read_hypnogram("night_001.csv")
compute_sleep_architecture(hyp)
} # }
```
