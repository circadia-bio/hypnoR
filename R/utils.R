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

# hypnoR uses circadia for colours and themes when it is installed, but runs
# completely standalone without it.  Never list circadia in DESCRIPTION —
# use .hypno_theme() and .hypno_stage_colours() everywhere instead of calling
# circadia directly.

#' Return theme_circadia() if circadia is installed, otherwise theme_minimal()
#' @noRd
.hypno_theme <- function(...) {
  if (requireNamespace("circadia", quietly = TRUE)) {
    circadia::theme_circadia(...)
  } else {
    if (requireNamespace("ggplot2", quietly = TRUE)) {
      ggplot2::theme_minimal(...)
    }
  }
}

#' Built-in stage colour fallback (drawn from the Circadia main palette)
#'
#' Returns a named character vector of hex colours for all known stage labels.
#' When circadia is installed, its palette is used instead.
#' @noRd
.hypno_stage_colours <- function() {
  fallback <- c(
    # AASM stages
    "W"           = "#FC544A",   # coral  — wake
    "REM"         = "#FFA75D",   # amber  — REM
    "N1"          = "#9BDFE2",   # teal   — light NREM
    "N2"          = "#4A9BBF",   # sky    — NREM
    "N3"          = "#014370",   # navy   — deep NREM
    # Coarse stages
    "Sleep"       = "#4A9BBF",
    "Quiet sleep" = "#014370"
  )
  if (requireNamespace("circadia", quietly = TRUE)) {
    # Allow circadia to override if it exports a stage colour map
    if (existsMethod <- exists("stage_colours", where = asNamespace("circadia"),
                               inherits = FALSE)) {
      return(circadia::stage_colours())
    }
  }
  fallback
}
