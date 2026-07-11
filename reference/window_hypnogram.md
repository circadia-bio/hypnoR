# Restrict a hypnogram to a time or epoch window

Filters a hypnogram down to a sub-range, either by clock time
(`lights_off`/`lights_on`) or by epoch number (`from_epoch`/`to_epoch`),
re-attaching `epoch_sec` and `resolution` correctly on the result. This
is the single place windowing logic lives in hypnoR –
[`compute_cycles()`](https://hypnor.circadia-lab.uk/reference/compute_cycles.md)
and
[`compute_transitions()`](https://hypnor.circadia-lab.uk/reference/compute_transitions.md)
have no `lights_off`/`lights_on` arguments of their own; window first,
then pass the windowed hypnogram in.

## Usage

``` r
window_hypnogram(
  hypnogram,
  lights_off = NULL,
  lights_on = NULL,
  from_epoch = NULL,
  to_epoch = NULL
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
  automatically if not already a `hypnor_hypnogram`.

- lights_off, lights_on:

  `POSIXct` or `NULL`. Both must be supplied together. Requires
  `hypnogram` to carry real timestamps (i.e. `start_time` was supplied
  to
  [`new_hypnogram()`](https://hypnor.circadia-lab.uk/reference/new_hypnogram.md)
  or `mrpheus::export_hypnogram()`) – errors if `time` is entirely `NA`.
  Mutually exclusive with `from_epoch`/`to_epoch`.

- from_epoch, to_epoch:

  Integer or `NULL`. Either may be supplied alone (an open-ended
  window); defaults to the first/last epoch in `hypnogram` respectively.
  Mutually exclusive with `lights_off`/`lights_on`.

## Value

A `hypnor_hypnogram`, filtered to the window, with `epoch_sec` and
`resolution` carried over unchanged from the input – `resolution` is
*not* re-detected from the (possibly much smaller) windowed subset,
since a short window could plausibly contain no REM/N3 epochs and get
misdetected as `"coarse"` otherwise.

## Details

[`compute_sleep_architecture()`](https://hypnor.circadia-lab.uk/reference/compute_sleep_architecture.md)'s
own `lights_off`/`lights_on` arguments are sugar for calling this first:
passing them restricts `TST`, `SOL`, `WASO`, and every other metric to
the window, not just the `TIB`/`SE` denominator.

## Examples

``` r
if (FALSE) { # \dontrun{
hyp <- new_hypnogram(mrpheus_hyp)

# By clock time
hyp_night <- window_hypnogram(
  hyp,
  lights_off = as.POSIXct("2024-01-01 23:00:00", tz = "UTC"),
  lights_on  = as.POSIXct("2024-01-02 07:00:00", tz = "UTC")
)

# By epoch range (e.g. isolating a sleep period out of a longer recording)
hyp_sleep <- window_hypnogram(hyp, from_epoch = 1001L, to_epoch = 1950L)

compute_cycles(hyp_sleep)
compute_transitions(hyp_sleep)
} # }
```
