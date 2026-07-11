# dev/test_zeitR_pipeline.R
#
# End-to-end smoke test: zeitR's bundled ActTrust validation recording
# (input1.txt) -- the same fixture used in zeitR's own pipeline-parity
# tests -- piped straight into hypnoR. Mirrors dev/test_mrpheus_pipeline.R,
# but exercises the coarse (W / Sleep / Quiet sleep) path instead of full
# AASM.
#
# Run interactively, chunk by chunk; not part of either package's test
# suite (uses zeitR's bundled example data, not synthetic fixtures).

devtools::load_all("/Users/lucas/Documents/GitHub/zeitR")
devtools::load_all("/Users/lucas/Documents/GitHub/hypnoR")

# ── Run the zeitR pipeline ────────────────────────────────────────────────────
result <- run_pipeline(
  system.file("extdata", "input1.txt", package = "zeitR"),
  tz    = "UTC",
  quiet = TRUE  # input1.txt has 5 known minor timestamp gaps; not an error
)
result
result$nights

# ── zeitR -> hypnoR ──────────────────────────────────────────────────────────
zeitr_hyp <- export_hypnogram(result)
zeitr_hyp

hyp <- new_hypnogram(zeitr_hyp)
hyp
attr(hyp, "resolution")  # "coarse" -- no N1/N2/N3/REM labels

# ── Metrics ──────────────────────────────────────────────────────────────────
arch <- compute_sleep_architecture(hyp)
arch
# rem_lat_min, sws_lat_min, pct_n1..pct_rem all NA (need AASM staging);
# pct_sleep / pct_quiet_sleep populated instead.

trans <- compute_transitions(hyp)
trans$matrix       # 3x3 instead of 5x5
trans$fragmentation

# compute_cycles() is AASM-only -- this should error clearly, not silently
# return nonsense, since there's no REM stage to segment cycles on.
tryCatch(
  compute_cycles(hyp),
  error = function(e) cat("Expected error:", conditionMessage(e), "\n")
)

# ── Windowing a single night ─────────────────────────────────────────────────
# input1.txt spans several nights (see result$nights); restrict to night 1
# for a cleaner single-night demo rather than analysing the whole multi-day
# recording at once.
night1 <- result$nights[1L, ]
hyp_night1 <- window_hypnogram(hyp, lights_off = night1$bed_time, lights_on = night1$get_up_time)
nrow(hyp_night1)

arch_night1 <- compute_sleep_architecture(hyp_night1)
arch_night1

# ── Plots ─────────────────────────────────────────────────────────────────────
print(plot_hypnogram(hyp_night1))
ggplot2::ggsave("dev/zeitr_hypnogram_step.png", plot_hypnogram(hyp_night1), width = 10, height = 3, dpi = 150)

print(plot_hypnogram(hyp_night1, style = "capsule"))
ggplot2::ggsave("dev/zeitr_hypnogram_capsule.png", plot_hypnogram(hyp_night1, style = "capsule"), width = 10, height = 3, dpi = 150)

print(plot_architecture(arch_night1))
ggplot2::ggsave("dev/zeitr_architecture.png", plot_architecture(arch_night1), width = 6, height = 4, dpi = 150)

print(plot_transition_matrix(trans$matrix))
ggplot2::ggsave("dev/zeitr_transition_matrix.png", plot_transition_matrix(trans$matrix), width = 5, height = 4.5, dpi = 150)
