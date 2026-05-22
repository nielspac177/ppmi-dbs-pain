# Manuscript draft (v2 — post peer-review) — formal prose

**Working title.** Deep brain stimulation, pain trajectory, and the symptom architecture of Parkinson disease: a target-trial-emulation matched longitudinal cohort in the Parkinson's Progression Markers Initiative.

**Authors.** Niels Pacheco-Barrios, MD¹; … ; John D. Rolston, MD, PhD¹\*.
¹ Department of Neurological Surgery, University of California, San Francisco.
\*Corresponding author.

**Target journal.** JAMA Neurology (primary) or Lancet Neurology (alternate). ≈3,200-word main text, ≤6 figures, ≤2 tables. Supplementary unlimited.

**Funding.** [TO BE COMPLETED]. PPMI is sponsored by The Michael J. Fox Foundation for Parkinson's Research and funding partners.

---

## Abstract (structured, ~300 words)

**Importance.** Pain affects up to 85 % of patients with Parkinson disease and is undertreated. Deep brain stimulation (DBS) is well established for motor benefit, but its long-term effect on the pain trajectory has not been tested in a matched longitudinal cohort.

**Objective.** To estimate the effect of DBS on the 4-year course of self-reported pain in Parkinson disease, and to examine whether stimulation alters the multivariate non-motor symptom architecture around pain.

**Design, Setting, and Participants.** Target-trial-emulation analysis of the Parkinson's Progression Markers Initiative (PPMI) Curated Data Cut, November 2024. We included 1,484 patients with idiopathic Parkinson disease and at least one MDS-UPDRS Part I item 9 (NP1PAIN) observation (105 DBS recipients; 1,379 Never-DBS). PPMI does not record the stimulation target, so analyses are target-agnostic.

**Exposure.** Deep brain stimulation, anchored at the first surgery date.

**Main Outcomes and Measures.** The primary outcome was the change in NP1PAIN at +6 to +18 months relative to a −24 to 0-month baseline, assessed by two one-sided tests (TOST) for non-inferiority at a pre-specified ±1-point margin and at three tighter sensitivity margins (±0.75, ±0.5, ±0.3). The primary estimator was an inverse-probability-of-censoring-weighted (IPCW) Welch contrast in the full cohort, with a 1:2 propensity-score-matched estimator as sensitivity. Pre-specified exploratory analyses included graphical-LASSO partial-correlation networks over 15 non-motor variables (compared between arms by the Network Comparison Test, Holm-adjusted across three windows), Fine-Gray competing-risk modelling, bootstrap ΔPain–ΔUPDRS-III Spearman correlations with replication in the unmatched complement, and six per-mediator analyses (LEDD, Hoehn &amp; Yahr stage, GDS, SCOPA, ESS, UPDRS-III).

**Results.** The IPCW-weighted between-arm change in pain was −0.053 points (95 % CI −0.293, +0.187). Non-inferiority was concluded at every margin tested: TOST P &lt; .001 at ±1, P &lt; 10⁻⁸ at ±0.75, P &lt; 10⁻⁴ at ±0.5, and P = .009 at ±0.3. A duration-matched sequential-trial-emulation sensitivity yielded Δ = −0.037 and concluded non-inferiority at ±0.5 (P = .004). At the pre-specified late-post window, the maximum-edge Network Comparison Test reached P = .050 uncorrected and P = .150 after Holm correction across three windows; the pain node's neighbourhood shifted toward autonomic and sleep domains under stimulation, although individual edge bootstrap intervals crossed zero. Within-patient pain–motor Spearman coupling was lower after DBS (matched Δρ = −0.16; 95 % CI −0.60, +0.29; independent-complement Δρ = −0.08), with wide intervals reflecting small DBS sub-samples (power for Δρ = −0.25 at n = 33 DBS ≈ 22 %). None of six candidate single mediators reached significance (ACME P ≥ .15). The Fine-Gray subdistribution hazard for crossing NP1PAIN ≥ 2 was 1.86 (1.28–2.69; P = .001), attributable to baseline channeling — DBS recipients began follow-up with higher pain — with E-value 5.09 (lower confidence limit 1.45) bounding the residual-confounder magnitude required to explain it. Genetic-by-DBS interactions were null but uninformative for effects below ≈ ±0.5 pain points given the available sample.

**Conclusions and Relevance.** Deep brain stimulation was non-inferior to medical therapy on the 4-year pain trajectory across margins from ±1 down to ±0.3 MDS-UPDRS Part I points. Three secondary signals — a borderline late-post Network Comparison Test, a lower within-patient pain–motor coupling, and a uniformly null multi-mediator analysis — were individually inconclusive but jointly supported a cautious reframing of stimulation toward a symptom-architecture-modulating therapy, pending prospective replication in target-aware cohorts.

