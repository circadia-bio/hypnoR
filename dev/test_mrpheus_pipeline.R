# dev/test_mrpheus_pipeline.R
#
# End-to-end smoke test: mrpheus's bundled SC4001E0 example -- the same
# staging output used in mrpheus's sleep-staging-demo vignette
# (22-hour Sleep-EDF cassette recording, ~2650 x 30 s epochs, mostly Wake
# before/after a single sleep period) -- piped straight into hypnoR.
#
# Run interactively, chunk by chunk; not part of either package's test
# suite (uses mrpheus's bundled example data, not synthetic fixtures).

devtools::load_all("/Users/lucas/Documents/GitHub/mrpheus")
devtools::load_all("/Users/lucas/Documents/GitHub/hypnoR")

# ── Load the example staging output ──────────────────────────────────────────
staging <- readRDS(system.file("extdata", "SC4001E0_staging.rds", package = "mrpheus"))
staging

# ── mrpheus -> hypnoR ────────────────────────────────────────────────────────
# The real start_time isn't bundled with the .rds (it comes from the EDF
# header at read_edf() time), so we use a placeholder here based on the
# sleep-staging-demo vignette's note that the cassette started ~16:13 local
# time. Swap this for rec$header$startTime if you have the actual EDF.
mrp_hyp <- export_hypnogram(
  staging,
  epoch_s        = 30,
  start_time     = as.POSIXct("2024-01-01 16:13:00", tz = "UTC"),
  participant_id = "SC4001"
)
mrp_hyp

hyp <- new_hypnogram(mrp_hyp)
hyp

# ── Smoothing ─────────────────────────────────────────────────────────────────
# Cleans up isolated single-epoch flips from stage_epochs()'s unsmoothed
# per-epoch argmax (see the confidence diagnostic below for evidence these
# are genuine borderline calls, not a bug).
hyp_smooth <- smooth_hypnogram(hyp, method = c("aasm_isolated", "min_run"), min_run_epochs = 2)
mean(hyp_smooth$stage != hyp_smooth$stage_raw)  # proportion of epochs changed
table(hyp_smooth$stage_raw, hyp_smooth$stage)   # confusion-style before/after table

# Run-length distribution of REM in the SMOOTHED output -- if these are
# mostly length 2-4 (1-2 min) rather than length 1, min_run_epochs = 2 is
# too low a threshold to have caught them (it only touches length-1 runs).
rl_smooth <- rle(as.character(hyp_smooth$stage))
table(rl_smooth$lengths[rl_smooth$values == "REM"])

# Try a higher threshold and compare
hyp_smooth_4 <- smooth_hypnogram(hyp, method = c("aasm_isolated", "min_run"), min_run_epochs = 4)
mean(hyp_smooth_4$stage != hyp_smooth_4$stage_raw)
rl_smooth_4 <- rle(as.character(hyp_smooth_4$stage))
table(rl_smooth_4$lengths[rl_smooth_4$values == "REM"])

# 23 separate REM runs is a lot more than one night's ~4-6 ultradian cycles
# would predict -- but most of those runs are individually plausible length
# (3.5-8.5 min), so this probably isn't noise smooth_hypnogram() should chase
# further. Check whether compute_cycles(method = "aasm")'s gap-tolerance
# already collapses fragmented REM into a sensible number of cycles instead:
cyc_aasm_smooth <- compute_cycles(hyp_smooth_4, method = "aasm")
nrow(cyc_aasm_smooth)
cyc_aasm_smooth

cyc_ff_smooth <- compute_cycles(hyp_smooth_4, method = "feinberg_floyd")
nrow(cyc_ff_smooth)  # compare: strict method, no gap tolerance

# ── Is the inflated cycle count really about daytime Wake, not smoothing? ────
# The sleep-staging-demo vignette itself restricts to epoch 1001-1950 as "the
# sleep period" for its detailed-view plot -- everything outside that is
# daytime Wake before/after the one real sleep opportunity. A handful of
# scattered REM calls way out in that daytime Wake (as seen in the very first
# screenshot, out past 11:00/13:00) would each register as their own "cycle"
# since they're nowhere near the main nocturnal REM cluster -- inflating the
# count regardless of how well the hypnogram is smoothed. Check by
# restricting to just the sleep-period epochs:
hyp_sleep_only <- window_hypnogram(hyp_smooth_4, from_epoch = 1001L, to_epoch = 1950L)

cyc_aasm_sleep_only <- compute_cycles(hyp_sleep_only, method = "aasm")
nrow(cyc_aasm_sleep_only)
cyc_aasm_sleep_only

