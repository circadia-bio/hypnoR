#' Construct a hypnoR hypnogram object
#'
#' `new_hypnogram()` is the low-level constructor for the `hypnor_hypnogram`
#' class used throughout `hypnoR`. It normalises hypnogram-shaped input --
#' whether a bare tibble (as produced by `zeitR::export_hypnogram()` or
#' [read_hypnogram()]) or a specially classed object (currently:
#' `mrpheus::export_hypnogram()`'s `mrpheus_hypnogram`) -- into the single
#' internal representation that every other `hypnoR` function expects.
#'
#' @param x A data frame with at minimum `epoch` and `stage` columns, or an
#'   object with a dedicated `new_hypnogram()` method (currently:
#'   `mrpheus_hypnogram`). Recognised optional columns: `time` (`POSIXct`),
#'   `subject_id`, `source`.
#' @param epoch_sec Epoch duration in seconds. When `x` carries its own
#'   epoch duration (e.g. an `mrpheus_hypnogram`'s `epoch_s` attribute) that
#'   value is used unless `epoch_sec` is explicitly supplied here. Falls
#'   back to `30L` when no value can be determined from either source.
#' @param resolution `"aasm"`, `"coarse"`, or `NULL` (default). When `NULL`,
#'   resolution is auto-detected from the stage labels present in `x` (or,
#'   for `mrpheus_hypnogram` input, taken from its `resolution` attribute).
#' @param subject_id Character or `NULL`. Overrides any subject/participant
#'   identifier carried by `x`.
#' @param source Character or `NULL`. Overrides any source/scorer label
#'   carried by `x`.
#' @param ... Passed to methods; currently unused.
#'
#' @return A tibble of class `hypnor_hypnogram` with columns `epoch`
#'   (integer), `time` (`POSIXct`, `NA` if unknown), `stage` (ordered
#'   factor), `subject_id` (character, `NA` if unknown), and `source`
#'   (character, `NA` if unknown). The detected `epoch_sec` and
#'   `resolution` are attached as attributes.
#'
#' @export
#' @examples
#' \dontrun{
#' # From a bare tibble (e.g. zeitR::export_hypnogram() output)
#' new_hypnogram(zeitr_hyp)
#'
#' # From mrpheus::export_hypnogram() output
#' new_hypnogram(mrpheus_hyp)
#' }
new_hypnogram <- function(x, ...) {
  UseMethod("new_hypnogram")
}

#' @export
#' @rdname new_hypnogram
new_hypnogram.default <- function(x,
                                  epoch_sec  = NULL,
                                  resolution = NULL,
                                  subject_id = NULL,
                                  source     = NULL,
                                  ...) {
  if (!is.data.frame(x)) {
    cli::cli_abort(c(
      "{.arg x} must be a data frame with {.field epoch} and {.field stage} columns.",
      "x" = "Got an object of class {.cls {class(x)}}."
    ))
  }

  required <- c("epoch", "stage")
  missing  <- setdiff(required, names(x))
  if (length(missing) > 0L) {
    cli::cli_abort(
      "{.arg x} is missing required column(s): {.val {missing}}."
    )
  }

  epoch <- suppressWarnings(as.integer(x$epoch))
  if (anyNA(epoch)) {
    cli::cli_abort("{.field epoch} must be coercible to integer with no missing values.")
  }
  if (any(duplicated(epoch))) {
    cli::cli_abort("{.field epoch} contains duplicate values; each epoch must be unique.")
  }

  stage_chr <- as.character(x$stage)
  valid     <- c(.aasm_levels(), .coarse_levels())
  unknown   <- setdiff(unique(stage_chr[!is.na(stage_chr)]), valid)
  if (length(unknown) > 0L) {
    cli::cli_abort(c(
      "Unrecognised stage label(s): {.val {unknown}}.",
      "i" = "Valid labels are {.val {valid}}."
    ))
  }

  res <- tolower(as.character(resolution %||% .detect_resolution_chr(stage_chr)))
  if (!res %in% c("aasm", "coarse")) {
    cli::cli_abort(c(
      "{.arg resolution} must be {.val aasm} or {.val coarse}.",
      "x" = "Got {.val {res}}."
    ))
  }
  lvl       <- if (res == "aasm") .aasm_levels() else .coarse_levels()
  stage_fct <- factor(stage_chr, levels = lvl, ordered = TRUE)

  ord  <- order(epoch)
  time <- if ("time" %in% names(x)) {
    as.POSIXct(x$time)[ord]
  } else {
    as.POSIXct(rep(NA, length(epoch)))
  }

  sid <- subject_id
  if (is.null(sid)) {
    sid <- if ("subject_id" %in% names(x)) .first_non_na(x$subject_id) else NA_character_
  }
  src <- source
  if (is.null(src)) {
    src <- if ("source" %in% names(x)) .first_non_na(x$source) else NA_character_
  }

  eps <- epoch_sec %||% attr(x, "epoch_sec") %||% attr(x, "epoch_s") %||% 30L

  out <- tibble::tibble(
    epoch      = epoch[ord],
    time       = time,
    stage      = stage_fct[ord],
    subject_id = as.character(sid),
    source     = as.character(src)
  )

  structure(
    out,
    class      = c("hypnor_hypnogram", class(out)),
    epoch_sec  = as.numeric(eps),
    resolution = res
  )
}

#' @export
#' @rdname new_hypnogram
new_hypnogram.mrpheus_hypnogram <- function(x,
                                            epoch_sec  = NULL,
                                            resolution = NULL,
                                            subject_id = NULL,
                                            source     = NULL,
                                            ...) {
  eps        <- epoch_sec %||% attr(x, "epoch_s") %||% 30L
  start_time <- attr(x, "start_time")
  sid        <- subject_id %||% attr(x, "participant_id")
  src        <- source %||% attr(x, "source") %||% "mrpheus"

  time <- if (!is.null(start_time)) {
    as.POSIXct(start_time) + (as.integer(x$epoch) - 1L) * eps
  } else {
    as.POSIXct(rep(NA, nrow(x)))
  }

  interim <- tibble::tibble(
    epoch      = as.integer(x$epoch),
    time       = time,
    stage      = as.character(x$stage),
    subject_id = if (!is.null(sid)) as.character(sid) else NA_character_,
    source     = as.character(src)
  )

  new_hypnogram.default(
    interim,
    epoch_sec  = eps,
    resolution = resolution %||% attr(x, "resolution"),
    subject_id = sid,
    source     = src
  )
}

#' @export
print.hypnor_hypnogram <- function(x, ...) {
  cli::cli_h1("hypnoR hypnogram")
  cli::cli_inform(c(
    "i" = "Epochs: {nrow(x)}",
    "i" = "Epoch length: {attr(x, 'epoch_sec')} s",
    "i" = "Resolution: {attr(x, 'resolution')}",
    "i" = "Subject: {x$subject_id[1] %||% 'unset'}"
  ))
  NextMethod()
  invisible(x)
}
