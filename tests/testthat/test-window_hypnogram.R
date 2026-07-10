library(testthat)
library(hypnoR)

# ── Fixtures ──────────────────────────────────────────────────────────────────

make_aasm_hyp <- function() {
  stage <- c("W", "W", "N1", "N2", "N3", "N2", "REM", "REM", "N2", "W")
  new_hypnogram(tibble::tibble(epoch = seq_along(stage), stage = stage))
}

make_aasm_hyp_with_time <- function(start_time) {
  stage <- c("W", "W", "N1", "N2", "N3", "N2", "REM", "REM", "N2", "W")
  tbl <- tibble::tibble(
    epoch = seq_along(stage),
    time  = start_time + (seq_along(stage) - 1) * 30,
    stage = stage
  )
  new_hypnogram(tbl)
}

# ── Epoch-range windowing ─────────────────────────────────────────────────────

test_that("window_hypnogram() filters by from_epoch/to_epoch", {
  hyp <- make_aasm_hyp()
  win <- window_hypnogram(hyp, from_epoch = 3L, to_epoch = 8L)

  expect_equal(win$epoch, 3:8)
  expect_equal(as.character(win$stage), c("N1", "N2", "N3", "N2", "REM", "REM"))
})

test_that("window_hypnogram() from_epoch/to_epoch can each be supplied alone", {
  hyp <- make_aasm_hyp()

  win_from <- window_hypnogram(hyp, from_epoch = 7L)
  expect_equal(win_from$epoch, 7:10)

  win_to <- window_hypnogram(hyp, to_epoch = 4L)
  expect_equal(win_to$epoch, 1:4)
})

# ── Clock-time windowing ──────────────────────────────────────────────────────

test_that("window_hypnogram() filters by lights_off/lights_on", {
  lights_off <- as.POSIXct("2024-01-01 22:00:00", tz = "UTC")
  hyp <- make_aasm_hyp_with_time(lights_off)

  win <- window_hypnogram(hyp, lights_off = lights_off + 60, lights_on = lights_off + 210)
  # epoch 1 = +0s, epoch 2 = +30s, epoch 3 = +60s, ..., epoch 8 = +210s
  expect_equal(win$epoch, 3:8)
})

test_that("window_hypnogram() errors if hypnogram has no time data for lights_off/lights_on", {
  hyp <- make_aasm_hyp()  # no time column
  expect_error(
    window_hypnogram(hyp, lights_off = as.POSIXct("2024-01-01 22:00:00", tz = "UTC"),
                     lights_on = as.POSIXct("2024-01-01 23:00:00", tz = "UTC")),
    "time"
  )
})

# ── Attribute preservation ────────────────────────────────────────────────────

test_that("window_hypnogram() preserves epoch_sec and resolution rather than re-detecting them", {
  hyp <- make_aasm_hyp()
  # Window down to a range containing no REM/N3 at all -- if resolution were
  # re-detected from this subset alone, it would misdetect as "coarse"
  win <- window_hypnogram(hyp, from_epoch = 1L, to_epoch = 2L)

  expect_equal(as.character(win$stage), c("W", "W"))
  expect_equal(attr(win, "resolution"), "aasm")
  expect_equal(attr(win, "epoch_sec"), attr(hyp, "epoch_sec"))
  expect_s3_class(win, "hypnor_hypnogram")
})

# ── Validation ────────────────────────────────────────────────────────────────

test_that("window_hypnogram() errors if both time-based and epoch-based windows are supplied", {
  hyp <- make_aasm_hyp_with_time(as.POSIXct("2024-01-01 22:00:00", tz = "UTC"))
  expect_error(
    window_hypnogram(hyp, from_epoch = 1L, lights_off = as.POSIXct("2024-01-01 22:00:00", tz = "UTC"),
                     lights_on = as.POSIXct("2024-01-01 23:00:00", tz = "UTC")),
    "not both"
  )
})

test_that("window_hypnogram() errors if no window is specified at all", {
  expect_error(window_hypnogram(make_aasm_hyp()), "Specify a window")
})

test_that("window_hypnogram() errors if only one of lights_off/lights_on is supplied", {
  hyp <- make_aasm_hyp_with_time(as.POSIXct("2024-01-01 22:00:00", tz = "UTC"))
  expect_error(
    window_hypnogram(hyp, lights_off = as.POSIXct("2024-01-01 22:00:00", tz = "UTC")),
    "supplied together"
  )
})

test_that("window_hypnogram() errors if the window matches no epochs", {
  hyp <- make_aasm_hyp()
  expect_error(window_hypnogram(hyp, from_epoch = 100L, to_epoch = 200L), "no epochs")
})

# ── Input handling ────────────────────────────────────────────────────────────

test_that("window_hypnogram() accepts a bare data frame and normalises it internally", {
  stage <- c("W", "N1", "N2", "REM", "W")
  bare  <- tibble::tibble(epoch = seq_along(stage), stage = stage)

  win <- window_hypnogram(bare, from_epoch = 2L, to_epoch = 4L)
  expect_s3_class(win, "hypnor_hypnogram")
  expect_equal(win$epoch, 2:4)
})

# ── Downstream usage ──────────────────────────────────────────────────────────

test_that("compute_cycles() and compute_transitions() work correctly on a windowed hypnogram with non-1:n epoch numbers", {
  hyp <- make_aasm_hyp()
  win <- window_hypnogram(hyp, from_epoch = 3L, to_epoch = 10L)

  cyc <- compute_cycles(win, min_rem_epochs = 2)
  expect_equal(nrow(cyc), 1)
  expect_equal(cyc$start_epoch, 3)   # first non-W in the window is epoch 3 itself
  expect_equal(cyc$end_epoch, 8)     # REM run ends at epoch 8

  trans <- compute_transitions(win)
  expect_true(is.data.frame(trans$matrix))
})
