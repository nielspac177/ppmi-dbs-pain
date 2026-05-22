# ADR-0003 · Sprint-script convention for post-hoc analyses

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

Adopt a **sprint-script convention**:

- All post-hoc analyses live in `sprints/sprintNN_<name>.R`, numbered
  in order of addition. Currently `sprint01` … `sprint11`.
- Each sprint script is self-contained: it sources only
  `R/helpers/pain_helpers.R`, sets `set.seed(20260519)`, defines window
  constants explicitly, and writes outputs via `save_table()` and
  `save_fig_pub()`.
- Each sprint produces at least one CSV table under
  `outputs/tables/sprintNN_*.csv` and (where relevant) a
  PNG+PDF figure.
- `MANIFEST.md` labels every sprint `[sprint]` (vs `[primary]`,
  `[secondary]`, `[exploratory]`).
- `PRE_REGISTRATION.md` documents which analyses were pre-specified
  before data access and which are sprints.
- The dashboard (`scripts/build_dashboard.py`) auto-detects sprint CSVs
  and renders one panel per sprint, so adding `sprint12_*.R` requires
  no dashboard code change.

## Consequences

**Positive**
- The post-hoc audit trail is immediately legible (one folder).
- Reviewers can grep for `sprint*` to see the full robustness layer.
- Sprints can be added or revised without touching the pre-specified
  pipeline scripts under `R/`.
- CI can run `make sprints` as a single target.

**Negative**
- Slight code duplication across sprints (each loads helpers
  independently). Mitigated by the small size of each sprint.
- "Sprint" terminology is borrowed from agile software workflows and
  may confuse readers expecting a scientific term. README clarifies.

## Alternatives considered

- **Integrate sprints into the numbered notebook sequence.** Hides the
  post-hoc distinction. Rejected.
- **One big `robustness.R`** script. Loses per-analysis output
  separability. Rejected.
- **Convert sprints into vignettes inside the `ppmiTTE` package.**
  Considered for the v0.2 release; deferred.
