# 😵‍💫 hypnoR

**Hypnogram handling, plotting, and sleep architecture metrics for R — the staging-agnostic layer of the Circadia Lab ecosystem.**

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

All metric functions are resolution-agnostic: they compute every metric that
is possible given the available stages and return `NA` with an informative
message for metrics that require full AASM staging.

Downstream, hypnoR feeds into `syncR::sync()` as part of the unified
participant-indexed database.

## ✨ Features

- **Flexible ingestion** — `read_hypnogram()` reads EDF annotations, CSV,
  YASA output, Compumedics Profusion, and Nox Medical formats.

- **Architecture metrics** — `compute_sleep_architecture()` returns TST, SE,
  SOL, WASO, REM latency, SWS latency, and stage percentages; all metrics
  degrade gracefully for coarse hypnograms.

- **Cycle segmentation** — `compute_cycles()` detects NREM/REM cycles via
  Feinberg & Floyd (1979) or AASM rules.

- **Transition analysis** — `compute_transitions()` builds a stage-to-stage
  transition probability matrix and computes a fragmentation index.

- **Publication-ready plots** — `plot_hypnogram()`, `plot_architecture()`, and
  `plot_transition_matrix()` all use `theme_circadia()` from the **circadia**
  shared visual identity package.

## 🗂️ Project Structure

```
hypnoR/
├── R/
│   ├── hypnoR-package.R       # package-level docs
│   ├── read_hypnogram.R       # ingestion
│   ├── architecture.R         # compute_sleep_architecture()
│   ├── cycles.R               # compute_cycles()
│   ├── transitions.R          # compute_transitions()
│   ├── plot.R                 # plot_hypnogram(), plot_architecture(),
│   │                          #   plot_transition_matrix()
│   └── utils.R                # internal helpers
├── tests/testthat/
├── vignettes/
│   └── getting-started.Rmd
├── man/figures/               # logo, favicon, card
├── .github/workflows/         # R CMD CHECK + pkgdown CI
├── _pkgdown.yml
└── DESCRIPTION
```

## 🚀 Getting Started

**Prerequisites:** R ≥ 4.1, `remotes`.

```r
remotes::install_github("circadia-bio/hypnoR")
```

**Basic workflow:**

```r
library(hypnoR)

hyp  <- read_hypnogram("night_001.csv")
arch <- compute_sleep_architecture(hyp)
cyc  <- compute_cycles(hyp)           # full AASM only
trans <- compute_transitions(hyp)

plot_hypnogram(hyp)
plot_architecture(arch)
plot_transition_matrix(trans$matrix)
```

## 📦 Dependencies

| Package | Role |
|---|---|
| `cli` | User-facing messages and errors |
| `dplyr` | Tabular data manipulation |
| `lubridate` | Timestamp handling |
| `rlang` | Tidy eval and error helpers |
| `tibble` | Tidy output objects |
| `tidyr` | Reshaping for transition matrices |
| `ggplot2` *(Suggests)* | Plotting |
| `circadia` *(Suggests)* | Shared colour palette and `theme_circadia()` |

## 👥 Authors

| Role | Name |
|---|---|
| Author, maintainer | [Lucas França](https://orcid.org/0000-0003-0853-1319) |
| Author | [Mario Leocadio-Miguel](https://orcid.org/0000-0002-7248-3529) |

Circadia Lab, Northumbria University.

## 🤝 Related Tools

- 📦 [**zeitR**](https://github.com/circadia-bio/zeitR) — wrist actigraphy analysis and circadian metrics; upstream source of coarse hypnograms
- 📦 [**mrpheus**](https://github.com/circadia-bio/mrpheus) — PSG signal analysis; upstream source of full AASM hypnograms
- 📦 [**syncR**](https://github.com/circadia-bio/syncR) — integrates zeitR, slumbR, tallieR, and hypnoR into a unified participant-indexed database
- 📦 [**circadia**](https://github.com/circadia-bio/circadia) — shared visual identity: palettes, themes, and scales
- 🔬 [**circadia-bio**](https://github.com/circadia-bio) — the Circadia Lab GitHub organisation

## 📄 Licence

Released under the [MIT License](./LICENSE).

Copyright © Lucas França, Mario Leocadio-Miguel, 2026
