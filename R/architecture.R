#' Compute sleep architecture metrics
#'
#' Derives standard sleep architecture summary statistics from a staged
#' hypnogram.  All metrics are resolution-agnostic: the function computes
#' every metric that is possible given the available staging levels and
#' silently omits metrics that require stages not present in the hypnogram
#' (e.g. REM latency requires a full AASM hypnogram).
#'
#' @param hypnogram A tibble returned by [read_hypnogram()], or any tibble
#'   with at minimum columns `epoch` (integer) and `stage` (factor).
#' @param epoch_sec Epoch duration in seconds.  Default `30`.
#' @param lights_off,lights_on Optional `POSIXct` timestamps for lights-off and
#'   lights-on.  When supplied, TIB (time in bed) and SE (sleep efficiency) are
#'   computed relative to the recording period; otherwise the first and last
#'   sleep epoch bound the period.
#'
#' @return A one-row tibble with columns:
#'   \describe{
#'     \item{tst_min}{Total sleep time (minutes).}
#'     \item{tib_min}{Time in bed (minutes).  `NA` if `lights_off`/`lights_on`
#'       not supplied.}
#'     \item{se_pct}{Sleep efficiency (percent).  `NA` if TIB unavailable.}
#'     \item{sol_min}{Sleep onset latency (minutes).}
#'     \item{waso_min}{Wake after sleep onset (minutes).}
#'     \item{rem_lat_min}{REM latency (minutes).  `NA` for coarse hypnograms.}
#'     \item{sws_lat_min}{SWS (N3) latency (minutes).  `NA` for coarse
#'       hypnograms.}
#'     \item{pct_n1,pct_n2,pct_n3,pct_rem}{Stage percentages of TST.  `NA`
#'       for stages absent in the hypnogram.}
#'     \item{pct_sleep,pct_quiet_sleep}{Stage percentages for coarse
#'       hypnograms.  `NA` for full AASM hypnograms.}
#'     \item{staging_resolution}{`"aasm"` or `"coarse"`.}
#'   }
#'
#' @export
#' @examples
#' \dontrun{
#' hyp <- read_hypnogram("night_001.csv")
#' compute_sleep_architecture(hyp)
#' }
compute_sleep_architecture <- function(hypnogram,
                                       epoch_sec  = 30L,
                                       lights_off = NULL,
                                       lights_on  = NULL) {
  cli::cli_abort("compute_sleep_architecture() is not yet implemented.")
}