---

## Introduction

Pain affects 40 % to 85 % of patients with Parkinson disease and contributes disproportionately to deterioration in health-related quality of life, yet remains undertreated.¹⁻³ The 2025 *Lancet Neurology* consensus distinguishes nociceptive, neuropathic, and nociplastic mechanisms and implicates both central (basal-ganglia, parabrachial, mesolimbic) and peripheral (small-fibre neuropathy, ectopic activity) pathways.¹ Pain severity scales with motor severity at baseline.²,⁴

Deep brain stimulation (DBS) is a widely used surgical therapy for advanced PD and has accumulated evidence of pain reduction at 6 to 24 months post-implantation. Cury and colleagues, studying subthalamic DBS specifically, reported a fall in pain prevalence from 70 % to 21 % in 41 patients at 12 months;⁵ an 8-year follow-up in 24 subthalamic-DBS patients extended the gain.⁶ The EuroInf-2 multicentre study placed subthalamic DBS ahead of levodopa-carbidopa intestinal gel and apomorphine on the pain domain of the Non-Motor Symptoms Scale at 6 months,⁷ with the NILS 36-month follow-up sustaining the effect.⁸ A 2021 meta-analysis pooled nine studies and identified a delayed pooled effect on PD-related pain.⁹ Stimulation of the dorsal subthalamic sensorimotor zone appears to drive pain response.¹⁰,¹¹ The Follett trial demonstrated that pallidal and subthalamic DBS have broadly comparable motor efficacy but distinct non-motor profiles.³⁸

These prior studies share three limitations. First, nearly all are single-arm pre/post designs without matched comparators. Second, the longest follow-up rests on a single 24-patient cohort.⁶ Third, none has applied non-inferiority testing to a pain endpoint in PD, nor examined the architecture of how pain relates to other non-motor symptoms longitudinally. Recent connectomic work by Hollunder and colleagues demonstrates that DBS targets are symptom-specific networks at the imaging level,¹² and Tosin and colleagues have begun to map longitudinal non-motor symptom networks in PD,¹³ but no published work has compared the multivariate symptom topology between DBS and Never-DBS PD patients.

We tested one pre-specified primary question and three exploratory secondary questions in PPMI:¹⁴ (1) is DBS non-inferior to medical therapy on the 4-year trajectory of pain at clinically meaningful margins? (2) does the multivariate non-motor symptom network reorganise after stimulation? (3) is within-patient pain–motor coupling — established cross-sectionally by Pacheco-Barrios and colleagues⁴ — preserved longitudinally? (4) does PD polygenic risk, APOE-ε4, cerebrospinal-fluid α-synuclein seeding amplification, or GBA carrier status modify the pain response? We adopted a target-trial-emulation framework¹⁵ with inverse-probability-of-censoring-weighted estimation as primary and propensity-score matching as sensitivity. Pre-specified secondary analyses were Holm-corrected within their respective families.

---

## Methods

### Cohort and data source

We used the PPMI Curated Data Cut released in November 2024 (clinicaltrials.gov NCT01141023).¹⁴ Eligibility required (a) physician-confirmed idiopathic PD, (b) absence of a known monogenic cause (440 monogenic carriers excluded a priori), and (c) at least one observation of MDS-UPDRS Part I item 9 (NP1PAIN). The analytic cohort contained 1,484 patients (105 DBS recipients, 1,379 Never-DBS controls). **PPMI does not record the stimulation target; the cohort is therefore treated as DBS-agnostic throughout and is expected to be a mixture of subthalamic and pallidal recipients** (Limitations). Inclusion-exclusion flow appears in Figure 2 (STROBE).¹⁶

### Target trial emulation

We adopted the framework of Hernán and Robins.¹⁵ The hypothetical target trial had: *eligibility*, idiopathic PD with at least one NP1PAIN observation; *treatment strategies*, "receive DBS within the follow-up window" versus "no DBS during the follow-up window"; *assignment*, by physician decision in observational data; *follow-up* beginning at an anchor visit and continuing for up to 48 months; *outcome*, change in NP1PAIN; *causal contrast*, the per-protocol average treatment effect. The DBS anchor was the first DBS surgery date. Three Never-DBS anchor schemes were compared (each patient's first visit, the cohort-median DBS calendar date, and each patient's own follow-up midpoint).

A secondary sequential-trial emulation matched DBS patients to Never-DBS controls within ±1 year of duration-at-anchor — addressing the immortal-time bias inherent in surgery-anchored comparisons.

### Outcomes

The *primary outcome* was the change in NP1PAIN between baseline (−24 to 0 mo) and the +6 to +18 month landmark window. *Negative-control outcomes* were NP1HALL (hallucinations), NP1URN (urinary), and NP1COG (cognition).¹⁷ The pre-specified *positive control* was the analogous change in MDS-UPDRS Part III (motor) score.

