# dev/check_coverage.R
#
# Test coverage analysis via covr, following the same approach used in
# zeitR: run coverage, find zero/low-coverage lines, write tests to close
# the gaps, then note the before/after percentage in NEWS.md.
#
# Run interactively; never source() as a whole.

devtools::load_all()

# ── Overall coverage ──────────────────────────────────────────────────────────
cov <- covr::package_coverage()
cov
covr::percent_coverage(cov)

# ── Per-file breakdown ────────────────────────────────────────────────────────
covr::coverage_to_list(cov)$filecoverage

# ── Specific untested lines (the actionable part) ────────────────────────────
covr::zero_coverage(cov)

# ── Interactive HTML report (opens in browser/viewer) ────────────────────────
covr::report(cov)
