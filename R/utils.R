# ── ggplot2 NSE column names ──────────────────────────────────────────────────
# Referenced via bare names inside aes() in R/plot.R; declared here (rather
# than via the rlang .data pronoun) so ggplot2 stays a Suggests-only runtime
# check instead of a hard dependency, per the same reasoning as .hypno_theme().
#' @importFrom utils globalVariables
utils::globalVariables(c("x", "y", "stage", "value", "to", "from", "run_id"))

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

# ── Capsule-style hypnogram plotting helpers ─────────────────────────────────

#' Trace a rounded-rectangle polygon
#'
#' ggplot2 has no native rounded-rect geom, so pills are drawn as hand-traced
#' polygons: four quarter-arcs joined by the rect's straight edges (which
#' geom_polygon supplies automatically between consecutive arc endpoints).
#' Works with either plain numeric or POSIXct x0/x1 -- POSIXct + numeric
#' offsets remain POSIXct, so the same code path handles both the "hours"
#' and "time" x-axis modes in plot_hypnogram(style = "capsule").
#'
#' @param x0,x1 Left/right edges (numeric hours, or POSIXct).
#' @param y0,y1 Bottom/top edges (numeric, lane units).
#' @param rx Corner radius in x-units (already clamped to half-width by the
#'   caller).
#' @param ry Corner radius in y-units.
#' @param n_arc Points per quarter-arc. Default `8`.
#' @return A data frame with columns `x`, `y` tracing the polygon boundary.
#' @noRd
.rounded_bar_polygon <- function(x0, x1, y0, y1, rx, ry, n_arc = 8L) {
  rx <- max(as.numeric(rx), 1e-9)
  ry <- max(ry, 1e-9)

  arc <- function(cx, cy, theta0, theta1) {
    theta <- seq(theta0, theta1, length.out = n_arc)
    data.frame(x = cx + rx * cos(theta), y = cy + ry * sin(theta))
  }

  bl <- arc(x0 + rx, y0 + ry, pi,          3 * pi / 2)
  br <- arc(x1 - rx, y0 + ry, 3 * pi / 2,  2 * pi)
  tr <- arc(x1 - rx, y1 - ry, 0,           pi / 2)
  tl <- arc(x0 + rx, y1 - ry, pi / 2,      pi)

  rbind(bl, br, tr, tl)
}

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
    "W"           = "#FFF7C5",   # cream  — wake (rotated from N1)
    "REM"         = "#F4AE52",   # amber  — REM (rotated from wake)
    "N1"          = "#C1EBE9",   # teal   — light NREM (rotated from REM)
    "N2"          = "#1B3A5C",   # navy   — NREM
    "N3"          = "#4F252E",   # maroon — deep NREM
    "Sleep"       = "#1B3A5C",
    "Quiet sleep" = "#4F252E"
  )
}