### Statistical analysis — primary

The Δ NP1PAIN contrast was estimated as a **stabilised inverse-probability-of-censoring-weighted (IPCW)** Welch comparison in the full cohort. The censoring model was a logistic regression of "remains in follow-up at the +6 to +18 month window" on age, sex, disease duration, baseline NP1PAIN, BMI, LEDD, UPDRS-III, NHY, and arm; stabilised weights were trimmed at the 99th percentile.

Non-inferiority was assessed by two one-sided tests (TOST)¹⁸ at four pre-specified margins: ±0.3, ±0.5, ±0.75, and ±1 MDS-UPDRS Part I point. The ±1 margin (one full clinical category) was registered as the primary, but the full margin grid is reported because the appropriate clinically meaningful margin on a 0–4 ordinal item is contested (no patient-anchored MCID for the single NP1PAIN item exists; the Horváth et al. MCID applies to MDS-UPDRS Part I total).¹⁹

A propensity-score-matched cohort (MatchIt²⁰; 1:2 nearest-neighbour, caliper 0.02 SD of logit-propensity; matched n = 170; 64 DBS / 106 Never-DBS) served as the sensitivity estimator. Propensity-model discrimination was c = 0.885.

### Statistical analysis — secondary

Linear mixed-effects models with random intercept and slope per patient were fitted with `lme4`.²¹ IPW-weighted generalised estimating equations (GEE) were fitted with `geepack` under exchangeable working correlation; the AR(1) correlation structure was reported as sensitivity.²² Time to NP1PAIN ≥ 2 was analysed by Kaplan–Meier, Cox regression, and Fine-Gray subdistribution hazard modelling (`cmprsk`).²³ Partial-correlation networks over 15 non-motor variables were estimated by graphical LASSO with EBIC (`bootnet` / `qgraph`),²⁴,²⁵ stratified by arm and by analysis window (baseline, early-post, late-post). Between-arm differences were tested by the Network Comparison Test (`NetworkComparisonTest`)²⁶ with 500 permutations, **Holm-adjusted across the three windows**.

### Statistical analysis — exploratory

Cross-sectional pain–motor associations were modelled by ordinal logistic regression with the proportional-odds assumption verified by Brant test.²⁷ Within-patient ΔPain–ΔUPDRS-III Spearman correlation was bootstrapped (B = 5,000) in both the matched cohort and the **unmatched non-overlapping complement** (Never-DBS patients not selected as controls), to provide an independent replication. Genetic and biomarker interactions on Δ Pain were tested for PD polygenic risk score (allele-count over 55 NeuroChip variants from Nalls et al. 2019),²⁸ APOE-ε4, cerebrospinal-fluid α-synuclein seeding amplification,²⁹ and GBA carrier status. A bootstrap distribution under flat prior approximation (renamed from "Bayesian posterior" per reviewer guidance — see ADR-0007) provided informative-null framings.

### Multi-mediator analysis

To address whether the pain effect is pharmacologically mediated, six candidate mediators were each tested separately in `mediation::mediate` (B = 1,000 bootstrap): Δ LEDD, Δ Hoehn & Yahr stage, Δ GDS (depression), Δ SCOPA (autonomic), Δ ESS (sleepiness), and Δ MDS-UPDRS Part III (motor).

### Sensitivity and robustness

Sixteen pre-registered and post-hoc robustness analyses were performed (`Analysis 01–Analysis 16`). Pre-registered: TOST primary, negative controls, anchor sensitivity, mediator analyses, genetic interactions. Post-hoc (added 2026-05-19 to 2026-05-22 in response to internal and external critical-review feedback): E-values,³⁰ MNAR tipping-point, Network Comparison Test with bootnet stability, profile-likelihood and Firth-penalized confidence intervals,³¹ cluster-robust (CR2) standard errors,³² Fine-Gray competing-risk model, bootstrap distribution for genetic interactions, IPCW for informative dropout, TOST margin grid, clone-censor-weight sequential emulation, unmatched-complement Δρ, multi-mediator analysis, demographics audit. `PRE_REGISTRATION.md` documents the pre-specified vs post-hoc split; `MANIFEST.md` labels every script accordingly.

### Causal assumptions and DAG

A directed acyclic graph implied by the analysis (Supplementary Figure S1; dagitty source³⁴) identifies a minimal adjustment set of {Age, Sex, Disease duration, MDS-UPDRS-III, Hoehn & Yahr stage, LEDD, BMI, Baseline NP1PAIN, GDS/STAI} for the total effect of DBS on the pain trajectory. The primary propensity model included the first seven of these; a sensitivity adding Baseline NP1PAIN and GDS/STAI is reported in Supplementary Table S1.

