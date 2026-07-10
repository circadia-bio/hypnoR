#' Plot a hypnogram
#'
#' Renders a hypnogram using `ggplot2` and the Circadia Lab colour palette.
#' Accepts both full AASM and coarse staging; the lane order (deepest sleep
#' at the bottom, Wake at the top) and colour mapping are set automatically
#' from the staging levels present in `hypnogram`.
#'
#' @param hypnogram A `hypnor_hypnogram` object as returned by
#'   [new_hypnogram()] or [read_hypnogram()], or any data frame with at
#'   minimum `epoch` and `stage` columns -- it will be passed through
#'   [new_hypnogram()] automatically if not already a `hypnor_hypnogram`.
#'   Epoch duration is read from the object's `epoch_sec` attribute.
#' @param style `"step"` (default) or `"capsule"`:
#'   \describe{
#'     \item{`"step"`}{Classic clinical step-plot: one line tracing the
#'       stage at every epoch.}
#'     \item{`"capsule"`}{Rounded-pill bars per contiguous stage run, one
#'       lane per stage.}
#'   }
#' @param x_axis `"auto"` (default), `"time"`, or `"hours"`:
#'   \describe{
#'     \item{`"auto"`}{Uses actual clock time (from the `time` column) if
#'       `hypnogram` carries any non-`NA` timestamps, otherwise falls back
#'       to elapsed hours since the first epoch.}
#'     \item{`"time"`}{Forces clock time; errors if `time` is entirely
#'       `NA` (no `start_time` was supplied to [new_hypnogram()] or
#'       `mrpheus::export_hypnogram()`).}
#'     \item{`"hours"`}{Forces elapsed hours since the first epoch,
#'       regardless of whether real timestamps are available.}
#'   }
#' @param date_breaks Only used when plotting clock time. Passed to
#'   [ggplot2::scale_x_datetime()]'s `date_breaks`. Default `"2 hours"`.
#' @param cycles Optional: the tibble returned by [compute_cycles()]. When
#'   supplied, a dashed vertical line is drawn at the start of each cycle.
#' @param colours Named character vector mapping stage labels to hex
#'   colours. Defaults to a built-in palette drawn from the Circadia Lab
#'   colours. Pass your own named vector to override.
#' @param title Optional plot title.
#' @param corner_min Only used by `style = "capsule"`. Maximum pill corner
#'   radius, in minutes. Runs shorter than `2 * corner_min` get a
#'   proportionally smaller radius (so very brief runs render as fully
#'   rounded capsule/stadium shapes rather than having oversized corners),
#'   longer runs are capped at this radius. Default `9`.
#'
#' @return A `ggplot` object.
#'
#' @export
#' @examples
#' \dontrun{
#' hyp <- read_hypnogram("night_001.csv")
#' plot_hypnogram(hyp)
#' plot_hypnogram(hyp, cycles = compute_cycles(hyp))
#' plot_hypnogram(hyp, x_axis = "hours")
#' plot_hypnogram(hyp, style = "capsule")
#' }
plot_hypnogram <- function(hypnogram,
                           style        = c("step", "capsule"),
                           x_axis       = c("auto", "time", "hours"),
                           date_breaks = "2 hours",
                           cycles       = NULL,
                           colours      = NULL,
                           title        = NULL,
                           corner_min   = 9) {
  style  <- match.arg(style)
  x_axis <- match.arg(x_axis)

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg ggplot2} is required for {.fn plot_hypnogram}.")
  }
  if (!inherits(hypnogram, "hypnor_hypnogram")) {
    hypnogram <- new_hypnogram(hypnogram)
  }

  has_time <- !all(is.na(hypnogram$time))

  if (x_axis == "time" && !has_time) {
    cli::cli_abort(c(
      "{.arg hypnogram} has no non-{.val NA} {.field time} values.",
      "i" = "Pass {.code x_axis = \"hours\"}, or supply {.arg start_time} to \\
             {.fn new_hypnogram} / {.code mrpheus::export_hypnogram()} so real \\
             clock times are available."
    ))
  }
  use_time <- has_time && x_axis != "hours"

  if (style == "step") {
    .plot_hypnogram_step(hypnogram, use_time, date_breaks, cycles, colours, title)
  } else {
    .plot_hypnogram_capsule(hypnogram, use_time, date_breaks, cycles, colours, title, corner_min)
  }
}

