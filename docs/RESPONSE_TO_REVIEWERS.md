# Response to reviewers — major revisions (template)

Tracking the 5 priority revisions identified in `PEER_REVIEW_2026-05-21.md`.

| # | Issue | Status | Action |
|---|---|---|---|
| 1 | Network reorganization overstated | TODO | Apply Holm correction across 3 NCT windows; soften abstract / Conclusions; add bootstrap edge heat-map to supplement. |
| 2 | TOST margin too wide | TODO | Add `sprint12_tost_margin_grid.R` testing ±0.3 / 0.5 / 0.75 / 1.0; defend chosen margin against PPMI-derived MCID. |
| 3 | Bayesian GBA reconciliation | TODO | Re-run sprint11 on **real** patient-level genetics data; resolve frequentist/Bayesian inconsistency. Flag as hypothesis-generating if real signal. |
| 4 | Immortal-time / anchor asymmetry | TODO | Add `sprint13_clone_censor_weight.R` sequential-trial emulation. |
| 5 | IPCW promoted to primary | TODO | Edit abstract + Results §"Pain trajectory is non-inferior" to report IPCW-stabilised estimate as primary; demote unweighted to sensitivity. Translate MNAR tipping into clinical units. |

Other major comments to address:
- Mediation: add Δ NHY / Δ GDS / Δ SCOPA / Δ ESS as alternative mediators.
- Pain-motor decoupling: compute Δρ in unmatched non-overlapping complement.
- External validity: report demographics of DBS arm; restrict inference language.
- Channeling: explicitly contrast TOST (mean) vs Fine-Gray (threshold) in Results summary.
