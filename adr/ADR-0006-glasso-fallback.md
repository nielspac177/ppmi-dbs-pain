# ADR-0006 · GLASSO fixed-ρ fallback when EBICglasso returns empty network

- Status: **Accepted**
- Date: 2026-05-19

## Context

The non-motor symptom network analysis (Analysis 04) estimates GLASSO
partial-correlation networks separately by arm × time window. In small
samples (DBS arm at +24–48 months, n ≈ 48 with 15 variables),
EBICglasso with default hyperparameters (`γ = 0.5`) frequently selects
an **empty network** — every edge regularised to zero. This is a known
sparsity failure mode for EBICglasso in n/p ≤ 5 regimes.

An empty network breaks the Network Comparison Test (NCT) because the
permutation distribution becomes degenerate.

## Decision

In `R/helpers/pain_helpers.R` (and the `ppmiTTE::build_glasso_network`
package wrapper), implement a two-tier procedure:

1. **Primary**: fit `bootnet::estimateNetwork(..., default = "EBICglasso",
   tuning = 0, lambda.min.ratio = 0.001)`.
2. **Fallback**: if the resulting graph has all-zero edges, refit
   with `glasso::glasso(S, rho = 0.12)`, which uses a fixed regularisation
   parameter consistent with the network published in the original
   paper. Convert the precision matrix to partial-correlation via
   `−cov2cor(wi)`.

Log a message indicating which arm/window triggered the fallback.

## Consequences

**Positive**
- The pipeline never errors out on small-sample arms.
- The published `ρ = 0.12` value preserves continuity with the
  original GLASSO published in the source paper.
- NCT permutation can run on all three windows uniformly.

**Negative**
- The fallback introduces a discontinuity in regularisation strength
  between arms/windows that use EBIC vs the fallback. This is
  acknowledged in the manuscript Methods.
- The fixed `ρ = 0.12` is heuristic; we have not formally compared
  ρ values 0.05 / 0.10 / 0.15 / 0.20 for stability of the late-post
  NCT P. **TODO** in revision: add Analysis 13 with a ρ-grid stability
  check.

## Alternatives considered

- **Raise `tuning = 0.5` (BIC instead of EBIC)** to encourage denser
  networks. Considered but the same empty-network behaviour reappears
  at smaller n.
- **Use partial correlations directly without regularisation.** Loses
  the sparsity argument central to GLASSO.
- **Skip arms/windows where EBICglasso returns empty.** Loses
  inferential symmetry across arms. Rejected.
