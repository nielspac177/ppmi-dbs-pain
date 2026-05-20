# Pre-registration and post-hoc declaration

This document distinguishes pre-specified from post-hoc analyses for full
transparency.

## Pre-specified analyses (analysis plan locked 2026-04-20, manuscript v11)

### Primary
1. Landmark Δ NP1PAIN at +6 to +18 months vs −24 to 0 month baseline.
2. Two one-sided tests for non-inferiority at a ±1 MDS-UPDRS Part I point margin.
3. Positive control: MDS-UPDRS Part III change with the same framework.
4. Cohorts: matched 1:2 PSM cohort (primary), IPW-weighted full cohort (secondary).

### Secondary
1. Linear mixed-effects models with random intercept + slope, three-level
   phase factor (Pre-DBS / Post-DBS / Never-DBS).
2. Generalised estimating equations with inverse-probability-of-treatment
   weights, exchangeable working correlation.
3. Kaplan–Meier time to NP1PAIN ≥ 1 and ≥ 2; Cox regression with seven covariates.
4. Graphical-LASSO partial-correlation network over 15 non-motor variables,
   stratified by arm and analysis window.

### Exploratory
1. Cross-sectional pain–motor association at baseline (replication of
   Pacheco-Barrios 2025 in PPMI).
2. Within-patient ΔPain–ΔUPDRS-III Spearman correlation, Fisher-z between
   arms.
3. PD polygenic risk score, APOE-ε4, cerebrospinal-fluid α-synuclein seeding
   amplification, and GBA carrier status × DBS interaction on Δ Pain.

## Post-hoc robustness analyses (added 2026-05-19)

In response to internal critical-review feedback, nine additional
robustness analyses were performed. **None of these change the
pre-specified primary, secondary, or exploratory conclusions.** All are
clearly labeled `[sprint]` in `MANIFEST.md` and run as the
`sprints/sprint*.R` scripts. They are reported in the manuscript as
sensitivity analyses, not as primary findings.

1. **sprint01** Negative-control outcomes (NP1HALL, NP1URN, NP1COG)
2. **sprint02** Anchor sensitivity sweep across three Never-DBS anchor schemes
3. **sprint03** E-value supplementary table and missing-not-at-random tipping-point
4. **sprint04** Formal Network Comparison Test with bootnet stability
5. **sprint05** Bootstrap Δρ confidence interval, Brant test, profile-likelihood + Firth CIs
6. **sprint06** Cluster-robust (CR2) SEs on LMMs; GEE AR(1) sensitivity
7. **sprint07** PSM overlap, weight distribution, c-statistic, caliper sensitivity
8. **sprint08** Fine-Gray competing-risk subdistribution hazard
9. **sprint09** ΔLEDD as candidate mediator of the pain effect

## OSF link

We will deposit this `PRE_REGISTRATION.md` on the Open Science Framework
upon manuscript submission and link the OSF identifier here.
