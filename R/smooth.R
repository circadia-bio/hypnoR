#' Smooth a hypnogram by reassigning short, likely-spurious runs
#'
#' Raw automatic sleep staging is typically a per-epoch classification with
#' no temporal continuity constraint (e.g. `mrpheus::stage_epochs()` is a
#' pure per-epoch argmax over posterior probabilities), which can produce
#' brief, isolated stage flips inconsistent with sleep physiology -- a
#' single REM epoch nested inside an N2 run, for instance.
#' `smooth_hypnogram()` offers two independent, rule-based cleanup passes
#' that operate purely on stage labels (no posterior probabilities
#' required, and none are carried through by [new_hypnogram()] in any
#' case).
#'
#' @param hypnogram A `hypnor_hypnogram` object as returned by
#'   [new_hypnogram()] or [read_hypnogram()], or any data frame with at
#'   minimum `epoch` and `stage` columns -- it will be passed through
#'   [new_hypnogram()] automatically if not already a `hypnor_hypnogram`.
#' @param method One or more of `"aasm_isolated"` (default) and
#'   `"min_run"`. When both are requested, `"aasm_isolated"` is always
#'   applied first, then `"min_run"` -- regardless of the order the two
#'   are given in `method`:
#'   \describe{
#'     \item{`"aasm_isolated"`}{A single epoch whose stage differs from
#'       both of its immediate neighbours is reassigned to the
#'       neighbours' stage, but only when both neighbours share the
#'       *same* stage. This mirrors the conservative manual-scoring
#'       convention of resolving an ambiguous single epoch bounded
#'       identically on both sides. It never touches a run of 2+ epochs,
#'       and never touches an isolated epoch whose two neighbours
#'       disagree with each other.}
#'     \item{`"min_run"`}{Any run shorter than `min_run_epochs` is
#'       reassigned to whichever flanking run is longer (ties favour the
#'       preceding run). Broader than `"aasm_isolated"`: it does not
#'       require the two flanking runs to agree with each other, and
#'       (with `min_run_epochs > 2`) can merge runs longer than a single
#'       epoch. Applied as a single left-to-right pass over the
#'       run-length structure computed at the start of this step -- it
#'       is not iterated to a fixed point, so a pathological hypnogram
#'       may still contain runs shorter than `min_run_epochs` afterwards.
#'       Call `smooth_hypnogram()` again on the result for a second pass
#'       if needed. Note that if `"aasm_isolated"` ran first, it may
#'       already have merged some runs together, which changes the
#'       flanking-run lengths `"min_run"` sees -- the two methods are
#'       genuinely sequential, not independent.}
#'   }
#' @param min_run_epochs Only used by `"min_run"`. Minimum run length (in
#'   epochs) to leave untouched. Default `2L` (merges only single-epoch
#'   runs).
#'
#' @return The input `hypnor_hypnogram`, with two changes: `stage` now
#'   holds the smoothed labels, and a new `stage_raw` column preserves the
#'   original, unsmoothed labels for comparison/audit. All other columns
#'   and attributes (`epoch_sec`, `resolution`) are unchanged.
#'
#' @export
#' @examples
#' \dontrun{
#' hyp        <- new_hypnogram(mrpheus_hyp)
#' hyp_smooth <- smooth_hypnogram(hyp)
#' mean(hyp_smooth$stage != hyp_smooth$stage_raw)  # proportion of epochs changed
#'
#' # Broader cleanup: also merge non-isolated short runs
#' smooth_hypnogram(hyp, method = c("aasm_isolated", "min_run"), min_run_epochs = 3)
#' }
smooth_hypnogram <- function(hypnogram,
                             method         = "aasm_isolated",
                             min_run_epochs = 2L) {
  method <- match.arg(method, c("aasm_isolated", "min_run"), several.ok = TRUE)

  if (!is.numeric(min_run_epochs) || length(min_run_epochs) != 1L || min_run_epochs < 1L) {
    cli::cli_abort("{.arg min_run_epochs} must be a single number >= 1.")
  }

  if (!inherits(hypnogram, "hypnor_hypnogram")) {
    hypnogram <- new_hypnogram(hypnogram)
  }

  eps <- attr(hypnogram, "epoch_sec")
  res <- attr(hypnogram, "resolution")
  lvl <- levels(hypnogram$stage)

  stage_raw <- as.character(hypnogram$stage)
  stage     <- stage_raw

  if ("aasm_isolated" %in% method) {
    stage <- .smooth_aasm_isolated(stage)
  }
  if ("min_run" %in% method) {
    stage <- .smooth_min_run(stage, min_run_epochs)
  }

  out <- tibble::tibble(
    epoch      = hypnogram$epoch,
    time       = hypnogram$time,
    stage      = factor(stage,     levels = lvl, ordered = TRUE),
    stage_raw  = factor(stage_raw, levels = lvl, ordered = TRUE),
    subject_id = hypnogram$subject_id,
    source     = hypnogram$source
  )

  structure(
    out,
    class      = c("hypnor_hypnogram", class(out)),
    epoch_sec  = eps,
    resolution = res
  )
}

#' Reassign single isolated epochs flanked identically on both sides
#' @param stage Character vector of stage labels.
#' @return Character vector, same length.
#' @noRd
.smooth_aasm_isolated <- function(stage) {
  rl     <- rle(stage)
  n_runs <- length(rl$lengths)
  if (n_runs < 3L) return(stage)  # need both flanks to exist

  ends   <- cumsum(rl$lengths)
  starts <- ends - rl$lengths + 1L

  for (i in seq(2L, n_runs - 1L)) {
    if (rl$lengths[i] == 1L &&
       rl$values[i - 1L] == rl$values[i + 1L] &&
       rl$values[i]      != rl$values[i - 1L]) {
      stage[starts[i]] <- rl$values[i - 1L]
    }
  }
  stage
}

#' Merge any run shorter than min_run_epochs into its longer flanking run
#' @param stage Character vector of stage labels.
#' @param min_run_epochs Minimum run length to leave untouched.
#' @return Character vector, same length.
#' @noRd
.smooth_min_run <- function(stage, min_run_epochs) {
  rl     <- rle(stage)
  n_runs <- length(rl$lengths)
  if (n_runs < 2L) return(stage)  # single run overall, nothing to merge into

  ends   <- cumsum(rl$lengths)
  starts <- ends - rl$lengths + 1L

  for (i in seq_len(n_runs)) {
    if (rl$lengths[i] >= min_run_epochs) next

    left_len  <- if (i > 1L)     rl$lengths[i - 1L] else -1L
    right_len <- if (i < n_runs) rl$lengths[i + 1L] else -1L
    if (left_len < 0L && right_len < 0L) next  # shouldn't happen given n_runs >= 2

    new_value <- if (right_len > left_len) rl$values[i + 1L] else rl$values[i - 1L]
    stage[starts[i]:ends[i]] <- new_value
  }
  stage
}
