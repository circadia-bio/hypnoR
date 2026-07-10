library(testthat)
library(hypnoR)

# ── Fixture A: isolated-epoch behaviour ──────────────────────────────────────
# Run1: N2 x3  (idx 1-3)
# Run2: REM x1 (idx 4)  -- flanked by N2/N2 (SAME)      -> aasm_isolated fixes this
# Run3: N2 x2  (idx 5-6)
# Run4: N3 x1  (idx 7)  -- flanked by N2/REM (DIFFERENT) -> aasm_isolated leaves this
# Run5: REM x5 (idx 8-12) -- sustained, never touched
# Run6: N3 x3  (idx 13-15)
make_fixture_a <- function() {
  stage <- c(
    "N2", "N2", "N2",
    "REM",
    "N2", "N2",
    "N3",
    rep("REM", 5),
    "N3", "N3", "N3"
  )
  new_hypnogram(tibble::tibble(epoch = seq_along(stage), stage = stage))
}

# ── Fixture B: min_run_epochs > 2, tie-breaking ──────────────────────────────
# Run1: N2 x10, Run2: REM x3 (short relative to threshold 4), Run3: N2 x10
# Flank lengths tie (10 vs 10) -> should favour the preceding (left) run.
make_fixture_b <- function() {
  stage <- c(rep("N2", 10), rep("REM", 3), rep("N2", 10))
  new_hypnogram(tibble::tibble(epoch = seq_along(stage), stage = stage))
}

# ── aasm_isolated ─────────────────────────────────────────────────────────────

test_that("smooth_hypnogram() aasm_isolated fixes only same-flanked single epochs", {
  hyp <- smooth_hypnogram(make_fixture_a(), method = "aasm_isolated")

  expect_equal(as.character(hyp$stage)[4], "N2")   # same-flanked -> fixed
  expect_equal(as.character(hyp$stage)[7], "N3")   # different-flanked -> untouched
  # Sustained REM run (idx 8-12) is completely unaffected
  expect_equal(as.character(hyp$stage)[8:12], rep("REM", 5))
})

test_that("smooth_hypnogram() aasm_isolated never touches runs of 2+ epochs", {
  hyp <- smooth_hypnogram(make_fixture_b(), method = "aasm_isolated")
  # Run2 (REM x3) has length > 1, so aasm_isolated (which only ever considers
  # length-1 runs) must leave it completely alone
  expect_equal(as.character(hyp$stage)[11:13], rep("REM", 3))
})

test_that("smooth_hypnogram() is the default method", {
  hyp_default  <- smooth_hypnogram(make_fixture_a())
  hyp_explicit <- smooth_hypnogram(make_fixture_a(), method = "aasm_isolated")
  expect_equal(as.character(hyp_default$stage), as.character(hyp_explicit$stage))
})

# ── min_run ───────────────────────────────────────────────────────────────────

test_that("smooth_hypnogram() min_run reassigns based on longer flank, even when flanks disagree", {
  hyp <- smooth_hypnogram(make_fixture_a(), method = "min_run", min_run_epochs = 2)

  # Run2 (REM@idx4): flanks are N2(len3) vs N2(len2) -> either way it's N2
  expect_equal(as.character(hyp$stage)[4], "N2")
  # Run4 (N3@idx7): flanks are N2(len2, run3) vs REM(len5, run5) on the
  # UNMODIFIED original hypnogram -> REM's longer flank wins
  expect_equal(as.character(hyp$stage)[7], "REM")
})

test_that("smooth_hypnogram() min_run ties favour the preceding run", {
  hyp <- smooth_hypnogram(make_fixture_b(), method = "min_run", min_run_epochs = 4)
  # Run2 (REM x3, idx 11-13): flanked by N2(len10) on both sides -> tie -> left wins (N2 either way)
  expect_equal(as.character(hyp$stage)[11:13], rep("N2", 3))
})

test_that("smooth_hypnogram() min_run can merge runs longer than a single epoch", {
  hyp_len3 <- smooth_hypnogram(make_fixture_b(), method = "min_run", min_run_epochs = 4)
  hyp_len2 <- smooth_hypnogram(make_fixture_b(), method = "min_run", min_run_epochs = 2)

  # min_run_epochs = 4 merges the length-3 REM run; min_run_epochs = 2 does not
  expect_equal(as.character(hyp_len3$stage)[11:13], rep("N2", 3))
  expect_equal(as.character(hyp_len2$stage)[11:13], rep("REM", 3))
})

# ── Combined: order matters ───────────────────────────────────────────────────

test_that("smooth_hypnogram() applies aasm_isolated before min_run, changing min_run's flank lengths", {
  # After aasm_isolated fixes idx 4 to N2, runs 1+2+3 merge into one N2 run of
  # length 6 (idx 1-6). Run4 (N3@idx7) then sees flanks N2(len6) vs REM(len5)
  # under min_run -- left now wins (6 > 5), unlike the min_run-alone case
  # above where the unmodified left flank was only length 2 and REM won.
  hyp <- smooth_hypnogram(
    make_fixture_a(),
    method         = c("aasm_isolated", "min_run"),
    min_run_epochs = 2
  )
  expect_equal(as.character(hyp$stage)[1:6], rep("N2", 6))
  expect_equal(as.character(hyp$stage)[7], "N2")  # differs from the min_run-alone result (REM)
})

# ── stage_raw preservation & attributes ──────────────────────────────────────

test_that("smooth_hypnogram() preserves the original labels in stage_raw", {
  hyp <- smooth_hypnogram(make_fixture_a(), method = "aasm_isolated")
  expected_raw <- c(
    "N2", "N2", "N2", "REM", "N2", "N2", "N3",
    rep("REM", 5), "N3", "N3", "N3"
  )
  expect_equal(as.character(hyp$stage_raw), expected_raw)
  # Only epoch 4 actually changed
  changed <- as.character(hyp$stage) != as.character(hyp$stage_raw)
  expect_equal(which(changed), 4)
})

test_that("smooth_hypnogram() preserves epoch_sec and resolution attributes", {
  orig <- make_fixture_a()
  hyp  <- smooth_hypnogram(orig, method = "aasm_isolated")

  expect_equal(attr(hyp, "epoch_sec"), attr(orig, "epoch_sec"))
  expect_equal(attr(hyp, "resolution"), attr(orig, "resolution"))
  expect_s3_class(hyp, "hypnor_hypnogram")
})

# ── Input handling ────────────────────────────────────────────────────────────

test_that("smooth_hypnogram() accepts a bare data frame and normalises it internally", {
  stage <- c("N2", "N2", "REM", "N2", "N2")
  bare  <- tibble::tibble(epoch = seq_along(stage), stage = stage)
  hyp   <- smooth_hypnogram(bare)
  expect_s3_class(hyp, "hypnor_hypnogram")
  expect_equal(as.character(hyp$stage)[3], "N2")
})

test_that("smooth_hypnogram() errors on an invalid min_run_epochs", {
  expect_error(smooth_hypnogram(make_fixture_a(), min_run_epochs = 0), "min_run_epochs")
  expect_error(smooth_hypnogram(make_fixture_a(), min_run_epochs = c(2, 3)), "min_run_epochs")
})

test_that("smooth_hypnogram() handles a hypnogram with a single uniform stage", {
  hyp <- new_hypnogram(tibble::tibble(epoch = 1:5, stage = rep("W", 5)), resolution = "aasm")
  smoothed <- smooth_hypnogram(hyp, method = c("aasm_isolated", "min_run"))
  expect_equal(as.character(smoothed$stage), rep("W", 5))
})
