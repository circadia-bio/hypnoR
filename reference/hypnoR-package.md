# hypnoR: Hypnogram Handling, Plotting, and Sleep Architecture Metrics

Provides a staging-agnostic layer for hypnogram ingestion, sleep
architecture metric computation, cycle segmentation, and transition
analysis. Accepts full AASM-staged hypnograms (W / N1 / N2 / N3 / REM)
from mrpheus and coarser actigraphy-derived hypnograms (W / Sleep /
Quiet sleep) from zeitR; all metric functions degrade gracefully
depending on staging resolution. Includes publication-ready plotting via
theme_circadia(). Designed as the hypnogram layer of the Circadia Lab
ecosystem, feeding into syncR::sync().

## See also

Useful links:

- <https://github.com/circadia-bio/hypnoR>

- Report bugs at <https://github.com/circadia-bio/hypnoR/issues>

## Author

**Maintainer**: Lucas França <lucas.franca@northumbria.ac.uk>
([ORCID](https://orcid.org/0000-0003-0853-1319))

Authors:

- Lucas França <lucas.franca@northumbria.ac.uk>
  ([ORCID](https://orcid.org/0000-0003-0853-1319))

- Mario Leocadio-Miguel <mario.miguel@northumbria.ac.uk>
  ([ORCID](https://orcid.org/0000-0002-7248-3529))
