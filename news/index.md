# Changelog

## hypnoR 0.1.0 (2026-06)

### Initial scaffold

- Package skeleton:
  [`read_hypnogram()`](https://hypnor.circadia-lab.uk/reference/read_hypnogram.md),
  [`compute_sleep_architecture()`](https://hypnor.circadia-lab.uk/reference/compute_sleep_architecture.md),
  [`compute_cycles()`](https://hypnor.circadia-lab.uk/reference/compute_cycles.md),
  [`compute_transitions()`](https://hypnor.circadia-lab.uk/reference/compute_transitions.md),
  [`plot_hypnogram()`](https://hypnor.circadia-lab.uk/reference/plot_hypnogram.md),
  [`plot_architecture()`](https://hypnor.circadia-lab.uk/reference/plot_architecture.md),
  [`plot_transition_matrix()`](https://hypnor.circadia-lab.uk/reference/plot_transition_matrix.md).
- Staging-agnostic design: all metric functions accept both full AASM (W
  / N1 / N2 / N3 / REM) and coarse actigraphy-derived (W / Sleep / Quiet
  sleep) hypnograms.
- pkgdown site with Bootstrap 5 and Circadia Lab branding.
