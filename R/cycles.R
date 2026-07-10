#' Detect NREM/REM sleep cycles
#'
#' Segments a full AASM hypnogram into NREM/REM cycles. A cycle is defined
#' as an NREM stretch followed by a qualifying REM period; only *complete*
#' cycles are returned -- a trailing NREM stretch at the end of the
#' recording that is not followed by a qualifying REM period does not
#' produce a final row.
#'
#' Only applicable to full AASM hypnograms (coarse actigraphy-derived
#' hypnograms have no REM stage and so cannot be cycle-segmented); this
#' function errors on a coarse hypnogram rather than silently returning an
#' empty result.
#'
#' @param hypnogram A `hypnor_hypnogram` object as returned by
#'   [new_hypnogram()] or [read_hypnogram()], or any data frame with at
#'   minimum `epoch` and `stage` columns -- it will be passed through
#'   [new_hypnogram()] automatically if not already a `hypnor_hypnogram`.
#'   Epoch duration is read from the object's `epoch_sec` attribute.
#' @param method `"feinberg_floyd"` (default) or `"aasm"`:
#'   \describe{
#'     \item{`"feinberg_floyd"`}{Feinberg & Floyd (1979)'s original,
#'       simplest rule: a REM period is any maximal contiguous run of REM
#'       epochs of at least `min_rem_epochs`. No tolerance for
#'       interruption -- a single non-REM epoch ends the REM period.}
#'     \item{`"aasm"`}{A simplified AASM-compatible variant that tolerates
#'       brief non-REM interruptions within a REM period: consecutive REM
#'       runs separated by a gap of at most `rem_gap_min` minutes are
#'       merged into a single REM period before the `min_rem_epochs`
#'       threshold is applied to their combined REM epoch count. This is
#'       a practical approximation, not a citable AASM standard -- the
#'       AASM manual itself does not define sleep-cycle segmentation
#'       rules.}
#'   }
#' @param min_rem_epochs Minimum number of REM epochs (after any merging
#'   under `method = "aasm"`) for a run to qualify as a REM period.
#'   Default `5` (2.5 min at 30-s epochs).
#' @param rem_gap_min Only used when `method = "aasm"`. Maximum gap, in
#'   minutes, of non-REM epochs between two REM runs for them to be
#'   merged into a single REM period. Default `15`.
#'
#' @return A tibble with one row per detected (complete) cycle:
#'   \describe{
#'     \item{cycle}{Integer cycle index.}
#'     \item{start_epoch,end_epoch}{First and last epoch of the cycle.}
#'     \item{nrem_min,rem_min}{Duration of the NREM and REM portions of
#'       the cycle (minutes). `nrem_min` is the whole non-REM portion of
#'       the cycle, including any brief interruption epochs absorbed into
#'       a merged REM period under `method = "aasm"`; `rem_min` counts
#'       only actual REM epochs. `nrem_min + rem_min == cycle_min`.}
#'     \item{cycle_min}{Total cycle duration (minutes).}
#'   }
#'   Zero rows if no qualifying REM period is found (e.g. no sleep, or no
#'   REM at all).
#'
#' @references
#' Feinberg, I., & Floyd, T. C. (1979). Systematic trends across the night
#' in human sleep cycles. *Psychophysiology*, 16(3), 283-291.
#'
#' @export
#' @examples
#' \dontrun{
#' hyp <- read_hypnogram("night_001.csv")
#' compute_cycles(hyp)
#' compute_cycles(hyp, method = "aasm", rem_gap_min = 10)
#' }
compute_cycles <- function(hypnogram,
                           method         = c("feinberg_floyd", "aasm"),
                           min_rem_epochs = 5L,
                           rem_gap_min    = 15) {
  method <- match.arg(method)

  if (!inherits(hypnogram, "hypnor_hypnogram")) {
    hypnogram <- new_hypnogram(hypnogram)
  }

  res <- attr(hypnogram, "resolution") %||% .detect_resolution(hypnogram)
  if (res != "aasm") {
    cli::cli_abort(c(
      "{.fn compute_cycles} requires a full AASM hypnogram.",
      "x" = "{.arg hypnogram} has {.val coarse} resolution (no REM stage), \\
             so NREM/REM cycles cannot be detected."
    ))
  }

  epoch_sec <- attr(hypnogram, "epoch_sec") %||% 30
  stage     <- as.character(hypnogram$stage)

  asleep    <- stage != "W"
  onset_idx <- if (any(asleep)) which(asleep)[1L] else NA_integer_

  if (is.na(onset_idx)) {
    return(.empty_cycles_tibble())
  }

  gap_epochs <- if (method == "aasm") {
    max(1L, round(rem_gap_min * 60 / epoch_sec))
  } else {
    0L
  }

  rem_periods <- .find_rem_periods(stage, min_rem_epochs, gap_epochs)
  if (nrow(rem_periods) == 0L) {
    return(.empty_cycles_tibble())
  }

  cycle_start <- onset_idx
  cyc <- integer(0); se <- integer(0); ee <- integer(0)
  nrem <- numeric(0); rem <- numeric(0); tot <- numeric(0)

  for (i in seq_len(nrow(rem_periods))) {
    rem_start <- rem_periods$start[i]
    rem_end   <- rem_periods$end[i]
    rem_n     <- rem_periods$n_rem_epochs[i]

    if (rem_start < cycle_start) next  # guard against pathological/synthetic input

    cyc_len   <- rem_end - cycle_start + 1L
    tot_min_i <- .epochs_to_min(cyc_len, epoch_sec)
    rem_min_i <- .epochs_to_min(rem_n, epoch_sec)

    cyc  <- c(cyc, length(cyc) + 1L)
    se   <- c(se, cycle_start)
    ee   <- c(ee, rem_end)
    nrem <- c(nrem, tot_min_i - rem_min_i)
    rem  <- c(rem, rem_min_i)
    tot  <- c(tot, tot_min_i)

    cycle_start <- rem_end + 1L
  }

  tibble::tibble(
    cycle       = cyc,
    start_epoch = se,
    end_epoch   = ee,
    nrem_min    = nrem,
    rem_min     = rem,
    cycle_min   = tot
  )
}

