library(testthat)
library(hypnoR)

# ── Fixtures ──────────────────────────────────────────────────────────────────
# 10 epochs. Sequence: W W N2 N2 N3 N2 REM REM W N2
# Transitions (9 total): W->W, W->N2, N2->N2, N2->N3, N3->N2, N2->REM,
#                        REM->REM, REM->W, W->N2
# Changes (non-self): W->N2, N2->N3, N3->N2, N2->REM, REM->W, W->N2 = 6
# wake_transitions (changes landing on W): REM->W = 1

make_aasm_hyp <- function() {
  stage <- c("W", "W", "N2", "N2", "N3", "N2", "REM", "REM", "W", "N2")
  new_hypnogram(tibble::tibble(epoch = seq_along(stage), stage = stage))
}

# ── Fragmentation ─────────────────────────────────────────────────────────────

test_that("compute_transitions() computes fragmentation metrics from the full sequence", {
  trans <- compute_transitions(make_aasm_hyp())
  frag  <- trans$fragmentation

  expect_equal(frag$n_transitions, 6)
  expect_equal(frag$fragmentation_index, 6 / 9)
  expect_equal(frag$wake_transitions, 1)
})

test_that("compute_transitions() fragmentation is unaffected by include_wake", {
  trans_wake    <- compute_transitions(make_aasm_hyp(), include_wake = TRUE)
  trans_no_wake <- compute_transitions(make_aasm_hyp(), include_wake = FALSE)

  expect_equal(trans_wake$fragmentation, trans_no_wake$fragmentation)
})

# ── Matrix: include_wake = TRUE ──────────────────────────────────────────────

test_that("compute_transitions() builds a full matrix including Wake by default", {
  trans <- compute_transitions(make_aasm_hyp())
  mat   <- trans$matrix

  expect_equal(mat$from, c("N3", "N2", "N1", "REM", "W"))
  expect_setequal(names(mat), c("from", "N3", "N2", "N1", "REM", "W"))

  # W row: W->W once, W->N2 twice, out of 3 total departures from W -> probs
  w_row <- mat[mat$from == "W", ]
  expect_equal(w_row$W,  1 / 3)
  expect_equal(w_row$N2, 2 / 3)

  # N1 never visited as a "from" stage -> NA row, not NaN
  n1_row <- mat[mat$from == "N1", ]
  expect_true(all(is.na(unlist(n1_row[ , -1]))))
})

test_that("compute_transitions() returns raw counts when normalise = FALSE", {
  trans <- compute_transitions(make_aasm_hyp(), normalise = FALSE)
  mat   <- trans$matrix

  w_row <- mat[mat$from == "W", ]
  expect_equal(w_row$W,  1L)
  expect_equal(w_row$N2, 2L)
})

# ── Matrix: include_wake = FALSE ─────────────────────────────────────────────

test_that("compute_transitions() excludes Wake from the matrix when include_wake = FALSE", {
  trans <- compute_transitions(make_aasm_hyp(), include_wake = FALSE, normalise = FALSE)
  mat   <- trans$matrix

  expect_setequal(names(mat), c("from", "N3", "N2", "N1", "REM"))
  expect_false("W" %in% mat$from)

  # Sleep-only transitions remaining: N2->N2, N2->N3, N3->N2, N2->REM, REM->REM
  n2_row <- mat[mat$from == "N2", ]
  expect_equal(n2_row$N2,  1L)
  expect_equal(n2_row$N3,  1L)
  expect_equal(n2_row$REM, 1L)
})

# ── Coarse resolution ─────────────────────────────────────────────────────────

test_that("compute_transitions() works for coarse hypnograms", {
  stage <- c("W", "Sleep", "Sleep", "Quiet sleep", "Sleep", "W")
  hyp   <- new_hypnogram(tibble::tibble(epoch = seq_along(stage), stage = stage))

  trans <- compute_transitions(hyp, normalise = FALSE)
  mat   <- trans$matrix

  expect_setequal(names(mat), c("from", "Quiet sleep", "Sleep", "W"))
  # Pairs: W->Sleep, Sleep->Sleep, Sleep->Quiet sleep, Quiet sleep->Sleep, Sleep->W
  # Changes: W->Sleep, Sleep->Quiet sleep, Quiet sleep->Sleep, Sleep->W = 4
  expect_equal(trans$fragmentation$n_transitions, 4)
  expect_equal(trans$fragmentation$wake_transitions, 1)  # Sleep->W
})

# ── Errors ────────────────────────────────────────────────────────────────────

test_that("compute_transitions() errors with fewer than 2 epochs", {
  hyp <- new_hypnogram(tibble::tibble(epoch = 1L, stage = "W"))
  expect_error(compute_transitions(hyp), "at least 2 epochs")
})
