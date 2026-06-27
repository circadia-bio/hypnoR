# Getting started with hypnoR

## Overview

**hypnoR** is the hypnogram layer of the Circadia Lab R ecosystem. It
accepts staged hypnograms from two upstream sources:

- **mrpheus** — full AASM staging: `W` / `N1` / `N2` / `N3` / `REM`
- **zeitR** — coarse actigraphy-derived staging: `W` / `Sleep` /
  `Quiet sleep`

All metric functions are *resolution-agnostic*: they compute what is
possible given the available stages and document which outputs require
full AASM staging.

## Installation

``` r

# install.packages("remotes")
remotes::install_github("circadia-bio/hypnoR")
```

## Basic workflow

``` r

library(hypnoR)

# 1. Read a hypnogram
hyp <- read_hypnogram("path/to/hypnogram.csv")

# 2. Compute sleep architecture metrics
arch <- compute_sleep_architecture(hyp)

# 3. Detect NREM/REM cycles (full AASM only)
cyc <- compute_cycles(hyp)

# 4. Stage-transition analysis
trans <- compute_transitions(hyp)

# 5. Plot
plot_hypnogram(hyp)
plot_architecture(arch)
plot_transition_matrix(trans$matrix)
```

## Supported input formats

[`read_hypnogram()`](https://hypnor.circadia-lab.uk/reference/read_hypnogram.md)
currently handles:

| Format                             | Argument            |
|------------------------------------|---------------------|
| Generic CSV (epoch, stage columns) | `"csv"`             |
| EDF+ annotations                   | `"edf_annotations"` |
| YASA output                        | `"yasa"`            |
| Compumedics Profusion              | `"compumedics"`     |
| Nox Medical                        | `"nox"`             |

Pass `format = "auto"` (the default) to infer the format from the file
header and extension.

## Staging resolution

hypnoR detects resolution automatically from the stage labels present in
the hypnogram. Metrics that require full AASM staging (REM latency, SWS
latency, cycle detection, N1/N2/N3 percentages) return `NA` with an
informative message for coarse hypnograms.
