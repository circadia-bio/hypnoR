library(testthat)
library(hypnoR)

# ── Fixtures ──────────────────────────────────────────────────────────────────

make_coarse_tbl <- function() {
  tibble::tibble(
    epoch      = 1:6,
    time       = as.POSIXct("2024-01-01 00:00:00", tz = "UTC") + (0:5) * 30,
    stage      = c("W", "Sleep", "Sleep", "Quiet sleep", "Sleep", "W"),
    subject_id = "P001",
    source     = "zeitR"
  )
}

make_aasm_tbl <- function() {
  tibble::tibble(
    epoch = 1:6,
    stage = c("W", "N1", "N2", "N3", "REM", "W")
  )
}

make_mrpheus_hypnogram <- function() {
  out <- tibble::tibble(
    epoch = 1:4,
    stage = c("W", "N1", "N2", "REM")
  )
  attr(out, "epoch_s")        <- 30
  attr(out, "start_time")     <- as.POSIXct("2024-01-01 22:00:00", tz = "UTC")
  attr(out, "participant_id") <- "SUBJ42"
  attr(out, "source")         <- "mrpheus"
  attr(out, "resolution")     <- "AASM"
  class(out) <- c("mrpheus_hypnogram", class(out))
  out
}

# ── new_hypnogram.default ────────────────────────────────────────────────────

test_that("new_hypnogram() builds a coarse hypnogram from a bare tibble", {
  hyp <- new_hypnogram(make_coarse_tbl())

  expect_s3_class(hyp, "hypnor_hypnogram")
  expect_equal(attr(hyp, "resolution"), "coarse")
  expect_equal(attr(hyp, "epoch_sec"), 30)
  expect_s3_class(hyp$stage, "ordered")
  expect_equal(levels(hyp$stage), c("Quiet sleep", "Sleep", "W"))
  expect_equal(hyp$subject_id[1], "P001")
  expect_equal(hyp$source[1], "zeitR")
  expect_true(all(!is.na(hyp$time)))
})

test_that("new_hypnogram() builds an AASM hypnogram and detects resolution automatically", {
  hyp <- new_hypnogram(make_aasm_tbl())

  expect_equal(attr(hyp, "resolution"), "aasm")
  expect_equal(levels(hyp$stage), c("N3", "N2", "N1", "REM", "W"))
  expect_true(all(is.na(hyp$time)))
  expect_true(all(is.na(hyp$subject_id)))
  expect_equal(attr(hyp, "epoch_sec"), 30)
})

test_that("new_hypnogram() sorts by epoch and rejects duplicates", {
  tbl <- make_aasm_tbl()
  tbl <- tbl[c(3, 1, 2, 4, 5, 6), ]
  hyp <- new_hypnogram(tbl)
  expect_equal(hyp$epoch, 1:6)

  dup <- make_aasm_tbl()
  dup$epoch[2] <- 1L
  expect_error(new_hypnogram(dup), "duplicate")
})

test_that("new_hypnogram() rejects missing columns and unknown stage labels", {
  expect_error(new_hypnogram(tibble::tibble(epoch = 1:3)), "missing required column")

  bad <- make_aasm_tbl()
  bad$stage[1] <- "Deep"
  expect_error(new_hypnogram(bad), "Unrecognised stage label")
})

test_that("new_hypnogram() lets explicit arguments override carried metadata", {
  hyp <- new_hypnogram(make_coarse_tbl(), subject_id = "OVERRIDE", source = "manual", epoch_sec = 15)
  expect_equal(hyp$subject_id[1], "OVERRIDE")
  expect_equal(hyp$source[1], "manual")
  expect_equal(attr(hyp, "epoch_sec"), 15)
})

# ── new_hypnogram.mrpheus_hypnogram ──────────────────────────────────────────

test_that("new_hypnogram() converts an mrpheus_hypnogram, computing time from epoch_s/start_time", {
  hyp <- new_hypnogram(make_mrpheus_hypnogram())

  expect_s3_class(hyp, "hypnor_hypnogram")
  expect_equal(attr(hyp, "resolution"), "aasm")
  expect_equal(attr(hyp, "epoch_sec"), 30)
  expect_equal(hyp$subject_id[1], "SUBJ42")
  expect_equal(hyp$source[1], "mrpheus")
  expect_equal(
    hyp$time,
    as.POSIXct("2024-01-01 22:00:00", tz = "UTC") + (0:3) * 30
  )
})

test_that("new_hypnogram() print method does not error", {
  expect_message(print(new_hypnogram(make_coarse_tbl())), "hypnoR hypnogram")
})
