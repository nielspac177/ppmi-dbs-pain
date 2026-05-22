# ADR-0004 · TOST ±1-point margin on the 0–4 NP1PAIN scale

- Status: **Accepted (under reviewer scrutiny — see Sprint 12 follow-up)**
- Date: 2026-05-19

## Context

The primary analysis is non-inferiority of DBS vs medical therapy on
the 4-year trajectory of NP1PAIN, evaluated by two one-sided tests
(TOST). The non-inferiority margin must be chosen before data analysis
and must be **clinically meaningful** — not so large that the test is
trivially significant, not so small that real differences cannot
be ruled out.

NP1PAIN is a single MDS-UPDRS Part I item with five ordinal levels (0,
1, 2, 3, 4) corresponding to: none / slight / mild / moderate /
severe. The dynamic range is 4 points.

Horváth et al., *J Parkinsons Dis*. 2017, established minimal
clinically important differences (MCIDs) for MDS-UPDRS *total* Part I,
not for individual items. Patient-anchored MCIDs for NP1PAIN
specifically have not been published.

## Decision

Set the TOST non-inferiority margin at **±1 MDS-UPDRS Part I point**,
on the basis that:

- 1 point corresponds to a full clinical-category shift (e.g., slight
  → mild → moderate). This is unambiguously a clinically meaningful
  change.
- 1 point ≈ 25 % of the dynamic range (4 points), comparable to MCID
  conventions for other ordinal PD instruments.
- A wider margin would be uninformative; a tighter margin would be
  underpowered with n_DBS = 105 in PPMI.

The choice is pre-registered (`PRE_REGISTRATION.md`).

A peer reviewer (`PEER_REVIEW_2026-05-21.md`, comment 3) has objected
that ±1 point is too wide — that a full-category shift is *itself*
clinically substantial, not an equivalence boundary. We accept that
challenge as a Major Revision item and will run a **margin-grid
sensitivity (±0.3, 0.5, 0.75, 1.0)** in `sprint12_tost_margin_grid.R`
as part of the revision.

## Consequences

**Positive**
- Conservative non-inferiority claim. If DBS were ±1-point harmful,
  the conclusion would flip — and that magnitude is clinically
  important.
- Computationally trivial to extend to a grid (Sprint 12 forthcoming).

**Negative**
- The cosmetic P < 10⁻¹² is uninformative and may invite reviewer
  skepticism. The manuscript will report only `P < .001`.
- Reviewer pressure for a tighter margin is reasonable; we may need
  to retighten to ±0.5 for revision.

## Alternatives considered

- **±0.5-point margin** (half a clinical category). Will be added as
  sensitivity. Considered as primary for revision.
- **Patient-anchored MCID derived in PPMI.** Requires a separate
  anchor-based analysis (e.g., PGIC question, which PPMI does not
  collect). Not feasible without a substitute.
- **No non-inferiority — superiority only.** Would force the paper into
  a "DBS does not improve pain" framing, which fails to address the
  clinical question of whether DBS *harms* pain.
