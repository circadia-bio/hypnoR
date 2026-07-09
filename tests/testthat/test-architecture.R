library(testthat)
library(hypnoR)

# ── Fixtures ──────────────────────────────────────────────────────────────────
# 20 epochs @ 30 s. Sleep onset at epoch 3 (N1), one WASO wake at epoch 11,
# final wake block at epochs 18-20 (not WASO). N3 first at epoch 6, REM
# first at epoch 9 -- both after onset, so latencies are non-trivial.

make_aasm_hyp <- function() {
  stage <- c(
    "W", "W", "N1", "N2", "N2", "N3", "N3", "N2", "REM", "REM",
    "W", "N2", "N2", "REM", "REM", "REM", "N2", "W", "W", "W"
  )
  new_hypnogram(tibble::tibble(epoch = seq_along(stage), stage = stage))
}

# 8 epochs @ 30 s. Sleep onset at epoch 3, no WASO, no trailing latency stages.
make_coarse_hyp <- function() {
  stage <- c("W", "W", "Sleep", "Sleep", "Quiet sleep", "Sleep", "W", "W")
  new_hypnogram(tibble::tibble(epoch = seq_along(stage), stage = stage))
}

make_no_sleep_hyp <- function() {
  new_hypnogram(tibble::tibble(epoch = 1:5, stage = rep("W", 5)))
}

# ── AASM ──────────────────────────────────────────────────────────────────────

test_that("compute_sleep_architecture() computes correct metrics for an AASM hypnogram", {
  arch <- compute_sleep_architecture(make_aasm_hyp())

  expect_equal(arch$staging_resolution, "aasm")
  expect_equal(arch$tst_min, 7)          # 14 sleep epochs * 0.5 min
  expect_equal(arch$tib_min, 10)         # 20 epochs * 0.5 min
  expect_equal(arch$se_pct, 70)
  expect_equal(arch$sol_min, 1)          # (3 - 1) * 0.5
  expect_equal(arch$waso_min, 0.5)       # epoch 11, one W epoch within sleep span
  expect_equal(arch$rem_lat_min, 3)      # (9 - 3) * 0.5
  expect_equal(arch$sws_lat_min, 1.5)    # (6 - 3) * 0.5
  expect_equal(arch$pct_n1, 1 / 14 * 100)
  expect_equal(arch$pct_n2, 6 / 14 * 100)
  expect_equal(arch$pct_n3, 2 / 14 * 100)
  expect_equal(arch$pct_rem, 5 / 14 * 100)
  expect_true(is.na(arch$pct_sleep))
  expect_true(is.na(arch$pct_quiet_sleep))
})

# ── Coarse ────────────────────────────────────────────────────────────────────

test_that("compute_sleep_architecture() computes correct metrics for a coarse hypnogram", {
  arch <- compute_sleep_architecture(make_coarse_hyp())

  expect_equal(arch$staging_resolution, "coarse")
  expect_equal(arch$tst_min, 2)    # 4 sleep epochs * 0.5 min
  expect_equal(arch$tib_min, 4)    # 8 epochs * 0.5 min
  expect_equal(arch$se_pct, 50)
  expect_equal(arch$sol_min, 1)    # (3 - 1) * 0.5, non-W ends SOL regardless of stage
  expect_equal(arch$waso_min, 0)
  expect_true(is.na(arch$rem_lat_min))
  expect_true(is.na(arch$sws_lat_min))
  expect_true(is.na(arch$pct_n1))
  expect_equal(arch$pct_sleep, 75)         # 3 of 4 sleep epochs
  expect_equal(arch$pct_quiet_sleep, 25)   # 1 of 4 sleep epochs
})

# ── Lights off/on ─────────────────────────────────────────────────────────────

test_that("compute_sleep_architecture() uses lights_off/lights_on for TIB and SE when supplied", {
  hyp <- make_aasm_hyp()
  lights_off <- as.POSIXct("2024-01-01 22:00:00", tz = "UTC")
  lights_on  <- lights_off + 20 * 60  # 20 minutes later

  arch <- compute_sleep_architecture(hyp, lights_off = lights_off, lights_on = lights_on)

  expect_equal(arch$tib_min, 20)
  expect_equal(arch$se_pct, 7 / 20 * 100)
})

test_that("compute_sleep_architecture() warns and ignores lights_off/on if only one is supplied", {
  hyp <- make_aasm_hyp()
  expect_warning(
    arch <- compute_sleep_architecture(hyp, lights_off = as.POSIXct("2024-01-01 22:00:00", tz = "UTC")),
    "must be supplied together"
  )
  expect_equal(arch$tib_min, 10)  # fallback to full recording span
})

# ── No sleep at all ───────────────────────────────────────────────────────────

test_that("compute_sleep_architecture() handles a hypnogram with no sleep epochs", {
  arch <- compute_sleep_architecture(make_no_sleep_hyp())

  expect_equal(arch$tst_min, 0)
  expect_equal(arch$se_pct, 0)
  expect_true(is.na(arch$sol_min))
  expect_true(is.na(arch$waso_min))
  expect_true(is.na(arch$pct_n1))
  expect_true(is.na(arch$pct_sleep))
})

# ── Passthrough for bare data frames ──────────────────────────────────────────

test_that("compute_sleep_architecture() accepts a bare data frame and normalises it internally", {
  stage <- c("W", "N1", "N2", "N2", "REM", "W")
  bare  <- tibble::tibble(epoch = seq_along(stage), stage = stage)

  arch <- compute_sleep_architecture(bare)

  expect_equal(arch$staging_resolution, "aasm")
  expect_equal(arch$tst_min, 4 * 0.5)  # default 30 s epochs assumed
})
