---
title: "Supplementary Materials — Deep brain stimulation, pain trajectory, and the symptom architecture of Parkinson disease"
fontsize: 11pt
geometry: margin=1in
---

# Supplementary Materials

Pacheco-Barrios *et al.*, 2026 — supplementary to the main manuscript.

This supplement contains the full numerical results of the sixteen pre-specified and post-hoc robustness analyses summarised in the main manuscript, together with reporting-checklist tables (STROBE, TRIPOD, ROBINS-I) and the directed acyclic graph used to derive the minimal adjustment set.

---

## eMethods

### eMethods 1 — Analytic cohort and synthetic-data fixture

The analytic cohort comprised 1,484 participants of the Parkinson's Progression Markers Initiative (PPMI; clinicaltrials.gov NCT01141023) Curated Data Cut, November 2024, with at least one MDS-UPDRS Part I item 9 (NP1PAIN) observation. Of these, 105 received deep brain stimulation (DBS); the remaining 1,379 are denoted Never-DBS. A deterministic, seeded synthetic PPMI-shaped data fixture, sufficient to exercise the analytic pipeline end-to-end without applying to PPMI, is bundled with the public code repository under `data-synth/` and is clearly labelled as synthetic data.

### eMethods 2 — Target trial emulation

The analysis emulates a hypothetical pragmatic trial in which eligible Parkinson-disease patients are randomised to receive deep brain stimulation within a follow-up window, or to continue medical therapy. The per-protocol average treatment effect is the causal contrast of interest. The DBS arm anchor is the first DBS surgery date. Three Never-DBS anchor schemes are compared in eAnalysis 2 (each patient's first visit, the cohort-median DBS calendar date, and each patient's own follow-up midpoint), and a duration-matched sequential-trial emulation (eAnalysis 13) provides explicit immortal-time correction.

### eMethods 3 — Statistical analyses

The primary estimator is an inverse-probability-of-censoring-weighted (IPCW) Welch contrast in the full cohort. The censoring model is a logistic regression of "remains in follow-up at the +6 to +18 month landmark window" on age, sex, disease duration, baseline pain, body-mass index, levodopa-equivalent daily dose, MDS-UPDRS Part III, Hoehn &amp; Yahr stage, and arm; stabilised weights are trimmed at the 99th percentile. Non-inferiority is evaluated by two one-sided tests at four pre-specified margins: ±0.3, ±0.5, ±0.75, and ±1.0 MDS-UPDRS Part I points. The ±1-point margin is registered as the primary; the additional margins are reported because the appropriate minimally clinically important difference for the single NP1PAIN item has not been derived in PPMI.

A 1:2 propensity-score-matched cohort (caliper 0.02 of the SD of the logit-propensity; matched n = 170; 64 DBS / 106 Never-DBS) serves as the secondary sensitivity estimator. The propensity model includes age, sex, disease duration, MDS-UPDRS Part III, Hoehn &amp; Yahr stage, levodopa-equivalent daily dose, and body-mass index. Propensity-model discrimination, by the c-statistic, was 0.885.

Secondary analyses include random-intercept linear mixed-effects models, generalised estimating equations under exchangeable and AR(1) working correlations, Fine-Gray competing-risk subdistribution hazards for time to NP1PAIN ≥ 2 (dropout as competing event), graphical-LASSO partial-correlation networks over 15 non-motor variables tested by Network Comparison Test (Holm-adjusted across three windows), and per-mediator analyses for six candidate mediators (LEDD, Hoehn &amp; Yahr, GDS, SCOPA, ESS, UPDRS-III).

---

## eAnalyses (sensitivity and robustness)

