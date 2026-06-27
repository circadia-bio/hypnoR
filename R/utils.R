# Internal utilities for hypnoR
# Not exported.

# ── Staging resolution ────────────────────────────────────────────────────────

#' Detect staging resolution from a hypnogram tibble
#'
#' Returns `"aasm"` if the stage factor contains any of N1 / N2 / N3 / REM,
#' or `"coarse"` if only W / Sleep / Quiet sleep are present.
#'
#' @param hypnogram A hypnogram tibble with a `stage` column.
#' @return `"aasm"` or `"coarse"`.
#' @noRd
.detect_resolution <- function(hypnogram) {
  stages <- unique(as.character(hypnogram$stage))
  if (any(stages %in% c("N1", "N2", "N3", "REM"))) "aasm" else "coarse"
}

#' Standard AASM stage order (deepest sleep first, wake last)
#' @noRd
.aasm_levels <- function() c("N3", "N2", "N1", "REM", "W")

#' Standard coarse stage order
#' @noRd
.coarse_levels <- function() c("Quiet sleep", "Sleep", "W")

#' Convert epoch count to minutes
#' @noRd
.epochs_to_min <- function(n, epoch_sec) n * epoch_sec / 60

# ── Circadia visual integration ───────────────────────────────────────────────

# circadia is intentionally NOT listed in DESCRIPTION: it lives only on GitHub
# and pak cannot resolve it during CI. Once circadia has a stable public
# release, add it back under Suggests with Additional_repositories.
#
# Until then: .hypno_theme() and .hypno_stage_colours() provide self-contained
# fallbacks drawn from the sticker palette. All plot functions must call these
# helpers rather than circadia directly.

#' ggplot2 theme for hypnoR plots
#'
#' Returns `ggplot2::theme_minimal()` with Circadia Lab defaults applied.
#' When the circadia package is installed it will be upgraded to
#' `circadia::theme_circadia()` in a future release.
#'
#' @noRd
.hypno_theme <- function(base_size = 14, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) return(NULL)
  ggplot2::theme_minimal(base_size = base_size, ...) +
    ggplot2::theme(
      panel.grid       = ggplot2::element_blank(),
      axis.line.x      = ggplot2::element_line(),
      axis.line.y      = ggplot2::element_line()
    )
}

#' Built-in stage colour palette (hex sticker palette)
#'
#' Returns a named character vector of hex colours for all known stage labels.
#'
#' @noRd
.hypno_stage_colours <- function() {
  c(
    "W"           = "#F4AE52",   # amber  — wake
    "REM"         = "#C1EBE9",   # teal   — REM
    "N1"          = "#FFF7C5",   # cream  — light NREM
    "N2"          = "#1B3A5C",   # navy   — NREM
    "N3"          = "#4F252E",   # maroon — deep NREM
    "Sleep"       = "#1B3A5C",
    "Quiet sleep" = "#4F252E"
  )
}
