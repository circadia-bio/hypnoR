# Detect NREM/REM sleep cycles

Segments a hypnogram into NREM/REM cycles using either Feinberg & Floyd
(1979) rules or a simplified AASM-compatible algorithm. Only applicable
to full AASM hypnograms; returns an informative error for coarse
actigraphy-derived hypnograms.

## Usage

``` r
compute_cycles(
  hypnogram,
  method = "feinberg_floyd",
  epoch_sec = 30L,
  min_rem_epochs = 5L
)
```

## Arguments

- hypnogram:

  A tibble returned by
  [`read_hypnogram()`](https://hypnor.circadia-lab.uk/reference/read_hypnogram.md).

- method:

  `"feinberg_floyd"` (default) or `"aasm"`.

- epoch_sec:

  Epoch duration in seconds. Default `30`.

- min_rem_epochs:

  Minimum number of consecutive REM epochs to qualify as a REM period.
  Default `5` (2.5 min at 30-s epochs).

## Value

A tibble with one row per detected cycle:

- cycle:

  Integer cycle index.

- start_epoch,end_epoch:

  First and last epoch of the cycle.

- nrem_min,rem_min:

  Duration of NREM and REM portions (minutes).

- cycle_min:

  Total cycle duration (minutes).

## References

Feinberg, I., & Floyd, T. C. (1979). Systematic trends across the night
in human sleep cycles. *Psychophysiology*, 16(3), 283–291.

## Examples

``` r
if (FALSE) { # \dontrun{
hyp <- read_hypnogram("night_001.csv")
compute_cycles(hyp)
} # }
```