| ID | Analysis | Headline result |
|---|---|---|
| 1 | Negative-control outcomes (NP1HALL, NP1URN, NP1COG) | All four outcomes (pain + three negatives) TOST-NI at ±1; effect sizes uniformly &lt; 0.15 points |
| 2 | Anchor sensitivity sweep (3 Never-DBS anchor schemes) | All three schemes conclude NI at ±1; between-arm Δ ∈ [−0.094, +0.082] |
| 3 | E-values + MNAR tipping-point | E-value 5.09 (lower CL 1.45) for worsener RR; tipping-point at ±1.0 |
| 4 | GLASSO network + Network Comparison Test | Late-post P = 0.050 uncorrected, P = 0.150 Holm-adjusted |
| 5 | Bootstrap Δρ + Brant test + Firth-penalized CIs | Matched Δρ = −0.16 (95 % CI −0.60, +0.29); PO assumption holds (Brant P &gt; 0.70) |
| 6 | Cluster-robust SEs (CR2) + GEE AR(1) sensitivity | LMM contrasts robust under CR2; Pre-DBS × time sensitive to corstr (excl. P = .079 → AR(1) P = .59) |
| 7 | PSM diagnostics + caliper sweep | c-statistic = 0.885; balance preserved across calipers 0.05–0.20 |
| 8 | Fine-Gray competing-risk subdistribution hazard | HR (DBS vs Never-DBS, reaching pain ≥ 2) = 1.86 (1.28–2.69), P = .001 |
| 9 | ΔLEDD mediation | ACME P = .69 (matched); .07 (full); no mediation |
| 10 | IPCW for informative dropout | Stabilised Δ = −0.053 (95 % CI −0.293, +0.187); NI conclusion preserved |
| 11 | Bootstrap distribution for genetic interactions | All four interactions null; per-term posterior summaries reported |
| 12 | TOST margin grid (±0.3 / 0.5 / 0.75 / 1.0) | NI concluded at every margin; P = .009 at ±0.3 |
| 13 | Sequential-trial emulation (duration-matched) | Δ = −0.037; TOST NI at ±0.5 (P = .004) |
| 14 | Independent-complement Δρ replication | Unmatched-complement Δρ = −0.08; direction concordant with matched cohort |
| 15 | Multi-mediator analysis (6 candidates) | All six null (ACME P ≥ .15); rules out single-pathway mediation |
| 16 | DBS-arm demographics audit | Only sex available in PPMI_basic1; flagged as limitation |

Complete CSVs for each analysis are deposited at <https://github.com/nielspac177/ppmi-dbs-pain/tree/main/outputs/aggregated>.

---

## Reporting-checklist tables

### STROBE checklist (key items)

| Item | Topic | Page / section |
|---|---|---|
| 1a | Title indicates design | Title |
| 1b | Abstract structured | Abstract |
| 2 | Background | Introduction |
| 3 | Objectives | Introduction (final paragraph) |
| 4 | Study design | Methods §1, §2 |
| 5 | Setting | Methods §1 |
| 6 | Participants + matching criteria | Methods §1; eMethods 2; Table 1 |
| 7 | Variables | Methods §3 |
| 8 | Data sources / measurement | Methods §1, §3 |
| 9 | Sources of bias + handling | Methods §4–§7; eAnalyses 2, 5, 8, 13 |
| 10 | Study size | Results §1 |
| 12 | Statistical methods | Methods §4–§7 |
| 13 | Participants flow | Figure 2 (STROBE) |
| 14 | Descriptive data | Results §1; Table 1 |
| 15 | Outcome data | Results §2–§6 |
| 16 | Main results | Results §2; Table 2 |
| 17 | Other analyses | Results §3–§6; eAnalyses 1–16 |
| 18 | Key results | Discussion §1 |
| 19 | Limitations | Discussion §5 |
| 20 | Interpretation | Discussion §1–§4 |
| 21 | Generalisability | Discussion §5 |
| 22 | Funding | Title page |

### ROBINS-I summary

| Domain | Risk of bias | Comment |
|---|---|---|
| Confounding | Moderate | DAG-derived adjustment set + PSM + IPW + E-value reporting |
| Selection of participants | Low | Single inclusion criterion uniformly applied |
| Classification of interventions | Moderate | DBS target not recorded in PPMI (eMethods 1, Limitations) |
| Deviations from intended interventions | Low | Per-protocol per target-trial emulation |
| Missing data | Moderate | IPCW + tipping-point MNAR sensitivity (eAnalysis 10, 3) |
| Measurement of outcomes | Moderate | NP1PAIN is a single 0–4 ordinal item; replicate with KPPS/BPI in future work |
| Selection of reported result | Low | Pre-specified primary; 16 documented analyses |
| Overall | Moderate | Conclusions presented with appropriate caveats |

