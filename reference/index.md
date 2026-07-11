# Package index

## Constructors

Build the hypnor_hypnogram object used by every other function.

- [`new_hypnogram()`](https://hypnor.circadia-lab.uk/reference/new_hypnogram.md)
  : Construct a hypnoR hypnogram object

## Preprocessing

Clean up and window a hypnogram before computing metrics.

- [`smooth_hypnogram()`](https://hypnor.circadia-lab.uk/reference/smooth_hypnogram.md)
  : Smooth a hypnogram by reassigning short, likely-spurious runs
- [`window_hypnogram()`](https://hypnor.circadia-lab.uk/reference/window_hypnogram.md)
  : Restrict a hypnogram to a time or epoch window

## Ingestion

Read hypnograms from common file formats.

- [`read_hypnogram()`](https://hypnor.circadia-lab.uk/reference/read_hypnogram.md)
  : Read a hypnogram from file

## Architecture metrics

Compute summary sleep architecture statistics.

- [`compute_sleep_architecture()`](https://hypnor.circadia-lab.uk/reference/compute_sleep_architecture.md)
  : Compute sleep architecture metrics

## Cycle segmentation

Detect NREM/REM sleep cycles.

- [`compute_cycles()`](https://hypnor.circadia-lab.uk/reference/compute_cycles.md)
  : Detect NREM/REM sleep cycles

## Transition analysis

Stage-to-stage transitions and fragmentation indices.

- [`compute_transitions()`](https://hypnor.circadia-lab.uk/reference/compute_transitions.md)
  : Compute stage-transition statistics

## Plotting

Publication-ready hypnogram and architecture visualisations.

- [`plot_hypnogram()`](https://hypnor.circadia-lab.uk/reference/plot_hypnogram.md)
  : Plot a hypnogram
- [`plot_architecture()`](https://hypnor.circadia-lab.uk/reference/plot_architecture.md)
  : Plot sleep architecture as a bar chart
- [`plot_transition_matrix()`](https://hypnor.circadia-lab.uk/reference/plot_transition_matrix.md)
  : Plot a stage-transition heatmap

## Package

Package-level documentation.

- [`hypnoR`](https://hypnor.circadia-lab.uk/reference/hypnoR-package.md)
  [`hypnoR-package`](https://hypnor.circadia-lab.uk/reference/hypnoR-package.md)
  : hypnoR: Hypnogram Handling, Plotting, and Sleep Architecture Metrics
