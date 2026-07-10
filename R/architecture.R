#' Compute sleep architecture metrics
#'
#' Derives standard sleep architecture summary statistics from a staged
#' hypnogram. All metrics are resolution-agnostic: the function computes
#' every metric that is possible given the available staging levels and
#' returns `NA` for metrics that require stages not present at the detected
#' resolution (e.g. REM/SWS latency and AASM stage percentages require a
#' full AASM hypnogram).
#'
#' Sleep onset is defined as the first epoch with any non-`"W"` stage --
#' this applies uniformly to full AASM hypnograms (where `N1` counts as
#' sleep onset) and coarse hypnograms (where `"Sleep"` or `"Quiet sleep"`
#' both count).
#'
#' @param hypnogram A `hypnor_hypnogram` object as returned by
#'   [new_hypnogram()] or [read_hypnogram()], or any data frame with at
#'   minimum `epoch` and `stage` columns -- it will be passed through
#'   [new_hypnogram()] automatically if not already a `hypnor_hypnogram`.
#'   Epoch duration and staging resolution are read from the object's
#'   `epoch_sec` and `resolution` attributes.
#' @param lights_off,lights_on Optional `POSIXct` timestamps for lights-off
#'   and lights-on. When both are supplied, `hypnogram` is first restricted
#'   to this window via [window_hypnogram()] -- every metric (`TST`, `SOL`,
#'   `WASO`, stage percentages, everything) is computed relative to the
#'   window, not just `TIB`/`SE`. Otherwise `TIB` defaults to the full span
#'   of `hypnogram` as passed in (first to last epoch).
#'
#' @return A one-row tibble with columns:
#'   \describe{
#'     \item{tst_min}{Total sleep time (minutes).}
#'     \item{tib_min}{Time in bed (minutes).}
#'     \item{se_pct}{Sleep efficiency (percent) = TST / TIB * 100.}
#'     \item{sol_min}{Sleep onset latency (minutes). `NA` if no sleep
#'       epoch is present.}
#'     \item{waso_min}{Wake after sleep onset (minutes): wake epochs
#'       between the first and last sleep epoch. `NA` if no sleep epoch
#'       is present.}
#'     \item{rem_lat_min}{REM latency from sleep onset (minutes). `NA` for
#'       coarse hypnograms or if no REM epoch is present.}
#'     \item{sws_lat_min}{SWS (N3) latency from sleep onset (minutes). `NA`
#'       for coarse hypnograms or if no N3 epoch is present.}
#'     \item{pct_n1,pct_n2,pct_n3,pct_rem}{Stage percentages of TST. `NA`
#'       for coarse hypnograms.}
#'     \item{pct_sleep,pct_quiet_sleep}{Stage percentages of TST for coarse
#'       hypnograms. `NA` for full AASM hypnograms.}
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
                                       lights_off = NULL,
                                       lights_on  = NULL) {
  if (!inherits(hypnogram, "hypnor_hypnogram")) {
    hypnogram <- new_hypnogram(hypnogram)
  }

  if (xor(is.null(lights_off), is.null(lights_on))) {
    cli::cli_warn(
      "Both {.arg lights_off} and {.arg lights_on} must be supplied together; ignoring."
    )
    lights_off <- NULL
    lights_on  <- NULL
  }

  windowed <- !is.null(lights_off) && !is.null(lights_on)
  if (windowed) {
    hypnogram <- window_hypnogram(hypnogram, lights_off = lights_off, lights_on = lights_on)
  }

  epoch_sec <- attr(hypnogram, "epoch_sec") %||% 30
  res       <- attr(hypnogram, "resolution") %||% .detect_resolution(hypnogram)

  stage <- as.character(hypnogram$stage)
  n     <- length(stage)

  asleep   <- stage != "W"
  n_asleep <- sum(asleep)

  tst_min <- .epochs_to_min(n_asleep, epoch_sec)

  sleep_idx <- which(asleep)
  onset_idx  <- if (n_asleep > 0L) sleep_idx[1L] else NA_integer_
  offset_idx <- if (n_asleep > 0L) sleep_idx[n_asleep] else NA_integer_

  sol_min <- if (!is.na(onset_idx)) {
    .epochs_to_min(onset_idx - 1L, epoch_sec)
  } else {
    NA_real_
  }

  waso_min <- if (n_asleep > 0L) {
    span <- stage[onset_idx:offset_idx]
    .epochs_to_min(sum(span == "W"), epoch_sec)
  } else {
    NA_real_
  }

  if (windowed) {
    tib_min <- as.numeric(difftime(lights_on, lights_off, units = "mins"))
  } else {
    tib_min <- .epochs_to_min(n, epoch_sec)
  }

  se_pct <- if (!is.na(tib_min) && tib_min > 0) tst_min / tib_min * 100 else NA_real_

  rem_lat_min <- NA_real_
  sws_lat_min <- NA_real_
  if (res == "aasm" && !is.na(onset_idx)) {
    rem_idx <- which(stage == "REM")
    if (length(rem_idx) > 0L) {
      rem_lat_min <- .epochs_to_min(rem_idx[1L] - onset_idx, epoch_sec)
    }
    n3_idx <- which(stage == "N3")
    if (length(n3_idx) > 0L) {
      sws_lat_min <- .epochs_to_min(n3_idx[1L] - onset_idx, epoch_sec)
    }
  }

  pct_of_tst <- function(label) {
    if (n_asleep == 0L) return(NA_real_)
    sum(stage == label) / n_asleep * 100
  }

  aasm <- res == "aasm"

  tibble::tibble(
    tst_min            = tst_min,
    tib_min            = tib_min,
    se_pct             = se_pct,
    sol_min            = sol_min,
    waso_min           = waso_min,
    rem_lat_min        = rem_lat_min,
    sws_lat_min        = sws_lat_min,
    pct_n1             = if (aasm) pct_of_tst("N1") else NA_real_,
    pct_n2             = if (aasm) pct_of_tst("N2") else NA_real_,
    pct_n3             = if (aasm) pct_of_tst("N3") else NA_real_,
    pct_rem            = if (aasm) pct_of_tst("REM") else NA_real_,
    pct_sleep          = if (aasm) NA_real_ else pct_of_tst("Sleep"),
    pct_quiet_sleep    = if (aasm) NA_real_ else pct_of_tst("Quiet sleep"),
    staging_resolution = res
  )
}
