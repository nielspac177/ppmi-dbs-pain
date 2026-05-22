# ADR-0008 · Target-agnostic DBS framing in PPMI

- Status: **Accepted**
- Date: 2026-05-20

## Context

The PPMI Curated Data Cut does not record the surgical target of DBS
implantation. The standard targets in clinical practice are
subthalamic nucleus (STN), globus pallidus internus (GPi), and
occasionally ventral intermediate thalamus (VIM). Each has a different
non-motor profile; pallidal stimulation in particular is associated
with a different pain-response trajectory than STN (Follett et al.,
*N Engl J Med* 2010; CSP 468 trial).

The original draft of this paper assumed STN-predominance and used
"STN-DBS" throughout. The first author identified during revision
that PPMI is target-agnostic, and that assuming STN exposes the paper
to a reviewer objection that cannot be answered from the data.

## Decision

Reframe the entire paper, codebase, dashboard, and citation metadata
as **target-agnostic DBS**:

- Replace "STN-DBS" with "DBS" everywhere in our own text.
- Retain "subthalamic" in cited prior-literature references where the
  source paper studied STN specifically (Cury 2014, Jung 2015,
  Dafsari 2019, Strauss 2023, etc.) — those authors made a target
  claim, we are accurate when we cite them.
- Add an explicit Limitation paragraph noting that the cohort is
  expected to be a mixture of subthalamic and pallidal recipients,
  and that pain effects may be heterogeneous by target — a hypothesis
  PPMI cannot test.
- Update `CITATION.cff`, `README.md`, `MANUSCRIPT_DRAFT.md`,
  `docs/index.qmd`, `scripts/build_dashboard.py`,
  `R/build_causal_dag.R`, and sprint01 comment.

## Consequences

**Positive**
- Eliminates a reviewer objection that we cannot answer from the
  data.
- More honest scientific framing: PPMI is a registry, not a
  procedure cohort.
- Future linkages to the Vercise Genus / Boston Scientific Allay /
  Medtronic Activa registries that *do* record target become a
  natural extension.

**Negative**
- The Discussion's mechanistic interpretation (e.g.,
  subthalamic-pallidal projections to mesencephalic locomotor
  circuits) is now slightly less specific. We resolve this by
  reframing the mechanism as "basal-ganglia–brainstem" rather than
  "subthalamic-pallidal".
- Some pre-existing figure captions and supplementary materials still
  reference STN. These are updated in the v1.1 release.

## Alternatives considered

- **Restrict the analysis to STN-presumed cases** by indirect inference
  (e.g., decade of surgery, centre, programmer log). Too speculative.
  Rejected.
- **Run separate sensitivity analyses for "STN-likely" vs "GPi-likely"**
  subsets. No reliable feature for the split in PPMI. Rejected.
- **Restrict the cohort to known-STN cases via external linkage.** Would
  require an additional data-sharing agreement; not currently feasible.