#' Identify REM periods from a stage vector, with optional gap-merging
#'
#' @param stage Character vector of stage labels.
#' @param min_rem_epochs Minimum combined REM epoch count for a (possibly
#'   merged) run to qualify as a REM period.
#' @param gap_epochs Maximum gap, in epochs, of non-REM epochs between two
#'   raw REM runs for them to be merged into one period. `0` disables
#'   merging entirely.
#' @return A tibble with columns `start`, `end` (epoch indices of the
#'   period), and `n_rem_epochs` (actual REM epoch count within it,
#'   excluding any merged-in gap epochs).
#' @noRd
.find_rem_periods <- function(stage, min_rem_epochs, gap_epochs) {
  empty <- tibble::tibble(start = integer(0), end = integer(0), n_rem_epochs = integer(0))

  rl    <- rle(stage)
  ends  <- cumsum(rl$lengths)
  starts <- ends - rl$lengths + 1L
  rem_i <- which(rl$values == "REM")

  if (length(rem_i) == 0L) return(empty)

  period_start_i <- rem_i[1L]
  period_end_i   <- rem_i[1L]
  period_rem_len <- rl$lengths[rem_i[1L]]

  out_start <- integer(0); out_end <- integer(0); out_n <- integer(0)

  flush <- function() {
    out_start <<- c(out_start, starts[period_start_i])
    out_end   <<- c(out_end,   ends[period_end_i])
    out_n     <<- c(out_n,     period_rem_len)
  }

  if (length(rem_i) > 1L) {
    for (k in 2:length(rem_i)) {
      i   <- rem_i[k]
      gap <- starts[i] - ends[period_end_i] - 1L
      if (gap <= gap_epochs) {
        period_end_i   <- i
        period_rem_len <- period_rem_len + rl$lengths[i]
      } else {
        flush()
        period_start_i <- i
        period_end_i   <- i
        period_rem_len <- rl$lengths[i]
      }
    }
  }
  flush()

  keep <- out_n >= min_rem_epochs
  tibble::tibble(start = out_start[keep], end = out_end[keep], n_rem_epochs = out_n[keep])
}