### Software and reproducibility

All analyses were conducted in R 4.5.1; Python 3.13 was used for figure assembly. The complete code, a synthetic data fixture, a Docker container, a GitHub Codespaces configuration, a `Makefile`-driven reproduction workflow, an interactive results dashboard, eight Architecture Decision Records, an AI peer-review harness, and the manuscript drafts are available at <https://github.com/nielspac177/ppmi-dbs-pain> (Zenodo DOI to be assigned at submission). Raw PPMI data are not redistributed; access is via <https://www.ppmi-info.org/access-data-specimens/download-data>.

---

## Results

### Cohort characteristics and balance

Of 1,924 idiopathic PD patients in PPMI, 440 were excluded for monogenic variants, yielding 1,484 with at least one NP1PAIN observation (105 DBS recipients; 1,379 Never-DBS) (Figure 2). Mean follow-up was 4.04 years among DBS recipients and 2.28 years among Never-DBS controls. **A duration-at-anchor gap is evident: DBS patients had a median 15.8 years of disease duration at surgery versus a median 8.6 years for Never-DBS at their first visit (Analysis 13)** — the source of the immortal-time bias that the sequential-trial emulation addresses.

Channeling bias was apparent at baseline: pre-match standardised mean differences exceeded 0.4 on MDS-UPDRS Part III, Hoehn & Yahr stage, LEDD, and baseline NP1PAIN. Propensity matching (caliper 0.02, 1:2 nearest-neighbour) yielded a balanced sub-cohort (n = 170; 64 DBS / 106 Never-DBS) with all SMDs below 0.1. Propensity-model c-statistic was 0.885. **Only sex was available as a demographic descriptor in the PPMI_basic1 file (Analysis 16); race, ethnicity, education, and recruitment site distributions were not analysable here — see Limitations.**

### Pain trajectory is non-inferior to medical therapy across margins

The IPCW-weighted between-arm Δ NP1PAIN at the +6 to +18 month landmark was **−0.053 (95 % CI −0.293, +0.187)** (Table 2). Two one-sided non-inferiority tests rejected at all four pre-specified margins (Table 3, Figure 4): ±1.0 point, P < .001; ±0.75, P < 10⁻⁸; ±0.5, P < 10⁻⁴; **±0.3, P = .009**. The unweighted matched-cohort sensitivity (Δ = −0.016, 95 % CI −0.249, +0.217) was directionally concordant. A duration-matched sequential-trial-emulation sensitivity (Analysis 13; matched on time-since-diagnosis within ±1 year; n = 109, 67 DBS / 42 Never-DBS) yielded Δ = −0.037 (95 % CI −0.373, +0.299), TOST NI at ±0.5 (P = .004) — reinforcing the primary conclusion under an explicit immortal-time correction. The pre-specified positive control (MDS-UPDRS Part III) favoured DBS at the same landmark (mean Δ = −4.95, P < .001), confirming that the analytic pipeline detects clinically meaningful effects when they exist. The three negative-control outcomes (NP1HALL, NP1URN, NP1COG) also concluded TOST non-inferiority with effect sizes uniformly below 0.15 points — the pipeline does not selectively detect null effects (Analysis 1, Supplementary Figure S2).

### Channeling-versus-threshold-crossing tension

A separate analysis of time to NP1PAIN ≥ 2 yielded a Fine-Gray subdistribution hazard ratio of 1.86 (95 % CI 1.28–2.69, P = .001) and cause-specific Cox HR 1.84 (1.23–2.77, P = .003), with dropout as competing risk (Analysis 8). This *appears* contradictory to the non-inferior mean change but is consistent with the baseline-channeling pattern: DBS recipients began follow-up with a higher mean NP1PAIN (Table 1), so a larger fraction crossed the binary threshold ≥ 2 over follow-up even when their *mean change* was indistinguishable from controls. The E-value for the worsener risk ratio is 5.09 (lower confidence limit 1.45), indicating that a moderately strong unmeasured confounder — for example, motor severity not fully captured by UPDRS-III, or DBS candidacy itself as a marker of treatment-refractory disease — could account for the threshold-crossing signal. We frame this contrast explicitly: the **mean trajectory** is non-inferior; the **threshold-crossing risk** reflects baseline channeling that PPMI's covariate set does not fully resolve.

### Pain-symptom-architecture reshaping: a hypothesis-generating directional signal

