# hypnoR — development script
# Run interactively; never source() as a whole.

library(devtools)

# ── Load / check ──────────────────────────────────────────────────────────────
load_all()
document()
check()

# ── Tests ─────────────────────────────────────────────────────────────────────
test()

# ── pkgdown ───────────────────────────────────────────────────────────────────
pkgdown::build_site()
pkgdown::preview_site()
