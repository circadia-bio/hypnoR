## hypnoR (development version)

* Added `window_hypnogram()`: restricts a hypnogram to a time (`lights_off`/
  `lights_on`) or epoch (`from_epoch`/`to_epoch`) window, correctly
  preserving `epoch_sec` and `resolution` on the result rather than
  re-detecting them from the (possibly much smaller) subset. This is the
  single place windowing logic lives -- `compute_cycles()` and
  `compute_transitions()` have no `lights_off`/`lights_on` arguments of
  their own; window first, then pass the windowed hypnogram in.
* **Behaviour change:** `compute_sleep_architecture()`'s `lights_off`/
  `lights_on` arguments now restrict *every* metric via
  `window_hypnogram()`, not just `TIB`/`SE` as before -- previously `TST`,
  `SOL`, `WASO`, and stage percentages were computed over the entire
  hypnogram regardless of the window, which was inconsistent. Requires
  `hypnogram` to carry real timestamps; errors if `time` is entirely `NA`.
* **Bugfix:** `compute_cycles()`'s `start_epoch`/`end_epoch` columns were
  reporting row position within `hypnogram`, not the actual values in
  `hypnogram$epoch` -- identical whenever `epoch` runs `1:n` (true of every
  fixture in the test suite so far), but wrong for any hypnogram that
  doesn't start at epoch 1, e.g. after subsetting a longer recording down
  to a sleep-period window. Durations (`nrem_min`/`rem_min`/`cycle_min`)
  were unaffected, since those were already computed from row-position
  differences rather than the epoch column.
* Added `smooth_hypnogram()`, a hypnogram-level cleanup step for raw
  unsmoothed per-epoch staging (e.g. `mrpheus::stage_epochs()`, which has
  no temporal continuity constraint and can produce isolated single-epoch
  stage flips). Two label-only rules, applicable independently or in
  sequence: `"aasm_isolated"` (default) reassigns a single epoch flanked
  identically on both sides; `"min_run"` merges any run shorter than
  `min_run_epochs` into whichever flanking run is longer, regardless of
  whether the flanks agree. The original labels are preserved in a new
  `stage_raw` column.
* `plot_hypnogram()` gains an `x_axis` argument (`"auto"` (default),
  `"time"`, or `"hours"`). When the hypnogram carries real timestamps
  (i.e. `start_time` was supplied to `new_hypnogram()` or
  `mrpheus::export_hypnogram()`), the x-axis now shows actual clock time
  by default instead of always using elapsed hours since the first epoch.
* Implemented `plot_hypnogram()`, `plot_architecture()`, and
  `plot_transition_matrix()`. All three use a runtime `ggplot2` check
  rather than a hard dependency (consistent with the rest of the
  ecosystem) and share the built-in Circadia Lab stage colour palette.
  `plot_hypnogram()` takes an optional `cycles` argument (the tibble from
  `compute_cycles()`) to overlay cycle-boundary lines; `plot_architecture()`
  facets on a `night`/`id` column when present, for comparing nights.
* Implemented `compute_cycles()`: NREM/REM cycle segmentation for full AASM
  hypnograms, with two selectable algorithms. `method = "feinberg_floyd"`
  (default) treats any maximal contiguous REM run of at least
  `min_rem_epochs` as a REM period, with no tolerance for interruption.
  `method = "aasm"` merges REM runs separated by a gap of at most
  `rem_gap_min` minutes (default 15) into a single REM period before
  applying the `min_rem_epochs` threshold. Errors on coarse hypnograms,
  which have no REM stage to segment on.
* Implemented `compute_transitions()`: stage-to-stage transition matrix
  (counts or row-normalised probabilities) plus fragmentation index and
  wake-transition count. New `include_wake` argument controls whether
  Wake is included as a state in the matrix; fragmentation metrics always
  use the full epoch sequence regardless of this setting.
* Implemented `compute_sleep_architecture()`: TST, TIB, SE, SOL, WASO, REM/SWS
  latency, and stage percentages, all resolution-agnostic. Sleep onset is
  defined as the first non-`"W"` epoch for both AASM and coarse hypnograms.
  `epoch_sec` and staging resolution are now read automatically from the
  `hypnor_hypnogram` object rather than passed as arguments.
* Added `new_hypnogram()`, the constructor underlying all other hypnoR
  functions. Accepts either a bare tibble with `epoch`/`stage` columns
  (e.g. `zeitR::export_hypnogram()` output) or an `mrpheus_hypnogram`
  object (`mrpheus::export_hypnogram()` output), normalising both into a
  single `hypnor_hypnogram` representation. Staging resolution
  (AASM vs coarse) is auto-detected from the stage labels present.

## hypnoR 0.1.0  (2026-06)

### Initial scaffold

* Package skeleton: `read_hypnogram()`, `compute_sleep_architecture()`,
  `compute_cycles()`, `compute_transitions()`, `plot_hypnogram()`,
  `plot_architecture()`, `plot_transition_matrix()`.
* Staging-agnostic design: all metric functions accept both full AASM
  (W / N1 / N2 / N3 / REM) and coarse actigraphy-derived
  (W / Sleep / Quiet sleep) hypnograms.
* pkgdown site with Bootstrap 5 and Circadia Lab branding.