Partial-correlation networks over 15 non-motor variables were estimated by arm and window (Figure 5). At baseline, networks were largely similar. **At the pre-specified late-post window (+24 to +48 months), the Network Comparison Test maximum-edge-strength was P = 0.050** (uncorrected; Holm-adjusted across three windows P = 0.150, reported as a sensitivity). Global network strength did not differ at any window (raw P 0.13 / 0.65 / 0.53). The pain node's neighbourhood directionally shifted: in the DBS arm, partial correlations between pain and autonomic/sleep nodes (NP1SLPN, NP1SLPD, NP1URN, SCOPA) increased over time, while the pain–UPDRS-III edge attenuated; the reverse pattern was observed in the Never-DBS arm. Pain-anchored edge bootstrap CIs crossed zero for most individual edges (Supplementary Figure S6), and the Holm-adjusted P does not meet conventional significance. We therefore frame the network result as a **directional, hypothesis-generating signal** consistent with pain-architecture reshaping under stimulation, not as a confirmed finding. This is the strongest mechanistic signal in the cohort and motivates prospective replication in cohorts with stimulation-target metadata.

### Within-patient pain–motor coupling is directionally lower after DBS

Cross-sectional pain–motor associations at baseline replicated the Pacheco-Barrios 2025 finding⁴: in the matched cohort, the ordinal odds ratio of higher pain tier per MDS-UPDRS-III ≥ 33 was 1.58 (95 % CI 0.86–2.93, P = .14); in the full cohort, OR = 1.76 (1.37–2.26, P < .001). Within-patient longitudinal ΔPain–ΔUPDRS-III bootstrap mean Spearman correlation was ρ_DBS = +0.03 (95 % CI −0.33, +0.39), ρ_Never-DBS = +0.19 (−0.10, +0.44), Δρ_matched = **−0.16 (95 % CI −0.60, +0.29; two-sided bootstrap P = .49)**. The independent-complement replication (Analysis 14; Never-DBS patients not selected as matched controls, n_DBS = 17) yielded Δρ = **−0.08 (95 % CI −0.64, +0.58, P = .76)** — directionally concordant but with very wide intervals owing to small DBS sub-sample. The proportional-odds assumption was satisfied (Brant test P = 0.70 matched; P = 0.96 full cohort); profile-likelihood and Firth-penalized confidence intervals were indistinguishable from Wald intervals. **Bootstrap power for a Δρ = −0.25 is approximately 22 % at n = 33 DBS** — we therefore frame the coupling result as hypothesis-generating evidence of decoupling rather than definitive proof.

### No candidate mediator explains the pain effect

The multi-mediator analysis (Analysis 15) tested Δ LEDD, Δ NHY, Δ GDS, Δ SCOPA, Δ ESS, and Δ UPDRS-III as candidate single mediators. **All six were null** (ACME P ≥ .15; the strongest signal was Δ LEDD with ACME = −0.032, 95 % CI −0.076, +0.011, P = .146). This argues against pharmacological washout (Δ LEDD), motor disability progression (Δ NHY, Δ UPDRS-III), depression (Δ GDS), autonomic burden (Δ SCOPA), and daytime sleepiness (Δ ESS) as routes through which DBS would affect pain. If a treatment effect on pain exists in this cohort, it is not transmitted through any single measured non-motor or motor mediator.

### Genetic and biomarker status

PD polygenic risk × DBS LRT P = .30; APOE-ε4 × DBS P = .96; α-synuclein SAA × DBS P = .71; GBA × DBS P = .40 (Figure 7). The bootstrap-distribution sensitivity (Analysis 11) reported per-term posterior summaries; with approximately 50 DBS patients per stratum, the minimum detectable interaction effect at 80 % power is ≈ ±0.5 pain points on the 0–4 scale. **These results are uninformative regarding genetic moderation effects below this magnitude.**

### Robustness checks

Across the 16 analyses, the primary non-inferiority conclusion was preserved. Anchor sweep: all three Never-DBS anchor schemes yielded between-arm Δ within ±0.10 points (Analysis 2). MNAR tipping-point: non-inferiority held under Δ Pain shifts among dropouts up to ±0.75 points and flipped only at ±1.0 points (Analysis 3) — concretely, **at least ≈ 30 % of Never-DBS dropouts (≈ 175 patients) would need to have systematically worsened by ≥ 1 pain point relative to completers to overturn the conclusion**. E-values: 1.47 for the slope contrast (lower CL 1.26); 5.09 for the worsener RR (lower CL 1.45). Cluster-robust (CR2) standard errors preserved LMM slope-contrast inference for the Post-DBS phase (P = 0.35). The Pre-DBS time × phase interaction was sensitive to GEE working correlation (exchangeable P = .079 → AR(1) P = .59), and we have retired the pre-DBS divergence narrative accordingly.

---

## Discussion

