# Smooth a hypnogram by reassigning short, likely-spurious runs

Raw automatic sleep staging is typically a per-epoch classification with
no temporal continuity constraint (e.g. `mrpheus::stage_epochs()` is a
pure per-epoch argmax over posterior probabilities), which can produce
brief, isolated stage flips inconsistent with sleep physiology – a
single REM epoch nested inside an N2 run, for instance.
`smooth_hypnogram()` offers two independent, rule-based cleanup passes
that operate purely on stage labels (no posterior probabilities
required, and none are carried through by
[`new_hypnogram()`](https://hypnor.circadia-lab.uk/reference/new_hypnogram.md)
in any case).

## Usage

``` r
smooth_hypnogram(hypnogram, method = "aasm_isolated", min_run_epochs = 2L)
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

- method:

  One or more of `"aasm_isolated"` (default) and `"min_run"`. When both
  are requested, `"aasm_isolated"` is always applied first, then
  `"min_run"` – regardless of the order the two are given in `method`:

  `"aasm_isolated"`

  :   A single epoch whose stage differs from both of its immediate
      neighbours is reassigned to the neighbours' stage, but only when
      both neighbours share the *same* stage. This mirrors the
      conservative manual-scoring convention of resolving an ambiguous
      single epoch bounded identically on both sides. It never touches a
      run of 2+ epochs, and never touches an isolated epoch whose two
      neighbours disagree with each other.

  `"min_run"`

  :   Any run shorter than `min_run_epochs` is reassigned to whichever
      flanking run is longer (ties favour the preceding run). Broader
      than `"aasm_isolated"`: it does not require the two flanking runs
      to agree with each other, and (with `min_run_epochs > 2`) can
      merge runs longer than a single epoch. Applied as a single
      left-to-right pass over the run-length structure computed at the
      start of this step – it is not iterated to a fixed point, so a
      pathological hypnogram may still contain runs shorter than
      `min_run_epochs` afterwards. Call `smooth_hypnogram()` again on
      the result for a second pass if needed. Note that if
      `"aasm_isolated"` ran first, it may already have merged some runs
      together, which changes the flanking-run lengths `"min_run"` sees
      – the two methods are genuinely sequential, not independent.

- min_run_epochs:

  Only used by `"min_run"`. Minimum run length (in epochs) to leave
  untouched. Default `2L` (merges only single-epoch runs).

## Value

The input `hypnor_hypnogram`, with two changes: `stage` now holds the
smoothed labels, and a new `stage_raw` column preserves the original,
unsmoothed labels for comparison/audit. All other columns and attributes
(`epoch_sec`, `resolution`) are unchanged.

## Examples

``` r
if (FALSE) { # \dontrun{
hyp        <- new_hypnogram(mrpheus_hyp)
hyp_smooth <- smooth_hypnogram(hyp)
mean(hyp_smooth$stage != hyp_smooth$stage_raw)  # proportion of epochs changed

# Broader cleanup: also merge non-isolated short runs
smooth_hypnogram(hyp, method = c("aasm_isolated", "min_run"), min_run_epochs = 3)
} # }
```
