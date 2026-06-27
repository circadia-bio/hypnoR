#' Compute stage-transition statistics
#'
#' Builds a stage-to-stage transition probability matrix and derives
#' fragmentation indices from a staged hypnogram.  Works with both
#' full AASM and coarse actigraphy-derived staging.
#'
#' @param hypnogram A tibble returned by [read_hypnogram()].
#' @param normalise If `TRUE` (default), each row of the transition count
#'   matrix is divided by its row sum to give transition probabilities.
#'   If `FALSE`, raw transition counts are returned.
#'
#' @return A list with two elements:
#'   \describe{
#'     \item{matrix}{A square tibble (stages × stages) of transition
#'       probabilities or counts.  Row = *from* stage, column = *to* stage.}
#'     \item{fragmentation}{A one-row tibble with:
#'       \describe{
#'         \item{n_transitions}{Total number of stage transitions.}
#'         \item{fragmentation_index}{Proportion of epochs that are
#'           followed by a different stage.}
#'         \item{wake_transitions}{Number of transitions to Wake (proxy for
#'           arousal burden).}
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
#' }
compute_transitions <- function(hypnogram, normalise = TRUE) {
  cli::cli_abort("compute_transitions() is not yet implemented.")
}
