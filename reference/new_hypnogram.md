# Construct a hypnoR hypnogram object

`new_hypnogram()` is the low-level constructor for the
`hypnor_hypnogram` class used throughout `hypnoR`. It normalises
hypnogram-shaped input – whether a bare tibble (as produced by
[`zeitR::export_hypnogram()`](https://zeitr.circadia-lab.uk/reference/export_hypnogram.html)
or
[`read_hypnogram()`](https://hypnor.circadia-lab.uk/reference/read_hypnogram.md))
or a specially classed object (currently:
[`mrpheus::export_hypnogram()`](https://mrpheus.circadia-lab.uk/reference/export_hypnogram.html)'s
`mrpheus_hypnogram`) – into the single internal representation that
every other `hypnoR` function expects.

## Usage

``` r
new_hypnogram(x, ...)

# Default S3 method
new_hypnogram(
  x,
  epoch_sec = NULL,
  resolution = NULL,
  subject_id = NULL,
  source = NULL,
  ...
)

# S3 method for class 'mrpheus_hypnogram'
new_hypnogram(
  x,
  epoch_sec = NULL,
  resolution = NULL,
  subject_id = NULL,
  source = NULL,
  ...
)
```

## Arguments

- x:

  A data frame with at minimum `epoch` and `stage` columns, or an object
  with a dedicated `new_hypnogram()` method (currently:
  `mrpheus_hypnogram`). Recognised optional columns: `time` (`POSIXct`),
  `subject_id`, `source`.

- ...:

  Passed to methods; currently unused.

- epoch_sec:

  Epoch duration in seconds. When `x` carries its own epoch duration
  (e.g. an `mrpheus_hypnogram`'s `epoch_s` attribute) that value is used
  unless `epoch_sec` is explicitly supplied here. Falls back to `30L`
  when no value can be determined from either source.

- resolution:

  `"aasm"`, `"coarse"`, or `NULL` (default). When `NULL`, resolution is
  auto-detected from the stage labels present in `x` (or, for
  `mrpheus_hypnogram` input, taken from its `resolution` attribute).

- subject_id:

  Character or `NULL`. Overrides any subject/participant identifier
  carried by `x`.

- source:

  Character or `NULL`. Overrides any source/scorer label carried by `x`.

## Value

A tibble of class `hypnor_hypnogram` with columns `epoch` (integer),
`time` (`POSIXct`, `NA` if unknown), `stage` (ordered factor),
`subject_id` (character, `NA` if unknown), and `source` (character, `NA`
if unknown). The detected `epoch_sec` and `resolution` are attached as
attributes.

## Examples

``` r
if (FALSE) { # \dontrun{
# From a bare tibble (e.g. zeitR::export_hypnogram() output)
new_hypnogram(zeitr_hyp)

# From mrpheus::export_hypnogram() output
new_hypnogram(mrpheus_hyp)
} # }
```
