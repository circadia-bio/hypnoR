## hypnoR 0.1.0  (2026-06)

### Initial scaffold

* Package skeleton: `read_hypnogram()`, `compute_sleep_architecture()`,
  `compute_cycles()`, `compute_transitions()`, `plot_hypnogram()`,
  `plot_architecture()`, `plot_transition_matrix()`.
* Staging-agnostic design: all metric functions accept both full AASM
  (W / N1 / N2 / N3 / REM) and coarse actigraphy-derived
  (W / Sleep / Quiet sleep) hypnograms.
* pkgdown site with Bootstrap 5 and Circadia Lab branding.
