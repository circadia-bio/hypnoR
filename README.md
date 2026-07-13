# 😵‍💫 hypnoR

**Hypnogram handling, plotting, and sleep architecture metrics for R — the staging-agnostic layer of the Circadia Lab ecosystem.**

[![r-universe](https://circadia-bio.r-universe.dev/badges/hypnoR)](https://circadia-bio.r-universe.dev/hypnoR)
[![DOI](https://img.shields.io/badge/DOI-10.5281%2Fzenodo.21309263-blue)](https://doi.org/10.5281/zenodo.21309263)
[![R](https://img.shields.io/badge/R-%3E%3D4.1-276DC3)](https://www.r-project.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![R CMD CHECK](https://github.com/circadia-bio/hypnoR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/circadia-bio/hypnoR/actions/workflows/R-CMD-check.yaml)
[![Coverage](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/circadia-bio/hypnoR/gh-pages/badges/coverage.json)](https://github.com/circadia-bio/hypnoR/actions/workflows/pkgdown.yaml)

---

> ⚠️ **hypnoR is in early development and has not been formally tested.** The API may change without notice, estimation results have not yet been validated against a reference implementation, and the package has not undergone peer review. Use with caution and verify outputs independently before using in any research context.

---

## 📖 What is hypnoR?

hypnoR is the hypnogram layer of the Circadia Lab R ecosystem. It sits
between raw signal sources and the integrated participant database, providing
a common interface for sleep staging regardless of where the staging came from.

It accepts two staging resolutions:

- **Full AASM** (5-state: `W` / `N1` / `N2` / `N3` / `REM`) — supplied by **mrpheus**
- **Coarse** (3-state: `W` / `Sleep` / `Quiet sleep`) — supplied by **zeitR**

All metric and plotting functions are resolution-agnostic: they compute
every metric that is possible given the available stages and return `NA`
(documented per-function) for metrics that need finer staging than what's
available.

Downstream, hypnoR feeds into `syncR::sync()` as part of the unified
participant-indexed database.

## ✨ Features

- 🏗️ **`new_hypnogram()`** — the constructor everything else goes through.
  Accepts a bare tibble with `epoch`/`stage` columns (e.g.
  `zeitR::export_hypnogram()` output) or an `mrpheus_hypnogram` object
  (`mrpheus::export_hypnogram()` output), auto-detecting AASM vs coarse
  resolution and normalising both into one representation.

- 🧹 **`smooth_hypnogram()`** — cleans up isolated single-epoch stage flips
  from raw, unsmoothed per-epoch classifiers, via two label-only rules
  (`aasm_isolated`, `min_run`), applicable independently or in sequence.

- 🪟 **`window_hypnogram()`** — restricts a hypnogram to a time
  (`lights_off`/`lights_on`) or epoch (`from_epoch`/`to_epoch`) window
  before any metric sees it.

- 📐 **`compute_sleep_architecture()`** — TST, TIB, SE, SOL, WASO, REM/SWS
  latency, and stage percentages; degrades gracefully for coarse hypnograms.

- 🌙 **`compute_cycles()`** — NREM/REM cycle segmentation via
  Feinberg & Floyd (1979) (`method = "feinberg_floyd"`) or a gap-tolerant
  variant (`method = "aasm"`). Full AASM staging only.

- 🔀 **`compute_transitions()`** — stage-to-stage transition matrix (counts
  or probabilities) plus a fragmentation index and wake-transition count.

- 🎨 **`plot_hypnogram()`**, **`plot_architecture()`**, **`plot_transition_matrix()`**
  — publication-ready plots built on `ggplot2` (a runtime-checked, not hard,
  dependency) and a shared Circadia Lab colour palette. `plot_hypnogram()`
  supports two visual styles: `"step"` (classic clinical trace) and
  `"capsule"` (rounded-pill bars per stage run, one lane per stage).

### 🚧 Coming soon

- **`read_hypnogram()`** — direct ingestion from CSV, EDF annotations, YASA
  output, Compumedics Profusion, and Nox Medical files. Not yet
  implemented; for now, hypnograms come from an upstream package
  (`mrpheus::export_hypnogram()`, `zeitR::export_hypnogram()`) or a
  hand-built tibble passed to `new_hypnogram()`.

## 🗂️ Project Structure

```
hypnoR/
├── R/
│   ├── hypnoR-package.R        # package-level docs
│   ├── new_hypnogram.R         # new_hypnogram() constructor
│   ├── smooth.R                # smooth_hypnogram()
│   ├── window_hypnogram.R      # window_hypnogram()
│   ├── architecture.R          # compute_sleep_architecture()
│   ├── cycles.R                # compute_cycles()
│   ├── transitions.R           # compute_transitions()
│   ├── read_hypnogram.R        # ingestion (not yet implemented)
│   ├── plot.R                  # plot_hypnogram(), plot_architecture(),
│   │                           #   plot_transition_matrix()
│   └── utils.R                 # internal helpers, stage colour palette
├── tests/testthat/
├── vignettes/
│   ├── getting-started.Rmd
│   └── articles/
│       ├── mrpheus-integration.Rmd  # worked example: AASM/mrpheus
│       └── zeitR-integration.Rmd    # worked example: coarse/zeitR
├── man/figures/                # logo, favicon, card
├── .github/workflows/          # R CMD CHECK + pkgdown/coverage CI
├── _pkgdown.yml
└── DESCRIPTION
```

## 🚀 Getting Started

**Prerequisites:** R ≥ 4.1.

Install from [r-universe](https://circadia-bio.r-universe.dev) (recommended — pre-built binaries):

```r
install.packages(
  "hypnoR",
  repos = c("https://circadia-bio.r-universe.dev", "https://cloud.r-project.org")
)
```

Or install the development version from GitHub:

```r
# install.packages("remotes")
remotes::install_github("circadia-bio/hypnoR")
```

To reproduce the vignettes with real evaluated output (rather than just the
code), also install **mrpheus** and **zeitR** from their r-universe:

```r
install.packages(
  c("mrpheus", "zeitR"),
  repos = c("https://circadia-bio.r-universe.dev", "https://cloud.r-project.org")
)
```

**Basic workflow** (see `vignette("getting-started")` for the full walkthrough,
including where `staging`/`result` come from in each case):

```r
library(hypnoR)

# From mrpheus (full AASM)
hyp <- new_hypnogram(mrpheus::export_hypnogram(staging, epoch_s = 30))

# ...or from zeitR (coarse) -- same functions from here on, either way
hyp <- new_hypnogram(zeitR::export_hypnogram(result))

hyp   <- smooth_hypnogram(hyp)          # optional cleanup
arch  <- compute_sleep_architecture(hyp)
trans <- compute_transitions(hyp)
cyc   <- compute_cycles(hyp)            # full AASM only

plot_hypnogram(hyp, cycles = cyc)
plot_architecture(arch)
plot_transition_matrix(trans$matrix)
```

## 📦 Dependencies

| Package | Type | Role |
|---|---|---|
| `cli` | Imports | User-facing messages and errors |
| `stats` | Imports | Faceting in `plot_architecture()` |
| `tibble` | Imports | Tidy output objects |
| `utils` | Imports | NSE variable declarations for `ggplot2` |
| `ggplot2` | Suggests | Plotting — checked at runtime, not required to use the metric functions |
| `mrpheus`, `zeitR` | Suggests | Real-data vignettes (both on [circadia-bio's r-universe](https://circadia-bio.r-universe.dev)) |
| `covr`, `testthat` | Suggests | Test coverage and the test suite |
| `knitr`, `rmarkdown`, `pkgdown` | Suggests | Vignettes and documentation site |

## 👥 Authors

| Role | Name |
|---|---|
| Author, maintainer | [Lucas França](https://orcid.org/0000-0003-0853-1319) |
| Author | [Mario Leocadio-Miguel](https://orcid.org/0000-0002-7248-3529) |

Circadia Lab, Northumbria University.

## 📄 Citation

If you use hypnoR in your research, please cite it:

```bibtex
@software{franca_hypnor_2026,
  author  = {França, Lucas and Leocadio-Miguel, Mario},
  title   = {{hypnoR}: Hypnogram Handling, Plotting, and Sleep Architecture Metrics},
  year    = {2026},
  version = {0.1.1},
  doi     = {10.5281/zenodo.21309263},
  url     = {https://github.com/circadia-bio/hypnoR}
}
```

## 🤝 Related Tools

- 📦 [**zeitR**](https://github.com/circadia-bio/zeitR) — wrist actigraphy analysis and circadian metrics; upstream source of coarse hypnograms
- 📦 [**mrpheus**](https://github.com/circadia-bio/mrpheus) — PSG signal analysis; upstream source of full AASM hypnograms
- 📦 [**syncR**](https://github.com/circadia-bio/syncR) — integrates zeitR, slumbR, tallieR, and hypnoR into a unified participant-indexed database
- 🔬 [**circadia-bio**](https://github.com/circadia-bio) — the Circadia Lab GitHub organisation

## 📄 Licence

Released under the [MIT License](./LICENSE).

Copyright © Lucas França, Mario Leocadio-Miguel, 2026
