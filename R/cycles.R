#' Detect NREM/REM sleep cycles
#'
#' Segments a hypnogram into NREM/REM cycles using either Feinberg & Floyd
#' (1979) rules or a simplified AASM-compatible algorithm.  Only applicable
#' to full AASM hypnograms; returns an informative error for coarse
#' actigraphy-derived hypnograms.
#'
#' @param hypnogram A tibble returned by [read_hypnogram()].
#' @param method `"feinberg_floyd"` (default) or `"aasm"`.
#' @param epoch_sec Epoch duration in seconds.  Default `30`.
#' @param min_rem_epochs Minimum number of consecutive REM epochs to qualify
#'   as a REM period.  Default `5` (2.5 min at 30-s epochs).
#'
#' @return A tibble with one row per detected cycle:
#'   \describe{
#'     \item{cycle}{Integer cycle index.}
#'     \item{start_epoch,end_epoch}{First and last epoch of the cycle.}
#'     \item{nrem_min,rem_min}{Duration of NREM and REM portions (minutes).}
#'     \item{cycle_min}{Total cycle duration (minutes).}
#'   }
#'
#' @references
#' Feinberg, I., & Floyd, T. C. (1979). Systematic trends across the night
#' in human sleep cycles. *Psychophysiology*, 16(3), 283–291.
#'
#' @export
#' @examples
#' \dontrun{
#' hyp <- read_hypnogram("night_001.csv")
#' compute_cycles(hyp)
#' }
compute_cycles <- function(hypnogram,
                           method         = "feinberg_floyd",
                           epoch_sec      = 30L,
                           min_rem_epochs = 5L) {
  cli::cli_abort("compute_cycles() is not yet implemented.")
}
