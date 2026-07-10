#' Restrict a hypnogram to a time or epoch window
#'
#' Filters a hypnogram down to a sub-range, either by clock time
#' (`lights_off`/`lights_on`) or by epoch number (`from_epoch`/`to_epoch`),
#' re-attaching `epoch_sec` and `resolution` correctly on the result. This
#' is the single place windowing logic lives in hypnoR -- [compute_cycles()]
#' and [compute_transitions()] have no `lights_off`/`lights_on` arguments of
#' their own; window first, then pass the windowed hypnogram in.
#'
#' [compute_sleep_architecture()]'s own `lights_off`/`lights_on` arguments
#' are sugar for calling this first: passing them restricts `TST`, `SOL`,
#' `WASO`, and every other metric to the window, not just the `TIB`/`SE`
#' denominator.
#'
#' @param hypnogram A `hypnor_hypnogram` object as returned by
#'   [new_hypnogram()] or [read_hypnogram()], or any data frame with at
#'   minimum `epoch` and `stage` columns -- it will be passed through
#'   [new_hypnogram()] automatically if not already a `hypnor_hypnogram`.
#' @param lights_off,lights_on `POSIXct` or `NULL`. Both must be supplied
#'   together. Requires `hypnogram` to carry real timestamps (i.e.
#'   `start_time` was supplied to [new_hypnogram()] or
#'   `mrpheus::export_hypnogram()`) -- errors if `time` is entirely `NA`.
#'   Mutually exclusive with `from_epoch`/`to_epoch`.
#' @param from_epoch,to_epoch Integer or `NULL`. Either may be supplied
#'   alone (an open-ended window); defaults to the first/last epoch in
#'   `hypnogram` respectively. Mutually exclusive with
#'   `lights_off`/`lights_on`.
#'
#' @return A `hypnor_hypnogram`, filtered to the window, with `epoch_sec`
#'   and `resolution` carried over unchanged from the input -- `resolution`
#'   is *not* re-detected from the (possibly much smaller) windowed subset,
#'   since a short window could plausibly contain no REM/N3 epochs and get
#'   misdetected as `"coarse"` otherwise.
#'
#' @export
#' @examples
#' \dontrun{
#' hyp <- new_hypnogram(mrpheus_hyp)
#'
#' # By clock time
#' hyp_night <- window_hypnogram(
#'   hyp,
#'   lights_off = as.POSIXct("2024-01-01 23:00:00", tz = "UTC"),
#'   lights_on  = as.POSIXct("2024-01-02 07:00:00", tz = "UTC")
#' )
#'
#' # By epoch range (e.g. isolating a sleep period out of a longer recording)
#' hyp_sleep <- window_hypnogram(hyp, from_epoch = 1001L, to_epoch = 1950L)
#'
#' compute_cycles(hyp_sleep)
#' compute_transitions(hyp_sleep)
#' }
window_hypnogram <- function(hypnogram,
                             lights_off = NULL,
                             lights_on  = NULL,
                             from_epoch = NULL,
                             to_epoch   = NULL) {
  if (!inherits(hypnogram, "hypnor_hypnogram")) {
    hypnogram <- new_hypnogram(hypnogram)
  }

  time_based  <- !is.null(lights_off) || !is.null(lights_on)
  epoch_based <- !is.null(from_epoch) || !is.null(to_epoch)

  if (time_based && epoch_based) {
    cli::cli_abort(
      "Specify either {.arg lights_off}/{.arg lights_on} or \\
       {.arg from_epoch}/{.arg to_epoch}, not both."
    )
  }
  if (!time_based && !epoch_based) {
    cli::cli_abort(
      "Specify a window: either {.arg lights_off}/{.arg lights_on} or \\
       {.arg from_epoch}/{.arg to_epoch}."
    )
  }

  if (time_based) {
    if (xor(is.null(lights_off), is.null(lights_on))) {
      cli::cli_abort("{.arg lights_off} and {.arg lights_on} must be supplied together.")
    }
    if (all(is.na(hypnogram$time))) {
      cli::cli_abort(c(
        "{.arg hypnogram} has no non-{.val NA} {.field time} values.",
        "i" = "Use {.arg from_epoch}/{.arg to_epoch} instead, or supply \\
               {.arg start_time} to {.fn new_hypnogram} / \\
               {.code mrpheus::export_hypnogram()} so real clock times are available."
      ))
    }
    keep <- hypnogram$time >= lights_off & hypnogram$time <= lights_on
  } else {
    lo <- from_epoch %||% min(hypnogram$epoch)
    hi <- to_epoch   %||% max(hypnogram$epoch)
    keep <- hypnogram$epoch >= lo & hypnogram$epoch <= hi
  }

  keep[is.na(keep)] <- FALSE
  if (!any(keep)) {
    cli::cli_abort("The requested window matches no epochs in {.arg hypnogram}.")
  }

  out <- hypnogram[keep, ]
  structure(
    out,
    class      = c("hypnor_hypnogram", setdiff(class(out), "hypnor_hypnogram")),
    epoch_sec  = attr(hypnogram, "epoch_sec"),
    resolution = attr(hypnogram, "resolution")
  )
}
