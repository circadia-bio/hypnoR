# Compute sleep architecture metrics

Derives standard sleep architecture summary statistics from a staged
hypnogram. All metrics are resolution-agnostic: the function computes
every metric that is possible given the available staging levels and
silently omits metrics that require stages not present in the hypnogram
(e.g. REM latency requires a full AASM hypnogram).

## Usage

``` r
compute_sleep_architecture(
  hypnogram,
  epoch_sec = 30L,
  lights_off = NULL,
  lights_on = NULL
)
```

## Arguments

- hypnogram:

  A tibble returned by
  [`read_hypnogram()`](https://hypnor.circadia-lab.uk/reference/read_hypnogram.md),
  or any tibble with at minimum columns `epoch` (integer) and `stage`
  (factor).

- epoch_sec:

  Epoch duration in seconds. Default `30`.

- lights_off, lights_on:

  Optional `POSIXct` timestamps for lights-off and lights-on. When
  supplied, TIB (time in bed) and SE (sleep efficiency) are computed
  relative to the recording period; otherwise the first and last sleep
  epoch bound the period.

## Value

A one-row tibble with columns:

- tst_min:

  Total sleep time (minutes).

- tib_min:

  Time in bed (minutes). `NA` if `lights_off`/`lights_on` not supplied.

- se_pct:

  Sleep efficiency (percent). `NA` if TIB unavailable.

- sol_min:

  Sleep onset latency (minutes).

- waso_min:

  Wake after sleep onset (minutes).

- rem_lat_min:

  REM latency (minutes). `NA` for coarse hypnograms.

- sws_lat_min:

  SWS (N3) latency (minutes). `NA` for coarse hypnograms.

- pct_n1,pct_n2,pct_n3,pct_rem:

  Stage percentages of TST. `NA` for stages absent in the hypnogram.

- pct_sleep,pct_quiet_sleep:

  Stage percentages for coarse hypnograms. `NA` for full AASM
  hypnograms.

- staging_resolution:

  `"aasm"` or `"coarse"`.

## Examples

``` r
if (FALSE) { # \dontrun{
hyp <- read_hypnogram("night_001.csv")
compute_sleep_architecture(hyp)
} # }
```
