#' Plot a hypnogram
#'
#' Renders a classic stage-over-time hypnogram using `ggplot2` and
#' `theme_circadia()`.  Accepts both full AASM and coarse staging; the
#' y-axis order and colour mapping are set automatically from the staging
#' resolution detected in `hypnogram`.
#'
#' @param hypnogram A tibble returned by [read_hypnogram()].
#' @param epoch_sec Epoch duration in seconds, used to construct the
#'   time axis.  Default `30`.
#' @param colours Named character vector mapping stage labels to hex colours.
#'   Defaults to the Circadia Lab palette via `circadia::domain_colour_for()`,
#'   if available, otherwise a built-in fallback.
#' @param show_cycles If `TRUE` and cycle information is available (a `cycle`
#'   column is present in `hypnogram`), cycle boundaries are overlaid as
#'   vertical dashed lines.  Default `FALSE`.
#' @param title Optional plot title.
#'
#' @return A `ggplot` object.
#'
#' @export
#' @examples
#' \dontrun{
#' hyp <- read_hypnogram("night_001.csv")
#' plot_hypnogram(hyp)
#' }
plot_hypnogram <- function(hypnogram,
                           epoch_sec   = 30L,
                           colours     = NULL,
                           show_cycles = FALSE,
                           title       = NULL) {
  cli::cli_abort("plot_hypnogram() is not yet implemented.")
}


#' Plot sleep architecture as a bar chart
#'
#' Renders stage durations or percentages as a horizontal bar chart using
#' `ggplot2` and `theme_circadia()`.
#'
#' @param architecture A one-row tibble returned by
#'   [compute_sleep_architecture()], or a multi-row tibble for comparing
#'   multiple nights (requires a `night` or `id` grouping column).
#' @param metric `"duration"` (minutes, default) or `"percentage"` of TST.
#' @param colours Named character vector of stage colours.  See
#'   [plot_hypnogram()] for defaults.
#' @param title Optional plot title.
#'
#' @return A `ggplot` object.
#'
#' @export
#' @examples
#' \dontrun{
#' hyp  <- read_hypnogram("night_001.csv")
#' arch <- compute_sleep_architecture(hyp)
#' plot_architecture(arch)
#' }
plot_architecture <- function(architecture,
                              metric  = "duration",
                              colours = NULL,
                              title   = NULL) {
  cli::cli_abort("plot_architecture() is not yet implemented.")
}


#' Plot a stage-transition heatmap
#'
#' Renders the transition probability (or count) matrix returned by
#' [compute_transitions()] as a heatmap using `ggplot2` and
#' `theme_circadia()`.
#'
#' @param transitions The `matrix` element of the list returned by
#'   [compute_transitions()].
#' @param label_values If `TRUE` (default), cell values are printed inside
#'   each tile.
#' @param digits Number of decimal places for cell labels.  Default `2`.
#' @param title Optional plot title.
#'
#' @return A `ggplot` object.
#'
#' @export
#' @examples
#' \dontrun{
#' hyp   <- read_hypnogram("night_001.csv")
#' trans <- compute_transitions(hyp)
#' plot_transition_matrix(trans$matrix)
#' }
plot_transition_matrix <- function(transitions,
                                   label_values = TRUE,
                                   digits       = 2L,
                                   title        = NULL) {
  cli::cli_abort("plot_transition_matrix() is not yet implemented.")
}
