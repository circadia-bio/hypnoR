#' Compute stage-transition statistics
#'
#' Builds a stage-to-stage transition probability matrix and derives
#' fragmentation indices from a staged hypnogram. Works with both full AASM
#' and coarse actigraphy-derived staging.
#'
#' Fragmentation metrics (`n_transitions`, `fragmentation_index`,
#' `wake_transitions`) are always computed from the full epoch sequence,
#' wake included, regardless of `include_wake` -- that argument only
#' controls the shape of the returned `matrix`.
#'
#' @param hypnogram A `hypnor_hypnogram` object as returned by
#'   [new_hypnogram()] or [read_hypnogram()], or any data frame with at
#'   minimum `epoch` and `stage` columns -- it will be passed through
#'   [new_hypnogram()] automatically if not already a `hypnor_hypnogram`.
#' @param normalise If `TRUE` (default), each row of the transition count
#'   matrix is divided by its row sum to give transition probabilities.
#'   Rows for a from-stage that is never visited are returned as `NA`
#'   rather than `NaN`. If `FALSE`, raw transition counts are returned.
#' @param include_wake If `TRUE` (default), `"W"` is included as a state in
#'   the transition matrix like any other stage (including `W`->`W`
#'   self-transitions). If `FALSE`, the matrix is restricted to sleep-stage
#'   transitions only: any transition into or out of `"W"` is excluded
#'   before the matrix is built.
#'
#' @return A list with two elements:
#'   \describe{
#'     \item{matrix}{A tibble with one row per *from* stage: a `from`
#'       column plus one numeric column per *to* stage (transition
#'       probabilities or counts).}
#'     \item{fragmentation}{A one-row tibble with:
#'       \describe{
#'         \item{n_transitions}{Number of epoch-to-epoch stage changes
#'           (self-transitions do not count).}
#'         \item{fragmentation_index}{Proportion of epochs that are
#'           followed by a different stage.}
#'         \item{wake_transitions}{Number of transitions into Wake (proxy
#'           for arousal burden).}
#'       }
#'     }
#'   }
#'
#' @export
#' @examples
#' \dontrun{
#' hyp  <- read_hypnogram("night_001.csv")
#' trans <- compute_transitions(hyp)
#' trans$matrix
#' trans$fragmentation
#'
#' # Sleep-stage transitions only, excluding Wake
#' compute_transitions(hyp, include_wake = FALSE)
#' }
compute_transitions <- function(hypnogram,
                                normalise    = TRUE,
                                include_wake = TRUE) {
  if (!inherits(hypnogram, "hypnor_hypnogram")) {
    hypnogram <- new_hypnogram(hypnogram)
  }

  res   <- attr(hypnogram, "resolution") %||% .detect_resolution(hypnogram)
  stage <- as.character(hypnogram$stage)
  n     <- length(stage)

  if (n < 2L) {
    cli::cli_abort("{.arg hypnogram} must have at least 2 epochs to compute transitions.")
  }

  levels <- if (res == "aasm") .aasm_levels() else .coarse_levels()

  from <- stage[-n]
  to   <- stage[-1L]

  # Fragmentation always uses the full sequence, wake included, regardless
  # of `include_wake` (which only shapes the returned matrix below).
  changed             <- from != to
  n_transitions        <- sum(changed)
  fragmentation_index <- n_transitions / (n - 1L)
  wake_transitions     <- sum(changed & to == "W")

  fragmentation <- tibble::tibble(
    n_transitions        = n_transitions,
    fragmentation_index  = fragmentation_index,
    wake_transitions      = wake_transitions
  )

  mat_levels <- if (isTRUE(include_wake)) levels else setdiff(levels, "W")

  keep   <- from %in% mat_levels & to %in% mat_levels
  from_f <- factor(from[keep], levels = mat_levels)
  to_f   <- factor(to[keep],   levels = mat_levels)

  counts     <- table(from = from_f, to = to_f)
  counts_mat <- matrix(
    as.integer(counts),
    nrow      = length(mat_levels),
    dimnames  = list(mat_levels, mat_levels)
  )

  if (isTRUE(normalise)) {
    row_sums          <- rowSums(counts_mat)
    out_mat           <- counts_mat / row_sums
    out_mat[row_sums == 0, ] <- NA_real_
  } else {
    out_mat <- counts_mat
  }

  mat_tbl <- tibble::as_tibble(out_mat, rownames = "from")
  mat_tbl <- mat_tbl[, c("from", mat_levels)]

  list(
    matrix        = mat_tbl,
    fragmentation = fragmentation
  )
}
