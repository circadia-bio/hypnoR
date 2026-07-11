# Getting started with hypnoR

``` r

library(hypnoR)
```

## Overview

**hypnoR** is the hypnogram layer of the Circadia Lab R ecosystem. It
takes a staged hypnogram from anywhere – **mrpheus** (full AASM: `W` /
`N1` / `N2` / `N3` / `REM`), **zeitR** (coarse actigraphy-derived: `W` /
`Sleep` / `Quiet sleep`), or a hand-built tibble – and turns it into
sleep architecture metrics, NREM/REM cycles, transition statistics, and
publication-ready plots.

Every metric and plotting function is **staging-agnostic**: it computes
whatever is possible given the resolution actually present, and returns
`NA` (documented per-function) for metrics that need finer staging than
what’s available.

This article walks through the whole pipeline using a real recording:
mrpheus’s bundled `SC4001E0` example – a 22-hour Sleep-EDF cassette
recording, already staged by mrpheus’s automatic sleep-staging model.

*mrpheus isn’t installed in the environment that built this article, so
the code below is shown but wasn’t executed. Install mrpheus to see it
run.*

## Installation

``` r

# install.packages("remotes")
remotes::install_github("circadia-bio/hypnoR")
```

## From mrpheus to hypnoR

``` r

staging <- readRDS(system.file("extdata", "SC4001E0_staging.rds", package = "mrpheus"))
staging
```

`staging` is mrpheus’s raw per-epoch output: one row per 30-second
epoch, an AASM `stage` label, and five posterior probabilities from the
underlying LightGBM classifier. `mrpheus::export_hypnogram()` prepares
it for hypnoR:

``` r

mrp_hyp <- mrpheus::export_hypnogram(
  staging,
  epoch_s        = 30,
  start_time     = as.POSIXct("2024-01-01 16:13:00", tz = "UTC"),
  participant_id = "SC4001"
)
```

(The real recording start time comes from the EDF header at
`mrpheus::read_edf()` time; the bundled `.rds` doesn’t carry it, so we
use a placeholder here based on the note in mrpheus’s own
`sleep-staging-demo` article that the cassette started around 16:13
local time.)

[`new_hypnogram()`](https://hypnor.circadia-lab.uk/reference/new_hypnogram.md)
– the constructor every other hypnoR function goes through – accepts
this directly:

``` r

hyp <- new_hypnogram(mrp_hyp)
hyp
```

Staging resolution (`aasm` here, since `N1` / `N2` / `N3` / `REM` are
present) and epoch duration are auto-detected and stored as attributes
on `hyp` – every other hypnoR function reads them from there rather than
asking you to repeat yourself.

## Preprocessing

Two optional cleanup steps happen before any metric sees the hypnogram.

### Smoothing

Automatic per-epoch staging with no temporal continuity constraint – as
here – can produce brief, isolated stage flips that don’t reflect real
sleep physiology (a single REM epoch nested inside an N2 run, for
instance).
[`smooth_hypnogram()`](https://hypnor.circadia-lab.uk/reference/smooth_hypnogram.md)
offers two label-only rules:

``` r

hyp_smooth <- smooth_hypnogram(hyp, method = c("aasm_isolated", "min_run"), min_run_epochs = 4)
mean(hyp_smooth$stage != hyp_smooth$stage_raw)
```

`aasm_isolated` reassigns a single epoch flanked identically on both
sides; `min_run` merges any run shorter than `min_run_epochs` into
whichever flanking run is longer, regardless of whether the flanks
agree. The original, unsmoothed labels are always preserved in
`stage_raw` for comparison.

### Windowing

`SC4001` is a 22-hour ambulatory recording – most of it is ordinary
daytime Wake before and after the one real sleep period. Running metrics
over the *entire* recording would badly distort things like sleep onset
latency and NREM/REM cycle counts, so
[`window_hypnogram()`](https://hypnor.circadia-lab.uk/reference/window_hypnogram.md)
restricts a hypnogram to a time or epoch window before any metric sees
it:

``` r

sleep_idx    <- which(as.character(hyp_smooth$stage) != "W")
onset_epoch  <- hyp_smooth$epoch[sleep_idx[1]]
offset_epoch <- hyp_smooth$epoch[sleep_idx[length(sleep_idx)]]

hyp_sleep <- window_hypnogram(hyp_smooth, from_epoch = onset_epoch, to_epoch = offset_epoch)
nrow(hyp_sleep)
```

[`compute_sleep_architecture()`](https://hypnor.circadia-lab.uk/reference/compute_sleep_architecture.md)
also accepts `lights_off`/`lights_on` directly and windows internally,
if you’d rather pass real lights-off/on timestamps than derive a window
from the data itself.

## Sleep architecture

``` r

arch <- compute_sleep_architecture(hyp_sleep)
arch
```

## Stage transitions

``` r

trans <- compute_transitions(hyp_sleep)
trans$matrix
trans$fragmentation
```

## NREM/REM cycles

``` r

cyc <- compute_cycles(hyp_sleep, method = "aasm")
cyc
```

## Plotting

Two hypnogram styles are available. `"step"` (the default) is the
classic clinical trace:

``` r

plot_hypnogram(hyp_sleep, cycles = cyc)
```

`"capsule"` draws rounded-pill bars per contiguous stage run, one lane
per stage:

``` r

plot_hypnogram(hyp_sleep, style = "capsule")
```

``` r

plot_architecture(arch)
```

``` r

plot_transition_matrix(trans$matrix)
```

## What isn’t here yet

[`read_hypnogram()`](https://hypnor.circadia-lab.uk/reference/read_hypnogram.md)
– ingesting hypnograms directly from CSV, EDF annotations, YASA,
Compumedics, or Nox export files – is still under development. For now,
hypnograms come from an upstream package (`mrpheus::export_hypnogram()`,
`zeitR::export_hypnogram()`) or a hand-built tibble passed to
[`new_hypnogram()`](https://hypnor.circadia-lab.uk/reference/new_hypnogram.md),
as shown above.

See `vignette("mrpheus-integration", package = "hypnoR")` (or the
“Worked examples” section of the pkgdown site) for a deeper,
warts-and-all walk through cleaning up and interpreting real automatic
staging output.
