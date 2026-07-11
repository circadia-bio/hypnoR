# Compute stage-transition statistics

Builds a stage-to-stage transition probability matrix and derives
fragmentation indices from a staged hypnogram. Works with both full AASM
and coarse actigraphy-derived staging.

## Usage

``` r
compute_transitions(hypnogram, normalise = TRUE, include_wake = TRUE)
```

## Arguments

- hypnogram:

  A `hypnor_hypnogram` object as returned by
  [`new_hypnogram()`](https://hypnor.circadia-lab.uk/reference/new_hypnogram.md)
  or
  [`read_hypnogram()`](https://hypnor.circadia-lab.uk/reference/read_hypnogram.md),
  or any data frame with at minimum `epoch` and `stage` columns – it
  will be passed through
  [`new_hypnogram()`](https://hypnor.circadia-lab.uk/reference/new_hypnogram.md)
  automatically if not already a `hypnor_hypnogram`.

- normalise:

  If `TRUE` (default), each row of the transition count matrix is
  divided by its row sum to give transition probabilities. Rows for a
  from-stage that is never visited are returned as `NA` rather than
  `NaN`. If `FALSE`, raw transition counts are returned.

- include_wake:

  If `TRUE` (default), `"W"` is included as a state in the transition
  matrix like any other stage (including `W`-\>`W` self-transitions). If
  `FALSE`, the matrix is restricted to sleep-stage transitions only: any
  transition into or out of `"W"` is excluded before the matrix is
  built.

## Value

A list with two elements:

- matrix:

  A tibble with one row per *from* stage: a `from` column plus one
  numeric column per *to* stage (transition probabilities or counts).

- fragmentation:

  A one-row tibble with:

  n_transitions

  :   Number of epoch-to-epoch stage changes (self-transitions do not
      count).

  fragmentation_index

  :   Proportion of epochs that are followed by a different stage.

  wake_transitions

  :   Number of transitions into Wake (proxy for arousal burden).

## Details

Fragmentation metrics (`n_transitions`, `fragmentation_index`,
`wake_transitions`) are always computed from the full epoch sequence,
wake included, regardless of `include_wake` – that argument only
controls the shape of the returned `matrix`.

## Examples

``` r
if (FALSE) { # \dontrun{
hyp  <- read_hypnogram("night_001.csv")
trans <- compute_transitions(hyp)
trans$matrix
trans$fragmentation

# Sleep-stage transitions only, excluding Wake
compute_transitions(hyp, include_wake = FALSE)
} # }
```
