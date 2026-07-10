library(testthat)
library(hypnoR)

skip_if_not_installed("ggplot2")

# ── Fixtures ──────────────────────────────────────────────────────────────────

make_aasm_hyp <- function() {
  stage <- c("W", "W", "N1", "N2", "N3", "N2", "REM", "REM", "N2", "W")
  new_hypnogram(tibble::tibble(epoch = seq_along(stage), stage = stage))
}

make_coarse_hyp <- function() {
  stage <- c("W", "Sleep", "Sleep", "Quiet sleep", "Sleep", "W")
  new_hypnogram(tibble::tibble(epoch = seq_along(stage), stage = stage))
}

# ── plot_hypnogram() ──────────────────────────────────────────────────────────

test_that("plot_hypnogram() returns a ggplot object for AASM and coarse hypnograms", {
  p1 <- plot_hypnogram(make_aasm_hyp())
  p2 <- plot_hypnogram(make_coarse_hyp())

  expect_s3_class(p1, "ggplot")
  expect_s3_class(p2, "ggplot")
})

test_that("plot_hypnogram() overlays cycle boundaries when cycles is supplied", {
  hyp <- make_aasm_hyp()
  cyc <- compute_cycles(hyp, min_rem_epochs = 2)

  p_no_cycles   <- plot_hypnogram(hyp)
  p_with_cycles <- plot_hypnogram(hyp, cycles = cyc)

  n_layers_no    <- length(p_no_cycles$layers)
  n_layers_with  <- length(p_with_cycles$layers)

  expect_gt(n_layers_with, n_layers_no)
})

test_that("plot_hypnogram() accepts a bare data frame", {
  stage <- c("W", "N1", "N2", "REM", "W")
  bare  <- tibble::tibble(epoch = seq_along(stage), stage = stage)
  expect_s3_class(plot_hypnogram(bare), "ggplot")
})

# ── x_axis: clock time vs elapsed hours ─────────────────────────────────────────────

make_aasm_hyp_with_time <- function() {
  stage <- c("W", "W", "N1", "N2", "N3", "N2", "REM", "REM", "N2", "W")
  tbl <- tibble::tibble(
    epoch = seq_along(stage),
    time  = as.POSIXct("2024-01-01 22:00:00", tz = "UTC") + (seq_along(stage) - 1) * 30,
    stage = stage
  )
  new_hypnogram(tbl)
}

test_that("plot_hypnogram() defaults to clock time when time is available (x_axis = 'auto')", {
  p <- plot_hypnogram(make_aasm_hyp_with_time())
  expect_equal(p$labels$x, "Time")
  expect_s3_class(p$scales$get_scales("x"), "ScaleContinuousDatetime")
})

test_that("plot_hypnogram() falls back to elapsed hours when time is unavailable (x_axis = 'auto')", {
  p <- plot_hypnogram(make_aasm_hyp())  # no time column populated -> all NA
  expect_equal(p$labels$x, "Time (hours)")
})

test_that("plot_hypnogram() x_axis = 'hours' forces elapsed hours even when time is available", {
  p <- plot_hypnogram(make_aasm_hyp_with_time(), x_axis = "hours")
  expect_equal(p$labels$x, "Time (hours)")
})

test_that("plot_hypnogram() x_axis = 'time' errors when time is entirely NA", {
  expect_error(
    plot_hypnogram(make_aasm_hyp(), x_axis = "time"),
    "non-.*time.*values"
  )
})

test_that("plot_hypnogram() cycle boundaries align correctly on a clock-time x-axis", {
  hyp <- make_aasm_hyp_with_time()
  cyc <- compute_cycles(hyp, min_rem_epochs = 2)

  p <- plot_hypnogram(hyp, cycles = cyc)
  vline_layer <- p$layers[[length(p$layers)]]
  expect_s3_class(vline_layer$geom, "GeomVline")
})

# ── plot_architecture() ───────────────────────────────────────────────────────

test_that("plot_architecture() works for AASM and coarse architecture tibbles", {
  arch_aasm   <- compute_sleep_architecture(make_aasm_hyp())
  arch_coarse <- compute_sleep_architecture(make_coarse_hyp())

  p1 <- plot_architecture(arch_aasm)
  p2 <- plot_architecture(arch_coarse)

  expect_s3_class(p1, "ggplot")
  expect_s3_class(p2, "ggplot")
})

test_that("plot_architecture() supports both duration and percentage metrics", {
  arch <- compute_sleep_architecture(make_aasm_hyp())

  p_dur <- plot_architecture(arch, metric = "duration")
  p_pct <- plot_architecture(arch, metric = "percentage")

  expect_equal(p_dur$labels$y, "Duration (minutes)")
  expect_equal(p_pct$labels$y, "Percentage of TST")
})

test_that("plot_architecture() facets when a night/id grouping column is present", {
  arch1 <- compute_sleep_architecture(make_aasm_hyp())
  arch2 <- compute_sleep_architecture(make_aasm_hyp())
  arch1$night <- "N1"
  arch2$night <- "N2"
  arch_multi  <- rbind(arch1, arch2)

  p <- plot_architecture(arch_multi)
  expect_true(!inherits(p$facet, "FacetNull"))
})

test_that("plot_architecture() errors on a malformed architecture tibble", {
  expect_error(
    plot_architecture(tibble::tibble(tst_min = 10)),
    "missing expected column"
  )
})

# ── plot_transition_matrix() ──────────────────────────────────────────────────

test_that("plot_transition_matrix() returns a ggplot object", {
  hyp   <- make_aasm_hyp()
  trans <- compute_transitions(hyp)

  p <- plot_transition_matrix(trans$matrix)
  expect_s3_class(p, "ggplot")
})

test_that("plot_transition_matrix() label_values toggles the text layer", {
  trans <- compute_transitions(make_aasm_hyp())

  p_labels   <- plot_transition_matrix(trans$matrix, label_values = TRUE)
  p_nolabels <- plot_transition_matrix(trans$matrix, label_values = FALSE)

  expect_gt(length(p_labels$layers), length(p_nolabels$layers))
})

test_that("plot_transition_matrix() errors on non-matrix input", {
  expect_error(
    plot_transition_matrix(tibble::tibble(x = 1:3)),
    "matrix.*element"
  )
})