#' @noRd
.plot_hypnogram_step <- function(hypnogram, use_time, date_breaks, cycles, colours, title) {
  epoch_sec <- attr(hypnogram, "epoch_sec") %||% 30
  colours   <- colours %||% .hypno_stage_colours()

  df <- hypnogram
  if (use_time) {
    df$x <- df$time
  } else {
    df$x <- (df$epoch - df$epoch[1L]) * epoch_sec / 3600
  }

  p <- ggplot2::ggplot(df, ggplot2::aes(x = x, y = stage, group = 1)) +
    ggplot2::geom_step(colour = "grey40", linewidth = 0.4) +
    ggplot2::geom_point(ggplot2::aes(colour = stage), size = 1.2, show.legend = FALSE) +
    ggplot2::scale_colour_manual(values = colours, drop = TRUE) +
    ggplot2::labs(y = NULL, title = title) +
    .hypno_theme()

  if (use_time) {
    p <- p + ggplot2::scale_x_datetime(date_breaks = date_breaks, date_labels = "%H:%M") +
      ggplot2::labs(x = "Time")
  } else {
    p <- p + ggplot2::labs(x = "Time (hours)")
  }

  if (!is.null(cycles) && nrow(cycles) > 0L) {
    if (use_time) {
      boundary_x <- df$time[match(cycles$start_epoch, df$epoch)]
    } else {
      boundary_x <- (cycles$start_epoch - df$epoch[1L]) * epoch_sec / 3600
    }
    p <- p + ggplot2::geom_vline(
      xintercept = boundary_x,
      linetype   = "dashed",
      colour     = "grey60"
    )
  }

  p
}

#' @noRd
.plot_hypnogram_capsule <- function(hypnogram, use_time, date_breaks, cycles, colours, title, corner_min) {
  epoch_sec <- attr(hypnogram, "epoch_sec") %||% 30
  colours   <- colours %||% .hypno_stage_colours()

  lane_levels <- levels(hypnogram$stage)  # already bottom-to-top per new_hypnogram()
  n_lanes     <- length(lane_levels)
  pill_half   <- 0.3  # pill height = 0.6 lane-units, leaving a 0.4-unit gap for separators

  stage_chr  <- as.character(hypnogram$stage)
  rl         <- rle(stage_chr)
  ends_pos   <- cumsum(rl$lengths)
  starts_pos <- ends_pos - rl$lengths + 1L
  n_runs     <- length(rl$lengths)

  epoch_start <- hypnogram$epoch[starts_pos]
  epoch_end   <- hypnogram$epoch[ends_pos]

  if (use_time) {
    x0 <- hypnogram$time[starts_pos]
    x1 <- hypnogram$time[ends_pos] + epoch_sec
    corner_x_unit <- corner_min * 60  # minutes -> seconds
  } else {
    e0 <- hypnogram$epoch[1L]
    x0 <- (epoch_start - e0) * epoch_sec / 3600
    x1 <- (epoch_end   - e0 + 1L) * epoch_sec / 3600
    corner_x_unit <- corner_min / 60  # minutes -> hours
  }

  lane_y <- match(rl$values, lane_levels)
  y0 <- lane_y - pill_half
  y1 <- lane_y + pill_half

  poly_list <- vector("list", n_runs)
  for (i in seq_len(n_runs)) {
    width_units <- if (use_time) {
      as.numeric(difftime(x1[i], x0[i], units = "secs"))
    } else {
      x1[i] - x0[i]
    }
    rx  <- min(width_units / 2, corner_x_unit)
    ry  <- pill_half * 0.5
    ply <- .rounded_bar_polygon(x0[i], x1[i], y0[i], y1[i], rx, ry)
    ply$run_id <- i
    ply$stage  <- rl$values[i]
    poly_list[[i]] <- ply
  }
  polys <- do.call(rbind, poly_list)

  p <- ggplot2::ggplot() +
    ggplot2::geom_polygon(
      data    = polys,
      mapping = ggplot2::aes(x = x, y = y, group = run_id, fill = stage)
    ) +
    ggplot2::scale_fill_manual(values = colours, drop = TRUE, guide = "none") +
    ggplot2::scale_y_continuous(
      breaks = seq_len(n_lanes),
      labels = lane_levels,
      limits = c(0.5, n_lanes + 0.5),
      expand = ggplot2::expansion(add = 0)
    ) +
    ggplot2::labs(y = NULL, title = title) +
    .hypno_theme() +
    ggplot2::theme(
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor   = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_line(colour = "grey85", linetype = "dashed"),
      axis.line.y        = ggplot2::element_blank()
    )

  if (n_lanes > 1L) {
    for (i in seq_len(n_lanes - 1L)) {
      p <- p + ggplot2::geom_hline(yintercept = i + 0.5, colour = "grey85", linewidth = 0.4)
    }
  }

  if (use_time) {
    p <- p + ggplot2::scale_x_datetime(date_breaks = date_breaks, date_labels = "%H:%M") +
      ggplot2::labs(x = "Time")
  } else {
    p <- p + ggplot2::labs(x = "Time (hours)")
  }

  if (!is.null(cycles) && nrow(cycles) > 0L) {
    if (use_time) {
      boundary_cx <- hypnogram$time[match(cycles$start_epoch, hypnogram$epoch)]
    } else {
      boundary_cx <- (cycles$start_epoch - hypnogram$epoch[1L]) * epoch_sec / 3600
    }
    p <- p + ggplot2::geom_vline(
      xintercept = boundary_cx,
      linetype   = "dashed",
      colour     = "grey50"
    )
  }

  p
}


