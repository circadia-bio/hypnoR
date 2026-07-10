# Internal utilities for hypnoR
# Not exported.

# ── Staging resolution ────────────────────────────────────────────────────────

#' Detect staging resolution from a character vector of stage labels
#'
#' Returns `"aasm"` if any of N1 / N2 / N3 / REM are present, or `"coarse"`
#' if only W / Sleep / Quiet sleep are present.
#'
#' @param stages_chr Character vector of stage labels.
#' @return `"aasm"` or `"coarse"`.
#' @noRd
.detect_resolution_chr <- function(stages_chr) {
  if (any(stages_chr %in% c("N1", "N2", "N3", "REM"))) "aasm" else "coarse"
}

#' Detect staging resolution from a hypnogram tibble
#'
#' @param hypnogram A hypnogram tibble with a `stage` column.
#' @return `"aasm"` or `"coarse"`.
#' @noRd
.detect_resolution <- function(hypnogram) {
  .detect_resolution_chr(as.character(hypnogram$stage))
}

#' Null-coalescing infix operator (internal, not exported)
#'
#' Package-local copy so hypnoR does not need to depend on rlang or a recent
#' R version (base `%||%` is R >= 4.4 only) just for this.
#'
#' @noRd
`%||%` <- function(x, y) if (is.null(x)) y else x

#' First non-NA element of a vector, or `NA_character_`
#' @noRd
.first_non_na <- function(v) {
  v <- v[!is.na(v)]
  if (length(v) > 0L) as.character(v[[1L]]) else NA_character_
}

#' Zero-row cycles tibble with the correct column types
#' @noRd
.empty_cycles_tibble <- function() {
  tibble::tibble(
    cycle       = integer(0),
    start_epoch = integer(0),
    end_epoch   = integer(0),
    nrem_min    = numeric(0),
    rem_min     = numeric(0),
    cycle_min   = numeric(0)
  )
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
