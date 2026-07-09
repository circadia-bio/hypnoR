## hypnoR (development version)

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
