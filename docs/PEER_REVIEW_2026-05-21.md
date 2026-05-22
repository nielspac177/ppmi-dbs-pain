# Peer review report — 21 May 2026

This is an internal peer-review report applied to `MANUSCRIPT_DRAFT.md` by a
JAMA-Neurology-style structured reviewer agent. The recommendation is
**major revisions** with five priority next steps. Specific revisions
are tracked in `RESPONSE_TO_REVIEWERS.md`.

---

## Summary of the work

Pacheco-Barrios and colleagues present a target-trial-emulation (TTE) analysis of the PPMI Curated Data Cut (November 2024) to characterize the long-term effect of deep brain stimulation (DBS) on the trajectory of self-reported pain (NP1PAIN) in idiopathic PD. From an analytic cohort of 1,484 patients (105 DBS recipients; 1,379 Never-DBS), the authors construct a 1:2 nearest-neighbour propensity-score-matched sub-cohort (n = 170; 64 DBS / 106 controls) and test four pre-specified questions: non-inferiority of DBS on the 4-year pain trajectory (±1-point margin), reorganization of the non-motor symptom network, preservation of pain–motor coupling, and modification by polygenic / biomarker status.

Central claims: (1) DBS is non-inferior to medical therapy on the 4-year pain trajectory (TOST P < 10⁻¹²); (2) the non-motor symptom network reorganizes at +24 to +48 months (NCT max-edge-strength P = 0.050); (3) within-patient ΔPain–ΔUPDRS-III coupling is attenuated post-DBS (Δρ = −0.16, 95 % CI −0.60, +0.29); (4) no detectable genetic × DBS interaction. The authors propose reframing DBS as a "symptom-architecture-modulating" therapy.

## Major comments

1. **Network reorganization claim resting on a borderline P (NCT max-edge P = 0.050) is overstated** in the abstract and Conclusions. Global strength does not differ at any window (P 0.13 / 0.65 / 0.53), and most pain-anchored edge CIs cross zero. Downgrade declarative phrasing to hypothesis-generating; apply multiplicity correction across the three NCT windows.

2. **"Pre-registered post-hoc" framing is contradictory.** Stamp `PRE_REGISTRATION.md` date; clarify what was registered before vs after data access; provide family-wise multiplicity correction (Holm) for secondary endpoints.

3. **TOST margin of ±1 point on a 0–4 ordinal scale is too wide** (a full clinical-category shift). The Horváth 2017 MCID is for the *total* MDS-UPDRS Part I, not the single NP1PAIN item. Either anchor the margin to a PPMI-derived patient-MCID or present TOST results across a grid (0.3, 0.5, 0.75, 1.0). Drop the cosmetically impressive P < 10⁻¹² formatting.

4. **Channeling vs threshold-crossing tension.** Mean change is non-inferior (TOST), but Fine-Gray HR for reaching NP1PAIN ≥ 2 is 1.86 (1.28–2.69) — a near-doubling of clinical-threshold crossings. Conclusions should acknowledge this tension explicitly, not bury it as "directionally consistent with channeling".

5. **Immortal time and anchor asymmetry.** DBS patients must survive to surgery; Never-DBS anchors are artificial. The three anchor sensitivity sweeps help but only the symmetric midpoint mimics post-treatment immortal time. Add a clone-censor-weight (sequential-trial-emulation) sensitivity to supplement.

6. **Pain–motor decoupling CI crosses zero — claim overstated.** Bootstrap Δρ = −0.16 (95 % CI −0.60, +0.29). Directional consistency between matched and full cohorts is partly artefactual (samples overlap). Compute Δρ in the *unmatched complement* for an independent replication; report bootstrap power for Δρ = −0.25 explicitly.

7. **Mediation framing too strong.** ΔLEDD ACME is borderline in the full cohort (P = 0.07) and the proportion-mediated CI is unstable (−2.97 to +2.38). Add alternative mediators (Δ NHY, Δ GDS, Δ SCOPA, Δ ESS). Avoid "rule-out" language.

8. **Bayesian GBA × DBS posterior contradicts frequentist null.** `sprint11_bayesian_genetics.csv` reports GBA posterior mean +0.47 (CrI 0.24, 0.73) and P(effect > 0) = 1.00 — i.e., essentially all posterior mass on a positive (DBS-harmful-in-GBA) effect — despite an LRT P = 0.40. Reconcile. Either the Bayesian framing differs in conditioning set, the bootstrap-as-posterior approximation is misleading, or there is a real signal worth reporting as hypothesis-generating. This is the single most important inconsistency to resolve. NOTE: this was a synthetic-data run; on real data the posterior will differ.

9. **Dropout asymmetry (Never-DBS 61.9 % vs DBS 34.9 %) threatens the IPCW interpretation.** Promote IPCW-stabilised estimator to the *primary* abstract estimator (currently in Supplement). Translate the MNAR tipping-point into clinical units ("≥ 30 % of Never-DBS dropouts shifted by ≥ 1 pain point would overturn").

10. **External validity is more constrained than acknowledged.** PPMI is biomarker-research, predominantly white, academic-centre, self-selected. Report racial/ethnic/educational/geographic distribution of the DBS arm. Revise Conclusions to limit inference to early-PD DBS recipients in biomarker cohorts.

## Statistical review

The TOST margin is too wide to be discriminating; tighten or anchor.
IPTW vs IPCW two-stage logic should be made explicit. Brant test is underpowered at the NP1PAIN ≥ 3 boundary. Bootstrap Δρ and Fisher-z report — present both side-by-side. GEE AR1 vs exchangeable: post-DBS phase robust; pre-DBS phase sensitive (retire any pre-DBS divergence narrative). Fine-Gray vs cause-specific Cox — clarify which clinical question each addresses. Bootstrap-as-Bayesian-posterior is a defensible approximation under flat priors and large samples, but with n_GBA-carriers ≈ 30 the asymptotics are strained; either fit `brms`/`rstanarm` or rename `sprint11` to "bootstrap distribution".

## Reporting checklist compliance

STROBE: mostly addressed; missing per-variable missingness counts in Table 1, funding statement absent in draft. TRIPOD: not a prediction model paper, but the c=0.885 propensity model warrants TRIPOD-style calibration/internal-validation reporting. ROBINS-I: confounding adequate; selection bias partial; classification of interventions **missing** (no DBS target recorded); deviations from intended interventions **missing** (stimulator off-time, programming adherence not captured). CONSORT-NI: margin justification inadequate.

## Reviewer recommendation

**Major revisions.** The work is methodologically ambitious, transparently reported, and reproducible. The core mean-trajectory non-inferiority is well-supported. Three of the four headline claims (network reorganization, pain-motor decoupling, "symptom-architecture-modulating" reframe) are over-asserted relative to the evidence. None of these issues is fatal; all are addressable.

## Five priority next steps

1. **Re-frame network reorganization as hypothesis-generating**, with multiplicity correction across NCT windows; bootstrap edge CIs in a supplementary heat-map.
2. **Justify or tighten the TOST margin**; report sensitivity across a margin grid.
3. **Reconcile Bayesian GBA × DBS** with frequentist null (on real data); if real, report as hypothesis-generating with mechanistic discussion.
4. **Address immortal time and anchor asymmetry** via clone-censor-weight sensitivity.
5. **Promote IPCW-stabilised estimator to primary**; translate MNAR tipping-point into clinical units.