---

## eFigures

### eFigure 1 — Causal directed acyclic graph

See `figures/eFigure_1_causal_DAG.{png,pdf}`. Source (dagitty syntax) is in the public repository at `outputs/aggregated/causal_dag.txt`. The implied minimal adjustment set for the total effect of deep brain stimulation on the pain trajectory is {age, sex, disease duration, MDS-UPDRS Part III, Hoehn &amp; Yahr stage, levodopa-equivalent daily dose, body-mass index, baseline NP1PAIN, GDS/STAI composite}. The primary propensity model includes the first seven of these; a sensitivity analysis adding the remaining two is reported in eTable 1.

### eFigure 2 — Pipeline callgraph

See `figures/eFigure_2_callgraph.{png,pdf}`. Mermaid source available in the repository.

### eFigure 3 — Cohort and analysis flow (Sankey)

See `figures/eFigure_3_sankey.{png,pdf}`. Interactive version on the companion website at <https://nielspac177.github.io/ppmi-dbs-pain/>.

---

## eTables

### eTable 1 — TOST across margin grid

| Margin (MDS-UPDRS-I points) | Δ (DBS − Never-DBS) | 95 % CI | TOST P_max | NI concluded? |
|---|---|---|---|---|
| ±0.3 | −0.016 | (−0.249, +0.217) | 0.009 | Yes |
| ±0.5 | −0.016 | (−0.249, +0.217) | 4.2 × 10⁻⁵ | Yes |
| ±0.75 | −0.016 | (−0.249, +0.217) | 7.6 × 10⁻⁹ | Yes |
| ±1.0 (pre-specified primary) | −0.016 | (−0.249, +0.217) | 4.9 × 10⁻¹³ | Yes |

### eTable 2 — Anchor sensitivity sweep

| Anchor | Δ | 95 % CI | TOST P_max (±1) | NI? |
|---|---|---|---|---|
| Patient first visit | −0.016 | (−0.249, +0.217) | 4.9 × 10⁻¹³ | Yes |
| Cohort-median DBS date | −0.094 | (−0.379, +0.191) | 1.8 × 10⁻⁹ | Yes |
| Symmetric midpoint | +0.082 | (−0.150, +0.314) | 1.0 × 10⁻¹⁴ | Yes |

### eTable 3 — Multi-mediator analysis (all six candidates)

| Mediator | n | ACME | 95 % CI | ACME P | Total effect P |
|---|---|---|---|---|---|
| Δ LEDD | 642 | −0.032 | (−0.076, +0.011) | .15 | .94 |
| Δ NHY | 408 | +0.007 | (−0.030, +0.048) | .67 | .63 |
| Δ GDS | 513 | +0.002 | (−0.011, +0.016) | .84 | .96 |
| Δ SCOPA | 509 | −0.009 | (−0.042, +0.015) | .43 | .94 |
| Δ ESS | 511 | +0.013 | (−0.007, +0.046) | .26 | .87 |
| Δ UPDRS-III | 537 | −0.003 | (−0.058, +0.041) | .89 | .35 |

### eTable 4 — Network Comparison Test (Holm-adjusted)

| Window | Max-edge-strength P_raw | P_Holm | Global strength Δ | Global strength P |
|---|---|---|---|---|
| Baseline | 0.888 | 0.888 | +1.11 | 0.14 |
| Early-post (+6 to +18 mo) | 0.114 | 0.228 | −0.49 | 0.65 |
| Late-post (+24 to +48 mo) | **0.050** | 0.150 | −1.75 | 0.53 |

---

## Data and code availability

The complete analysis code, eight Architecture Decision Records, sixteen analyses, a synthetic data fixture, a Docker container, a GitHub Codespaces configuration, a Makefile-driven workflow, and an interactive results website are available at <https://github.com/nielspac177/ppmi-dbs-pain> (Zenodo DOI to be assigned at submission). Raw PPMI participant-level data are not redistributed under the PPMI Data Use Agreement; access is via <https://www.ppmi-info.org/access-data-specimens/download-data>.
