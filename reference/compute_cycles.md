# Detect NREM/REM sleep cycles

Segments a full AASM hypnogram into NREM/REM cycles. A cycle is defined
as an NREM stretch followed by a qualifying REM period; only *complete*
cycles are returned – a trailing NREM stretch at the end of the
recording that is not followed by a qualifying REM period does not
produce a final row.

## Usage

``` r
compute_cycles(
  hypnogram,
  method = c("feinberg_floyd", "aasm"),
  min_rem_epochs = 5L,
  rem_gap_min = 15
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

- method:

  `"feinberg_floyd"` (default) or `"aasm"`:

  `"feinberg_floyd"`

  :   Feinberg & Floyd (1979)'s original, simplest rule: a REM period is
      any maximal contiguous run of REM epochs of at least
      `min_rem_epochs`. No tolerance for interruption – a single non-REM
      epoch ends the REM period.

  `"aasm"`

  :   A simplified AASM-compatible variant that tolerates brief non-REM
      interruptions within a REM period: consecutive REM runs separated
      by a gap of at most `rem_gap_min` minutes are merged into a single
      REM period before the `min_rem_epochs` threshold is applied to
      their combined REM epoch count. This is a practical approximation,
      not a citable AASM standard – the AASM manual itself does not
      define sleep-cycle segmentation rules.

- min_rem_epochs:

  Minimum number of REM epochs (after any merging under
  `method = "aasm"`) for a run to qualify as a REM period. Default `5`
  (2.5 min at 30-s epochs).

- rem_gap_min:

  Only used when `method = "aasm"`. Maximum gap, in minutes, of non-REM
  epochs between two REM runs for them to be merged into a single REM
  period. Default `15`.

## Value

A tibble with one row per detected (complete) cycle:

- cycle:

  Integer cycle index.

- start_epoch,end_epoch:

  First and last epoch of the cycle, using the values in
  `hypnogram$epoch` itself – not row position. These differ whenever
  `hypnogram` doesn't start at epoch 1 (e.g. after subsetting a larger
  recording to a sleep-period window).

- nrem_min,rem_min:

  Duration of the NREM and REM portions of the cycle (minutes).
  `nrem_min` is the whole non-REM portion of the cycle, including any
  brief interruption epochs absorbed into a merged REM period under
  `method = "aasm"`; `rem_min` counts only actual REM epochs.
  `nrem_min + rem_min == cycle_min`.

- cycle_min:

  Total cycle duration (minutes).

Zero rows if no qualifying REM period is found (e.g. no sleep, or no REM
at all).

## Details

Only applicable to full AASM hypnograms (coarse actigraphy-derived
hypnograms have no REM stage and so cannot be cycle-segmented); this
function errors on a coarse hypnogram rather than silently returning an
empty result.

## References

Feinberg, I., & Floyd, T. C. (1979). Systematic trends across the night
in human sleep cycles. *Psychophysiology*, 16(3), 283-291.

## Examples

``` r
if (FALSE) { # \dontrun{
hyp <- read_hypnogram("night_001.csv")
compute_cycles(hyp)
compute_cycles(hyp, method = "aasm", rem_gap_min = 10)
} # }
```
