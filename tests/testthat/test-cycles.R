library(testthat)
library(hypnoR)

# ── Fixtures ──────────────────────────────────────────────────────────────────
# 22 epochs @ 30 s.
# W W | N2 N2 N2 N2 | REM x5 | N2 N2 | REM x6 | W W W
# Two REM runs (5 and 6 epochs) separated by a 2-epoch (1 min) NREM gap.
# Under feinberg_floyd (no gap tolerance) these are two separate REM
# periods/cycles. Under aasm (15 min default gap tolerance) they merge
# into a single REM period/cycle.
make_two_rem_runs_hyp <- function() {
  stage <- c(
    "W", "W",
    "N2", "N2", "N2", "N2",
    rep("REM", 5),
    "N2", "N2",
    rep("REM", 6),
    "W", "W", "W"
  )
  new_hypnogram(tibble::tibble(epoch = seq_along(stage), stage = stage))
}

# 16 epochs @ 30 s: a single 3-epoch REM run, below the default
# min_rem_epochs = 5 threshold -> no qualifying REM period at all.
make_short_rem_hyp <- function() {
  stage <- c("W", "W", rep("N2", 8), rep("REM", 3), rep("N2", 3))
  new_hypnogram(tibble::tibble(epoch = seq_along(stage), stage = stage))
}

make_no_sleep_hyp <- function() {
  new_hypnogram(tibble::tibble(epoch = 1:5, stage = rep("W", 5)), resolution = "aasm")
}

make_coarse_hyp <- function() {
  stage <- c("W", "Sleep", "Sleep", "Quiet sleep", "W")
  new_hypnogram(tibble::tibble(epoch = seq_along(stage), stage = stage))
}

# ── feinberg_floyd ────────────────────────────────────────────────────────────

test_that("compute_cycles() with feinberg_floyd keeps separate REM runs as separate cycles", {
  cyc <- compute_cycles(make_two_rem_runs_hyp(), method = "feinberg_floyd")

  expect_equal(nrow(cyc), 2)
  expect_equal(cyc$cycle, c(1, 2))

  # Cycle 1: onset (epoch 3) through end of first REM run (epoch 11)
  expect_equal(cyc$start_epoch[1], 3)
  expect_equal(cyc$end_epoch[1], 11)
  expect_equal(cyc$rem_min[1], 2.5)   # 5 REM epochs * 0.5 min
  expect_equal(cyc$nrem_min[1], 2)    # 9 epochs total - 5 REM epochs = 4 NREM epochs -> 2 min
  expect_equal(cyc$cycle_min[1], 4.5)

  # Cycle 2: epoch 12 through end of second REM run (epoch 19)
  expect_equal(cyc$start_epoch[2], 12)
  expect_equal(cyc$end_epoch[2], 19)
  expect_equal(cyc$rem_min[2], 3)     # 6 REM epochs * 0.5 min
  expect_equal(cyc$nrem_min[2], 1)
  expect_equal(cyc$cycle_min[2], 4)

  expect_equal(cyc$nrem_min + cyc$rem_min, cyc$cycle_min)
})

# ── aasm gap-merging ──────────────────────────────────────────────────────────

test_that("compute_cycles() with aasm merges REM runs within rem_gap_min into one cycle", {
  cyc <- compute_cycles(make_two_rem_runs_hyp(), method = "aasm")

  expect_equal(nrow(cyc), 1)
  expect_equal(cyc$start_epoch, 3)
  expect_equal(cyc$end_epoch, 19)
  expect_equal(cyc$rem_min, 5.5)    # 5 + 6 = 11 REM epochs * 0.5 min
  expect_equal(cyc$nrem_min, 3)     # 17 epochs total - 11 REM epochs = 6 -> 3 min
  expect_equal(cyc$cycle_min, 8.5)
})

test_that("compute_cycles() with aasm respects a tight rem_gap_min (falls back to separate cycles)", {
  cyc <- compute_cycles(make_two_rem_runs_hyp(), method = "aasm", rem_gap_min = 0.25)  # 0.25 min = 0.5 epochs -> rounds to 1 epoch gap tolerance? check boundary
  # 2-epoch (1 min) gap exceeds a 0.25 min tolerance, so runs stay separate
  expect_equal(nrow(cyc), 2)
})

# ── min_rem_epochs filtering ──────────────────────────────────────────────────

test_that("compute_cycles() returns an empty tibble when no REM run meets min_rem_epochs", {
  cyc <- compute_cycles(make_short_rem_hyp())

  expect_equal(nrow(cyc), 0)
  expect_equal(names(cyc), c("cycle", "start_epoch", "end_epoch", "nrem_min", "rem_min", "cycle_min"))
  expect_type(cyc$cycle, "integer")
  expect_type(cyc$nrem_min, "double")
})

test_that("compute_cycles() qualifies a short REM run when min_rem_epochs is lowered", {
  cyc <- compute_cycles(make_short_rem_hyp(), min_rem_epochs = 3)
  expect_equal(nrow(cyc), 1)
  expect_equal(cyc$rem_min, 1.5)  # 3 REM epochs * 0.5 min
})

# ── No sleep at all ───────────────────────────────────────────────────────────

test_that("compute_cycles() returns an empty tibble when there is no sleep at all", {
  cyc <- compute_cycles(make_no_sleep_hyp())
  expect_equal(nrow(cyc), 0)
})

# ── Coarse hypnograms hard-error ─────────────────────────────────────────────

test_that("compute_cycles() errors on a coarse hypnogram", {
  expect_error(compute_cycles(make_coarse_hyp()), "full AASM hypnogram")
})

# ── Bare data frame passthrough ───────────────────────────────────────────────

test_that("compute_cycles() accepts a bare data frame and normalises it internally", {
  stage <- c("W", "N2", "N2", rep("REM", 5), "W")
  bare  <- tibble::tibble(epoch = seq_along(stage), stage = stage)

  cyc <- compute_cycles(bare)
  expect_equal(nrow(cyc), 1)
})