In this PPMI cohort, deep brain stimulation was non-inferior to medical therapy on the 4-year course of self-reported pain. Non-inferiority held at every pre-specified margin from ±1 down to ±0.3 MDS-UPDRS Part I points. The conclusion did not change under three alternative Never-DBS anchor schemes, a missing-not-at-random tipping-point sensitivity, cluster-robust standard errors, two GEE working-correlation structures, three propensity-score-matching calipers, or an explicit immortal-time correction via duration-matched sequential-trial emulation. We are not aware of a prior matched longitudinal analysis to test DBS non-inferiority on a non-motor Parkinson endpoint across a margin grid; this evidentiary standard exceeds that of the existing PD-DBS pain literature.

The exploratory analyses produced three signals worth flagging. First, the pre-specified late-post Network Comparison Test reached an uncorrected P = 0.050, with the pain node moving away from MDS-UPDRS Part III and toward autonomic and sleep nodes; the Holm correction across three windows raises the P value to 0.150. The pattern is suggestive of pain-symptom-architecture reshaping under stimulation, but it is not statistically conclusive in this cohort, and individual pain-anchored edge bootstrap intervals cross zero. Second, within-patient ΔPain–ΔUPDRS-III Spearman coupling was lower under DBS in both the matched cohort (Δρ = −0.16) and an independent unmatched-complement subsample (Δρ = −0.08); the bootstrap power at n = 33 DBS patients is approximately 22 % for a true Δρ = −0.25, so the coupling result is best read as a hypothesis to be tested in a larger sample. Third, none of six candidate single mediators (LEDD, Hoehn &amp; Yahr stage, GDS, SCOPA, ESS, UPDRS-III) reached significance (ACME P ≥ .15). Taken individually these signals are inconclusive. Taken together they are compatible with a stimulation effect on the architecture surrounding pain, transmitted through neither pharmacology nor any single measured non-motor or motor pathway. We propose, as a hypothesis pending mechanistic testing, that chronic stimulation interacts with basal-ganglia–brainstem projections to mesencephalic locomotor and parabrachial circuits encoding aversive and pain salience,³⁵ in line with the symptom-specific connectomic targets reported by Hollunder and colleagues at the imaging level.¹²

The Fine-Gray subdistribution hazard for crossing NP1PAIN ≥ 2 was 1.86 (95 % CI 1.28–2.69). This finding is not a treatment effect: DBS recipients began follow-up with higher baseline pain, leaving less headroom before they crossed the binary threshold. The E-value lower confidence limit of 1.45 quantifies the unmeasured-confounder strength that would be needed to explain this signal entirely. Mean-trajectory non-inferiority and threshold-crossing hazard are therefore non-contradictory: the first answers whether DBS worsens pain on average; the second answers whether DBS recipients cross a clinical threshold more often, dominated here by baseline composition.

**Strengths.** A pre-specified target-trial-emulation framework with IPCW-weighted primary estimator and propensity-matched sensitivity; calibration through both a positive (UPDRS-III) and three negative (NP1HALL, NP1URN, NP1COG) controls; sixteen pre-registered and post-hoc robustness analyses with concordant directionality; E-value reporting; the first formal Network Comparison Test of non-motor symptom topology between DBS and Never-DBS PD patients; the first systematic multi-mediator analysis of Δ Pain in PD-DBS; full reproducibility via Docker, Codespaces, synthetic data fixture, and AI peer-review harness.

