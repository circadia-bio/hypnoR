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
