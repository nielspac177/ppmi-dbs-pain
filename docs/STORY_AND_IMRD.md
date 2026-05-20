# Pain paper — story and IMRD skeleton

(Dated 2026-05-19. Author: Niels Pacheco-Barrios.)

## 5-bullet message

1. **Primary safety floor**: In a PPMI matched-cohort target-trial-emulation analysis (n = 1,484; 105 DBS, 1,379 Never-DBS), STN-DBS is non-inferior to medical therapy on the longitudinal course of self-reported pain (MDS-UPDRS-I item 9) at a ±1-point margin across 4 years (TOST P < 10⁻¹², all anchor schemes).

2. **Network reorganization (headline)**: The non-motor symptom partial-correlation network differs structurally between arms at late follow-up (Network Comparison Test P = 0.050 at +24-48 mo), with pain becoming more tightly coupled to autonomic/sleep nodes after stimulation while loosening from motor severity.

3. **Pain–motor decoupling**: Within-patient Δ-Δ coupling is attenuated after DBS (matched bootstrap Δρ = −0.16 [95 % CI −0.60, +0.29]; full cohort −0.16 [−0.47, +0.15]). Replicates and extends Pacheco-Barrios 2025 (Life, PMID 40003677) cross-sectional finding longitudinally.

4. **Mechanism**: ΔLEDD does NOT mediate the pain effect (matched ACME P = 0.69, full P = 0.07) — consistent with a stimulation-circuit mechanism rather than dopamine-replacement washout.

5. **Genetic / biomarker stratification**: PD-PRS, APOE-ε4, CSF α-synuclein SAA, and GBA carrier status × DBS interactions on Δ Pain are all null — the first systematic test of this in any cohort.

**Elevator pitch**: *"DBS doesn't change* how much *pain PD patients report; it changes* what their pain is linked to *— uncoupling it from motor severity and routing it toward autonomic and sleep domains over years of follow-up. This shifts the conceptual model of DBS from a 'motor-only' to a 'symptom-architecture-modulating' therapy."*

---

## Title

**Stimulation reshapes the pain–symptom architecture in Parkinson disease: a target-trial-emulation matched longitudinal cohort in the PPMI**

---

## IMRD skeleton (subtitles + key sentences per paragraph)

### ABSTRACT (structured, ~300 words)

(As in main narrative summary above. Include: importance, objective, design, exposure, main outcomes and measures, results, conclusions and relevance.)

### INTRODUCTION (4 paragraphs)

- **P1. Pain is a high-burden, undertreated non-motor symptom of PD.** Cite Mylius 2025 Lancet Neurol, Pacheco-Barrios 2025 Life.
- **P2. STN-DBS reduces pain at 6-24 months in single-arm studies — but a long-term, matched-comparator picture is missing.** Cite Cury 2014, Jung 2015, Dafsari EuroInf-2 2019, NILS 36mo 2020, meta Jung 2021.
- **P3. Beyond the level of pain, the structure of how pain relates to other non-motor domains may itself change with stimulation.** Cite Hollunder 2024 Nat Commun, Tosin 2023, Stephenson 2023.
- **P4. We test three pre-specified questions and one replication.** Non-inferiority + network reorganization + pain-motor coupling + genetic stratification.

### METHODS (9 subsections)

1. Cohort and data source
2. Target trial emulation framework
3. Outcomes (primary + negative + positive controls)
4. Statistical analysis — pre-specified primary
5. Statistical analysis — secondary
6. Statistical analysis — exploratory
7. Sensitivity and robustness (the 9 sprints)
8. Causal assumptions and DAG
9. Software and reproducibility

### RESULTS (6 subsections, each anchored to a figure)

- R1. Cohort and balance — Figure 1 (methods schematic), Figure 2 (STROBE), Figure 3 (love plot)
- R2. Pain trajectory is non-inferior — Figure 4 (landmark Δ Pain TOST + UPDRS-III positive control)
- R3. The non-motor network reorganizes — Figure 5 (GLASSO × arm × window + NCT)
- R4. Pain–motor coupling is attenuated — Figure 6 (cross-sectional ρ + Δ-Δ scatter)
- R5. Genetics/biomarkers don't modify — Figure 7 (forest of 4 interactions)
- R6. Robustness checks — Figure 8 / Supp (sprint summary forest)

### DISCUSSION (6 paragraphs)

- D1. Principal finding and reframe
- D2. Relation to prior literature
- D3. Mechanism (LEDD non-mediation, noradrenergic hypothesis)
- D4. Strengths (TTE, controls, robustness, novelty)
- D5. Limitations (n=105, EARLYSTIM-era, NP1PAIN as single item, underpowered ρ)
- D6. Implications (clinical / research / methodological)

### CONCLUSION (1 short paragraph)

Reframes "motor-only" DBS as "symptom-architecture-modulating".

---

## Figure roster (final)

- **Main text (6 figures)**
  1. Methods schematic (existing `Figure_methods_schematic`)
  2. STROBE flow diagram (existing `Figure1_STROBE`)
  3. Cohort balance + positive control UPDRS-III + landmark Δ Pain TOST (combine `Figure7_positive_control` + `Figure8_landmark`)
  4. GLASSO networks × arm × window + NCT P-values (new — uses `sprint04_pain_neighbours` data + recompose with NCT annotations)
  5. Pain–motor coupling — cross-sectional ρ over time + Δ-Δ scatter, matched cohort (`Figure26b_pain_motor_coupling_matched` + bootstrap CI overlay)
  6. Genetics × DBS forest (existing `Figure25_genetics_forest`)

- **Supplementary**
  - S1. Causal DAG (`Figure_causal_DAG`)
  - S2. Pipeline callgraph (`Figure_callgraph`)
  - S3. Anchor sensitivity sweep (`sprint02_anchor_sensitivity`)
  - S4. Negative-control outcomes (`sprint01_negative_controls`)
  - S5. MNAR tipping-point (`sprint03_mnar_tipping`)
  - S6. PSM diagnostics (`sprint07_psm_overlap` + `sprint07_love_plot`)
  - S7. Competing-risk Fine-Gray CIF (`sprint08_cif_pain_worsening`)
  - S8. Full-cohort pain-motor coupling (existing `Figure26_pain_motor_coupling`)
  - S9. Alluvial trajectories (matched + full, prop + abs — pick 2)
  - S10. Sex × DBS, BMI × DBS (existing supplement)

---

## What this skeleton enables

- Manuscript prose can be drafted paragraph-by-paragraph from this scaffold.
- Each Results subsection has a designated figure → predictable production order.
- Discussion paragraphs have a designated topic so they don't sprawl.
- The Methods subsection numbering aligns 1:1 with the existing repo script labels (`MANIFEST.md`).

## Workflow for drafting

1. Niels picks one subsection (e.g. R3 — "The non-motor network reorganizes").
2. Read the corresponding tables/figures (`sprint04_nct_global.csv`, `sprint04_pain_neighbours.png`).
3. Draft 1-2 paragraphs against the bullet points in this file.
4. The shared `docs/STORY_AND_IMRD.md` stays as the source of truth for the
   target structure.

Manuscript versions are kept *outside* the public repo per `.gitignore`.