#' Plot sleep architecture as a bar chart
#'
#' Renders stage durations or percentages as a horizontal bar chart using
#' `ggplot2` and a Circadia Lab colour palette.
#'
#' @param architecture A tibble returned by [compute_sleep_architecture()]
#'   -- either a single row, or multiple rows for comparing several nights,
#'   in which case a `night` or `id` column (if present) is used to facet
#'   the plot into one panel per night.
#' @param metric `"duration"` (minutes, default) or `"percentage"` of TST.
#' @param colours Named character vector of stage colours. See
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
#' plot_architecture(arch, metric = "percentage")
#' }
plot_architecture <- function(architecture,
                              metric  = c("duration", "percentage"),
                              colours = NULL,
                              title   = NULL) {
  metric <- match.arg(metric)

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg ggplot2} is required for {.fn plot_architecture}.")
  }

  required <- c("tst_min", "pct_n1", "pct_n2", "pct_n3", "pct_rem",
               "pct_sleep", "pct_quiet_sleep")
  missing  <- setdiff(required, names(architecture))
  if (length(missing) > 0L) {
    cli::cli_abort(c(
      "{.arg architecture} is missing expected column(s): {.val {missing}}.",
      "i" = "Did it come from {.fn compute_sleep_architecture}?"
    ))
  }

  aasm <- !all(is.na(architecture$pct_n1))
  if (aasm) {
    stage_labels <- c("N1", "N2", "N3", "REM")
    pct_cols     <- c("pct_n1", "pct_n2", "pct_n3", "pct_rem")
  } else {
    stage_labels <- c("Sleep", "Quiet sleep")
    pct_cols     <- c("pct_sleep", "pct_quiet_sleep")
  }

  group_col <- intersect(c("night", "id"), names(architecture))
  group_col <- if (length(group_col) > 0L) group_col[1L] else NULL

  n_rows    <- nrow(architecture)
  long_list <- vector("list", n_rows)
  for (i in seq_len(n_rows)) {
    pct    <- as.numeric(architecture[i, pct_cols])
    row_df <- data.frame(
      stage        = factor(stage_labels, levels = rev(stage_labels)),
      pct          = pct,
      duration_min = pct / 100 * architecture$tst_min[i]
    )
    if (!is.null(group_col)) {
      row_df[[group_col]] <- architecture[[group_col]][i]
    }
    long_list[[i]] <- row_df
  }
  long <- do.call(rbind, long_list)

  long$value <- if (metric == "duration") long$duration_min else long$pct
  ylab       <- if (metric == "duration") "Duration (minutes)" else "Percentage of TST"

  p <- ggplot2::ggplot(long, ggplot2::aes(x = stage, y = value, fill = stage)) +
    ggplot2::geom_col()

  if (!is.null(group_col)) {
    p <- p + ggplot2::facet_wrap(stats::as.formula(paste("~", group_col)))
  }

  p <- p +
    ggplot2::coord_flip() +
    ggplot2::scale_fill_manual(values = colours %||% .hypno_stage_colours(), guide = "none") +
    ggplot2::labs(x = NULL, y = ylab, title = title) +
    .hypno_theme()

  p
}


#' Plot a stage-transition heatmap
#'
#' Renders the transition probability (or count) matrix returned by
#' [compute_transitions()] as a heatmap using `ggplot2`.
#'
#' @param transitions The `matrix` element of the list returned by
#'   [compute_transitions()]: a tibble with a `from` column plus one
#'   numeric column per *to* stage.
#' @param label_values If `TRUE` (default), cell values are printed inside
#'   each tile. `NA` cells (unvisited from-stages) are left blank.
#' @param digits Number of decimal places for cell labels. Default `2`.
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
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg ggplot2} is required for {.fn plot_transition_matrix}.")
  }
  if (!is.data.frame(transitions) || !"from" %in% names(transitions)) {
    cli::cli_abort(
      "{.arg transitions} must be the {.field matrix} element returned by {.fn compute_transitions}."
    )
  }

  stage_levels <- setdiff(names(transitions), "from")
  n_from       <- nrow(transitions)
  n_to         <- length(stage_levels)

  long <- data.frame(
    from  = rep(transitions$from, times = n_to),
    to    = rep(stage_levels, each = n_from),
    value = unlist(transitions[stage_levels], use.names = FALSE)
  )
  long$from <- factor(long$from, levels = rev(transitions$from))
  long$to   <- factor(long$to, levels = stage_levels)

  p <- ggplot2::ggplot(long, ggplot2::aes(x = to, y = from, fill = value)) +
    ggplot2::geom_tile(colour = "white") +
    ggplot2::scale_fill_gradient(
      low      = "#FFF7C5",
      high     = "#4F252E",
      na.value = "grey90"
    ) +
    ggplot2::labs(x = "To", y = "From", title = title, fill = NULL) +
    .hypno_theme()

  if (isTRUE(label_values)) {
    p <- p + ggplot2::geom_text(
      ggplot2::aes(label = ifelse(
        is.na(value), "", formatC(value, digits = digits, format = "f")
      )),
      colour = "black",
      size   = 3
    )
  }

  p
}
