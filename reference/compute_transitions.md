# Compute stage-transition statistics

Builds a stage-to-stage transition probability matrix and derives
fragmentation indices from a staged hypnogram. Works with both full AASM
and coarse actigraphy-derived staging.

## Usage

``` r
compute_transitions(hypnogram, normalise = TRUE)
```

## Arguments

- hypnogram:

  A tibble returned by
  [`read_hypnogram()`](https://hypnor.circadia-lab.uk/reference/read_hypnogram.md).

- normalise:

  If `TRUE` (default), each row of the transition count matrix is
  divided by its row sum to give transition probabilities. If `FALSE`,
  raw transition counts are returned.

## Value

A list with two elements:

- matrix:

  A square tibble (stages × stages) of transition probabilities or
  counts. Row = *from* stage, column = *to* stage.

- fragmentation:

  A one-row tibble with:

  n_transitions

  :   Total number of stage transitions.

  fragmentation_index

  :   Proportion of epochs that are followed by a different stage.

  wake_transitions

  :   Number of transitions to Wake (proxy for arousal burden).

## Examples

``` r
if (FALSE) { # \dontrun{
hyp  <- read_hypnogram("night_001.csv")
trans <- compute_transitions(hyp)
trans$matrix
trans$fragmentation
} # }
```