# The vignette's 1001:1950 slice was chosen to make a nice-looking plot, not
# as a rigorous sleep-period boundary -- if the real last REM period extends
# past epoch 1950, that hard cutoff truncates it mid-cycle, and since
# compute_cycles() only returns COMPLETE cycles, that final one silently
# disappears rather than getting counted. A more principled window is the
# actual data-driven sleep period: first sleep epoch to last sleep epoch,
# rather than someone else's illustrative slice.
sleep_idx    <- which(as.character(hyp_smooth_4$stage) != "W")
onset_epoch  <- hyp_smooth_4$epoch[sleep_idx[1L]]
offset_epoch <- hyp_smooth_4$epoch[sleep_idx[length(sleep_idx)]]
c(onset_epoch = onset_epoch, offset_epoch = offset_epoch,
  duration_h  = (offset_epoch - onset_epoch + 1) * 30 / 3600)

hyp_sleep_period <- window_hypnogram(hyp_smooth_4, from_epoch = onset_epoch, to_epoch = offset_epoch)

cyc_aasm_sleep_period <- compute_cycles(hyp_sleep_period, method = "aasm")
nrow(cyc_aasm_sleep_period)
cyc_aasm_sleep_period

# ── Metrics ──────────────────────────────────────────────────────────────────
arch <- compute_sleep_architecture(hyp)
arch

trans <- compute_transitions(hyp)
trans$matrix
trans$fragmentation

cyc_ff <- compute_cycles(hyp, method = "feinberg_floyd")
cyc_ff

cyc_aasm <- compute_cycles(hyp, method = "aasm")
cyc_aasm

# ── Diagnostic: are the scattered/isolated REM epochs low-confidence calls? ─────
# stage_epochs() is a pure per-epoch argmax over the LightGBM posteriors, with
# no temporal smoothing/continuity rule -- so isolated single-epoch flips are
# expected precisely where the model is uncertain. This checks that directly
# rather than just asserting it.
staging$run_id <- with(rle(staging$stage), rep(seq_along(lengths), lengths))
run_lengths <- aggregate(epoch ~ run_id, staging, length)
staging$run_length <- run_lengths$epoch[match(staging$run_id, run_lengths$run_id)]

staging$confidence <- pmax(staging$prob_W, staging$prob_N1, staging$prob_N2,
                           staging$prob_N3, staging$prob_REM)

# Distribution of REM run lengths (in epochs) -- lots of length-1 runs would
# mean lots of isolated single-epoch REM calls
table(staging$run_length[staging$stage == "REM"])

# Confidence of isolated (run_length == 1) REM epochs vs. REM epochs that are
# part of a sustained run (run_length >= 5, i.e. >= 2.5 min)
isolated_rem  <- staging$confidence[staging$stage == "REM" & staging$run_length == 1]
sustained_rem <- staging$confidence[staging$stage == "REM" & staging$run_length >= 5]
summary(isolated_rem)
summary(sustained_rem)
# If isolated_rem's confidence is meaningfully lower than sustained_rem's,
# that supports "these are genuine borderline calls", not a bug.

# ── Plots ─────────────────────────────────────────────────────────────────────
# Wrapped in print() because bare top-level expressions only auto-print when
# run line-by-line in the console -- source()'ing this whole file (or
# RStudio's "Source" button) silently discards them otherwise. Also saved to
# PNG so they're viewable regardless of how you ran this.

p1 <- plot_hypnogram(hyp, cycles = cyc_ff)  # x_axis = "auto" -> clock time, since start_time is now set
print(p1)
ggplot2::ggsave("dev/sc4001_hypnogram_clocktime.png", p1, width = 10, height = 3, dpi = 150)

p1b <- plot_hypnogram(hyp, cycles = cyc_ff, x_axis = "hours")
print(p1b)
ggplot2::ggsave("dev/sc4001_hypnogram_hours.png", p1b, width = 10, height = 3, dpi = 150)

p1c <- plot_hypnogram(hyp_smooth, cycles = compute_cycles(hyp_smooth, method = "feinberg_floyd"))
print(p1c)
ggplot2::ggsave("dev/sc4001_hypnogram_smoothed.png", p1c, width = 10, height = 3, dpi = 150)

p2 <- plot_architecture(arch)
print(p2)
ggplot2::ggsave("dev/sc4001_architecture_duration.png", p2, width = 6, height = 4, dpi = 150)

p3 <- plot_architecture(arch, metric = "percentage")
print(p3)
ggplot2::ggsave("dev/sc4001_architecture_pct.png", p3, width = 6, height = 4, dpi = 150)

p4 <- plot_transition_matrix(trans$matrix)
print(p4)
ggplot2::ggsave("dev/sc4001_transition_matrix.png", p4, width = 6, height = 5, dpi = 150)

p5 <- plot_hypnogram(hyp_smooth_4, style = "capsule")
print(p5)
ggplot2::ggsave("dev/sc4001_hypnogram_capsule.png", p5, width = 12, height = 4, dpi = 150)
