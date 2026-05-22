# ADR-0003 · Analysis-script convention for post-hoc analyses

- Status: **Accepted**
- Date: 2026-05-19

## Context

After an internal critical-review pass, eleven additional robustness
analyses were identified as necessary additions to the original
pre-specified pipeline. These analyses (negative controls, anchor
sensitivity, E-value, MNAR tipping, NCT, bootstrap Δρ, Brant + Firth,
robust SE + AR(1), PSM diagnostics, Fine-Gray, mediation, IPCW,
Bayesian genetics) are post-hoc by definition and must be transparently
labeled as such, both for the audit trail and for compliance with
emerging journal post-hoc-disclosure norms (Lancet, NEJM, JAMA-family
all increasingly request this).

Folding them into the existing numbered notebook sequence would have
made the post-hoc/pre-specified distinction invisible.

## Decision

Adopt a **numbered-analysis convention**:

- All post-hoc analyses live in `analyses/sprintNN_<name>.R`, numbered
  in order of addition. Currently `Analysis 01` … `Analysis 11`.
- Each numbered analysis is self-contained: it sources only
  `R/helpers/pain_helpers.R`, sets `set.seed(20260519)`, defines window
  constants explicitly, and writes outputs via `save_table()` and
  `save_fig_pub()`.
- Each analysis produces at least one CSV table under
  `outputs/tables/sprintNN_*.csv` and (where relevant) a
  PNG+PDF figure.
- `MANIFEST.md` labels every analysis `[robustness]` (vs `[primary]`,
  `[secondary]`, `[exploratory]`).
- `PRE_REGISTRATION.md` documents which analyses were pre-specified
  before data access and which are analyses.
- The dashboard (`scripts/build_dashboard.py`) auto-detects analysis CSVs
  and renders one panel per analysis, so adding `Analysis 12_*.R` requires
  no dashboard code change.

## Consequences

**Positive**
- The post-hoc audit trail is immediately legible (one folder).
- Reviewers can grep for `analysis*` to see the full robustness layer.
- Analyses can be added or revised without touching the pre-specified
  pipeline scripts under `R/`.
- CI can run `make analyses` as a single target.

**Negative**
- Slight code duplication across analyses (each loads helpers
  independently). Mitigated by the small size of each analysis.
- "Analysis" terminology is borrowed from agile software workflows and
  may confuse readers expecting a scientific term. README clarifies.

## Alternatives considered

- **Integrate analyses into the numbered notebook sequence.** Hides the
  post-hoc distinction. Rejected.
- **One big `robustness.R`** script. Loses per-analysis output
  separability. Rejected.
- **Convert analyses into vignettes inside the `ppmiTTE` package.**
  Considered for the v0.2 release; deferred.