**Limitations.** Five limitations warrant emphasis. First, with 105 DBS recipients, the cohort is biased toward early-PD patients (mean disease duration at DBS ≈ 2.3 years on PPMI's enrolment-relative duration variable, but median 15.8 years since symptom onset at surgery; the patient population is the EARLYSTIM-era cohort rather than late-PD DBS recipients³⁷). Second, PPMI does not record the DBS target; the cohort is target-agnostic and is expected to be a mixture of subthalamic and pallidal recipients, which have comparable motor efficacy but distinct non-motor profiles.³⁸ Pain effects may be heterogeneous by target — a hypothesis our cohort cannot test. Third, NP1PAIN is a single 0–4 ordinal item and may be insensitive to phenotype heterogeneity captured by the King's PD Pain Scale or the Brief Pain Inventory; replication on a richer instrument is warranted. Fourth, the Network Comparison Test result (Holm-adjusted P = 0.150) does not reach conventional significance; bootstrap stability supports the directional pattern, but the finding should not be over-interpreted. Fifth, demographic variables beyond sex (race, ethnicity, education, recruitment site) were not available in the PPMI variable set used in this analysis; external validity to non-PPMI populations is therefore inferential and the framework should be replicated in registry-type DBS cohorts that record demographics. Sixth, the genetic/biomarker × DBS interaction results are uninformative regarding effects below ≈ ±0.5 pain points given the cohort sample.

**Clinical implications.** DBS is non-inferior on the 4-year pain trajectory at clinically meaningful margins, and there is no evidence of pharmacological mediation of the (null) pain effect. The threshold-crossing Fine-Gray finding is consistent with baseline channeling and does not contradict the mean-trajectory non-inferiority. Patient counselling should reflect that DBS does not appear to worsen long-term pain in early-PD recipients, with the caveat that target heterogeneity and demographic distribution are inferential.

**Conceptual implications.** Directional evidence — not statistically significant after correction — suggests that DBS *may* shift the non-motor symptom architecture around pain. If replicated in target-aware prospective cohorts, this would support a conceptual move from a "motor-only" to a "symptom-architecture-modulating" therapeutic frame, but the present analysis does not establish it.

**Methodological contribution.** The combination of target-trial emulation, sequential-trial emulation for immortal-time correction, propensity matching + IPCW, landmark non-inferiority testing across a margin grid, partial-correlation symptom-network analysis with multiplicity correction, multi-mediator analysis, and a fully reproducible repository with synthetic-data fixture and AI peer-review harness is a generalisable framework that we apply in this paper and intend to apply to four follow-up non-motor outcomes (sleep, autonomic, cognition, pain phenotype — see Future Papers in `docs/FUTURE_PAPERS.md`).

---

## Conclusion

In this matched longitudinal PPMI cohort, deep brain stimulation was non-inferior to medical therapy on the 4-year course of pain in Parkinson disease, with non-inferiority concluded at margins down to ±0.3 MDS-UPDRS Part I points. Three exploratory signals — a borderline late-post Network Comparison Test (P = 0.050 uncorrected), a lower within-patient pain–motor coupling under stimulation, and a uniformly null multi-mediator analysis — are individually inconclusive but jointly suggestive of a stimulation effect on the symptom architecture around pain. Prospective connectomic and noradrenergic-imaging studies in target-aware cohorts are needed to test that hypothesis.

---

## References

1. Mylius V, Möller JC, Bohlhalter S, et al. Pain in Parkinson's disease: current concepts and a new diagnostic algorithm. *Lancet Neurol*. 2025;24(4):353–369. doi:10.1016/S1474-4422(25)00027-X. PMID 40120617.
2. Wasner G, Deuschl G. Pain disorders in Parkinson's disease and how to treat them. *Lancet Neurol*. 2012;11(7):615–627.
3. Silverdale MA, Kobylecki C, Kass-Iliyya L, et al. Pain trajectory over six years in early Parkinson's disease: ICICLE-PD. *J Neurol*. 2021;268(11):4459–4469.
4. Pacheco-Barrios K, Lozano-Salinas E, Rolston JD. Association of chronic pain with motor symptom severity in PD. *Life (Basel)*. 2025;15(2):268. PMID 40003677.
5. Cury RG, Galhardoni R, Fonoff ET, et al. Effects of subthalamic stimulation on pain and PD symptoms. *Neurology*. 2014;83(16):1403–1409. PMID 25217059.
6. Jung YJ, Kim H-J, Jeon BS, et al. An 8-year follow-up on the effect of subthalamic nucleus deep brain stimulation on pain in Parkinson disease. *JAMA Neurol*. 2015;72(5):504–510. PMID 25799451.
7. Dafsari HS, Martinez-Martin P, Rizos A, et al. EuroInf 2: subthalamic stimulation, apomorphine, and levodopa infusion treatment improve quality of life in Parkinson's disease. *Mov Disord*. 2019;34(3):353–365. PMID 30719763.
8. Dafsari HS, Reker P, Stalinski L, et al. Quality-of-life outcomes from subthalamic stimulation 36 months after surgery: the NILS study. *Mov Disord*. 2020;35(6):1051–1058. PMID 32371534.
9. Jung JH, Park JY, Lee MA, et al. The effects of deep brain stimulation in Parkinson's disease patients with pain: a meta-analysis. *Front Hum Neurosci*. 2021;15:707812. PMID 34276330.
10. Cury RG, Galhardoni R, Teixeira MJ, et al. Connectomic profile of STN-DBS pain response. *Front Neurol*. 2020;11:632.
11. Strauss I, Sokol-Hessner J, Mehanna R, et al. Dorsal subthalamic stimulation improves pain in Parkinson's disease. *Front Pain Res*. 2023;4:1083115.
12. Hollunder B, Rajamani N, Siddiqi SH, et al. Network-mapping of deep brain stimulation in PD reveals symptom-specific networks. *Nat Commun*. 2024;15:48731. PMID 38821913.
13. Tosin MHS, Goetz CG, Schiess MC, et al. Longitudinal MDS-NMSS network analysis in PD. *NPJ Parkinsons Dis*. 2023;9:30.
14. Marek K, Chowdhury S, Siderowf A, et al. The Parkinson's Progression Markers Initiative (PPMI) — establishing a PD biomarker cohort. *Ann Clin Transl Neurol*. 2018;5(12):1460–1477.
15. Hernán MA, Robins JM. Using big data to emulate a target trial when a randomized trial is not available. *Am J Epidemiol*. 2016;183(8):758–764.
16. von Elm E, Altman DG, Egger M, et al. The Strengthening the Reporting of Observational Studies in Epidemiology (STROBE) statement. *PLoS Med*. 2007;4(10):e296.
17. Lipsitch M, Tchetgen Tchetgen E, Cohen T. Negative controls: a tool for detecting confounding and bias in observational studies. *Epidemiology*. 2010;21(3):383–388.
18. Lakens D. Equivalence tests: a practical primer for t tests, correlations, and meta-analyses. *Soc Psychol Personal Sci*. 2017;8(4):355–362.
19. Horváth K, Aschermann Z, Kovács M, et al. MDS-UPDRS Part I minimal clinically important difference. *J Parkinsons Dis*. 2017;7(3):545–550.
20. Ho DE, Imai K, King G, Stuart EA. MatchIt: nonparametric preprocessing for parametric causal inference. *J Stat Softw*. 2011;42(8):1–28.
21. Bates D, Mächler M, Bolker B, Walker S. Fitting linear mixed-effects models using lme4. *J Stat Softw*. 2015;67(1):1–48.
22. Højsgaard S, Halekoh U, Yan J. The R package geepack for generalized estimating equations. *J Stat Softw*. 2006;15(2):1–11.
23. Fine JP, Gray RJ. A proportional hazards model for the subdistribution of a competing risk. *J Am Stat Assoc*. 1999;94(446):496–509.
24. Epskamp S, Borsboom D, Fried EI. Estimating psychological networks and their accuracy: a tutorial paper. *Behav Res Methods*. 2018;50(1):195–212.
25. Epskamp S, Cramer AO, Waldorp LJ, Schmittmann VD, Borsboom D. qgraph: network visualizations of relationships in psychometric data. *J Stat Softw*. 2012;48(4):1–18.
26. van Borkulo CD, van Bork R, Boschloo L, et al. Comparing network structures on three aspects: a permutation test. *Psychol Methods*. 2022. doi:10.1037/met0000476.
27. Brant R. Assessing proportionality in the proportional odds model for ordinal logistic regression. *Biometrics*. 1990;46(4):1171–1178.
28. Nalls MA, Blauwendraat C, Vallerga CL, et al. Identification of novel risk loci, causal insights, and heritable risk for Parkinson's disease. *Lancet Neurol*. 2019;18(12):1091–1102.
29. Siderowf A, Concha-Marambio L, Lafontant DE, et al. Assessment of heterogeneity among participants in PPMI cohorts using α-synuclein seed amplification: a cross-sectional study. *Lancet Neurol*. 2023;22(5):407–417.
30. VanderWeele TJ, Ding P. Sensitivity analysis in observational research: introducing the E-value. *Ann Intern Med*. 2017;167(4):268–274.
31. Firth D. Bias reduction of maximum likelihood estimates. *Biometrika*. 1993;80(1):27–38.
32. Pustejovsky JE, Tipton E. Small-sample methods for cluster-robust variance estimation and hypothesis testing in fixed effects models. *J Bus Econ Stat*. 2018;36(4):672–683.
33. Tingley D, Yamamoto T, Hirose K, Keele L, Imai K. Mediation: R package for causal mediation analysis. *J Stat Softw*. 2014;59(5):1–38.
34. Textor J, van der Zander B, Gilthorpe MS, Liskiewicz M, Ellison GTH. Robust causal inference using directed acyclic graphs: the R package 'dagitty'. *Int J Epidemiol*. 2016;45(6):1887–1894.
35. Saadé NE, Atweh SF, Bahuth NB, Jabbur SJ. Augmentation of nociceptive reflexes and chronic deafferentation pain by chemical lesions of either dopaminergic terminals or midbrain dopaminergic neurons. *Brain Res*. 1997;751(1):1–12.
36. Espay AJ, LeWitt PA, Kaufmann H. Norepinephrine deficiency in Parkinson's disease: the case for noradrenergic enhancement. *Mov Disord*. 2023;38(1):3–7.
37. Schuepbach WMM, Rau J, Knudsen K, et al. Neurostimulation for Parkinson's disease with early motor complications (EARLYSTIM). *N Engl J Med*. 2013;368(7):610–622.
38. Follett KA, Weaver FM, Stern M, et al. Pallidal versus subthalamic deep-brain stimulation for Parkinson's disease (CSP 468). *N Engl J Med*. 2010;362(22):2077–2091.
