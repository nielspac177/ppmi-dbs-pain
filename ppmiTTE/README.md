# ppmiTTE — Target-trial-emulation utilities for PD DBS observational studies

A small R package extracted from the `ppmi-dbs-pain` analysis. Provides
reusable functions for:

- Symmetric-midpoint anchor construction (fixes the POSIXct → numeric bug)
- Landmark Δ outcome computation + TOST non-inferiority test
- GLASSO partial-correlation network estimation with a fixed-ρ fallback
- Network Comparison Test wrapper
- 1:2 propensity-score matching with sensible defaults

## Install

```r
# from GitHub (eventual)
remotes::install_github("nielspac177/ppmi-dbs-pain", subdir = "ppmiTTE")

# or locally (during development)
R CMD INSTALL ppmiTTE/
```

## Example

```r
library(ppmiTTE)
# rel = long data frame (PPMI-shaped)
anchors <- compute_symmetric_midpoint_anchors(rel)
rel_sym <- rebind_time_cols(rel, anchors)
delta   <- landmark_delta(rel_sym)
ni_test <- tost_non_inferiority(delta, margin = 1)
print(ni_test)
```

## Status

WIP. Currently a skeleton with the four core functions. The full set of
sprint-style analyses (E-value, MNAR tipping-point, Brant/Firth,
cluster-robust SE, Fine-Gray, mediation) will be added in v0.2+.
