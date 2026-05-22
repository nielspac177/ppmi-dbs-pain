# ADR-0005 · Symmetric-midpoint Never-DBS anchor for coupling analyses (POSIXct fix)

- Status: **Accepted**
- Date: 2026-04-20 (original); 2026-05-19 (refactor into shared helper)

## Context

For the within-patient longitudinal pain–motor coupling analysis (Δ-Δ
Spearman), Never-DBS patients have no real anchor event analogous to
DBS surgery. The visit grid must be symmetric pre- vs post-anchor across
arms so that ΔPain and ΔUPDRS-III are computed over comparable elapsed
disease time.

The original implementation in `26b_pain_motor_coupling_matched.R`
defined the Never-DBS anchor as the midpoint of the patient's observed
follow-up:

```r
first <- min(INFODT_orig)
last  <- max(INFODT_orig)
anchor <- first + as.numeric(difftime(last, first, units = "days")) / 2
```

This contained a **silent POSIXct bug**: when `first` is POSIXct,
`first + numeric` adds *seconds*, not days. The midpoint anchor was
collapsing to ~6 minutes after `first_visit`, effectively forcing all
Never-DBS controls to be anchored at their first visit — defeating the
symmetric-window goal.

The bug was undetected because Never-DBS Δ-Δ ρ "looked plausible"
under the buggy anchor (0.354 vs the corrected 0.29). Detection came
from Figure 7 panel B showing Never-DBS data starting at month 0 with
no negative-time bins — flagged by the first author.

## Decision

Extract the symmetric-midpoint anchor logic into a single helper
function `compute_symmetric_midpoint_anchors(rel_raw)` in
`R/helpers/pain_helpers.R`, which:

1. Filters Never-DBS rows with non-NA `INFODT_orig`.
2. Casts to `Date` first.
3. Computes midpoint via `Date + numeric` arithmetic (days, not seconds).
4. Returns a per-patient anchor table.

A complementary `rebind_time_cols(rel_raw, anchors)` rebuilds the time
columns from the fresh anchor.

A regression test in
`tests/testthat/test-anchor-midpoint.R` verifies that the function
correctly returns a midpoint ~365 days from the first visit when the
follow-up is 2 years, and that the POSIXct-bug pattern returns < 1 day
from `first` (negative regression test).

## Consequences

**Positive**
- The fix lives in one place; future refactors cannot silently
  reintroduce the POSIXct bug.
- Unit tested.
- Three sprint scripts (Sprint 02, Sprint 05) that previously
  re-implemented the anchor inline now call the helper.

**Negative**
- The published numbers for Δ-Δ ρ changed (e.g., Never-DBS 0.354 →
  0.29) after the fix. This required a manuscript revision and is
  documented in `CHANGELOG.md`.

## Alternatives considered

- **Use the cohort-median anchor for Never-DBS** (the legacy
  `load_full_ppmi_rel` convention). Loses individual-patient
  alignment. Used as the cohort-median sensitivity (`sprint02`).
- **Use each patient's first visit as anchor.** No symmetric pre/post
  window. Used as the patient-anchor sensitivity (`sprint02`).
