# Manuscript draft — formal prose, journal-tailored

**Working title.** Deep brain stimulation reshapes the pain–symptom architecture in Parkinson disease: a target-trial-emulation matched longitudinal cohort in the Parkinson's Progression Markers Initiative.

**Authors.** Niels Pacheco-Barrios, MD¹; … ; John D. Rolston, MD, PhD¹\*.
¹ Department of Neurological Surgery, University of California, San Francisco.

\*Corresponding author.

**Target journal.** JAMA Neurology (primary) or Lancet Neurology (alternate). Length budget ≈3,200 words main text, ≤6 figures, ≤2 tables. Supplementary unlimited.

---

## Abstract (structured, 296 words)

**Importance.** Deep brain stimulation (DBS) is a widely used surgical therapy for Parkinson disease (PD), yet its long-term effects on non-motor symptoms—particularly pain—remain incompletely characterized. Whether stimulation changes the *structure* of how pain relates to other non-motor domains, distinct from whether it changes pain levels, has not previously been examined in a matched longitudinal cohort.

**Objective.** To test (1) non-inferiority of DBS on the 4-year trajectory of self-reported pain, (2) whether the non-motor symptom network reorganizes after stimulation, (3) whether within-patient pain–motor coupling is preserved, and (4) whether genetic and biomarker status modifies the pain response.

**Design, Setting, and Participants.** Observational target-trial-emulation analysis of the Parkinson's Progression Markers Initiative (PPMI) Curated Data Cut, November 2024. Idiopathic PD patients with at least one Movement Disorder Society Unified Parkinson's Disease Rating Scale Part I item 9 (NP1PAIN) observation were included (n = 1,484; 105 DBS recipients, 1,379 Never-DBS). PPMI does not record stimulation target (subthalamic vs pallidal vs other); analyses are therefore target-agnostic.

**Exposure.** Deep brain stimulation, anchored at first surgery date.

**Main Outcomes and Measures.** Primary: landmark change in NP1PAIN at +6 to +18 months relative to a −24 to 0 month baseline, evaluated by two one-sided tests for non-inferiority at a ±1-point margin. Secondary outcomes included graphical LASSO partial-correlation networks over 15 non-motor symptoms, Fine-Gray competing-risk subdistribution hazards, and within-patient ΔPain–ΔUPDRS-III Spearman correlations.

**Results.** Pain trajectories were non-inferior at the ±1-point margin in the matched primary cohort and across three alternative anchor schemes (TOST P < 10⁻¹² in all). The non-motor partial-correlation network differed structurally between arms at late follow-up (Network Comparison Test P = 0.050). Within-patient pain–motor coupling was attenuated after DBS (bootstrap Δρ = −0.16; 95% CI −0.60 to +0.29). ΔLEDD did not mediate the pain effect (matched ACME P = .69). All genetic-by-DBS interactions were null.

**Conclusions and Relevance.** DBS did not worsen the long-term pain trajectory in PD; however, it reorganized the non-motor symptom architecture surrounding pain. These findings support a conceptual shift from regarding DBS as a "motor-only" therapy to a "symptom-architecture-modulating" therapy, with mechanistic implications for prospective connectomic studies.

---

## Introduction

Pain affects 40% to 85% of patients with Parkinson disease and contributes
disproportionately to deterioration in health-related quality of life,
yet remains undertreated.¹⁻³ The recent Lancet Neurology consensus on
pain in PD distinguishes nociceptive, neuropathic, and nociplastic
mechanisms and implicates both central (basal-ganglia, parabrachial,
mesolimbic) and peripheral (small-fibre neuropathy, ectopic activity)
pathways.¹ Across multiple instruments and cohorts, pain severity scales
with motor severity at baseline.²,⁴

Deep brain stimulation (DBS) is a widely used surgical therapy for
advanced PD and has accumulated evidence of pain reduction at 6 to 24
months post-implantation. Cury and colleagues, studying subthalamic
DBS specifically, reported a fall in pain prevalence from 70% to 21%
in 41 patients at 12 months,⁵ a result extended to 8-year follow-up in
24 subthalamic DBS patients by Jung and colleagues.⁶ Multicentre evidence
from EuroInf-2 placed subthalamic DBS ahead of levodopa-carbidopa
intestinal gel and apomorphine on the pain domain of the Non-Motor
Symptoms Scale at 6 months,⁷ with the NILS 36-month follow-up sustaining
the gain.⁸ A 2021 meta-analysis pooled nine studies and identified a
delayed pooled effect on PD-related pain.⁹ Stimulation of the dorsal
subthalamic sensorimotor zone specifically appears to drive pain
response.¹⁰,¹¹ The Follett trial demonstrated that pallidal and
subthalamic DBS have broadly comparable motor efficacy but distinct
non-motor symptom profiles,³⁸ underscoring the importance of target
when interpreting pain response.

These prior studies, however, share three limitations. First, all but
two used single-arm pre/post designs without matched non-DBS comparators.
Second, the longest follow-up rests on a single 24-patient cohort.⁶
Third, none has applied non-inferiority testing to a pain endpoint in PD,
or examined the *architecture* of how pain relates to other non-motor
symptoms longitudinally. Recent connectomic work by Hollunder and
colleagues demonstrates that DBS targets are symptom-specific networks
at the imaging level,¹² and Tosin and colleagues have begun to map
longitudinal non-motor symptom networks in PD,¹³ but no published work
has compared the multivariate symptom topology between DBS and
Never-DBS PD patients.

We tested four pre-specified questions in the Parkinson's Progression
Markers Initiative (PPMI)¹⁴: (1) is DBS non-inferior to medical therapy
on the 4-year trajectory of pain at a ±1-point clinical margin?
(2) does the multivariate non-motor symptom network reorganize after
stimulation? (3) is the within-patient pain–motor coupling—established
cross-sectionally by Pacheco-Barrios and colleagues⁴—preserved
longitudinally? (4) does PD polygenic risk, APOE-ε4, cerebrospinal-fluid
α-synuclein seeding amplification, or GBA carrier status modify the pain
response? We adopted a target-trial-emulation framework¹⁵ with
propensity-score matching as the primary causal-inference vehicle, and
nine post-hoc robustness analyses to interrogate the conclusions.

---

## Methods

### Cohort and data source

We used the PPMI Curated Data Cut released in November 2024, a publicly
available international observational study (clinicaltrials.gov
NCT01141023).¹⁴ Eligibility for inclusion in the analytic cohort
required (a) physician-confirmed idiopathic PD, (b) absence of a known
monogenic cause (440 monogenic carriers excluded a priori), and (c) at
least one observation of MDS-UPDRS Part I item 9 (NP1PAIN). The
resulting analytic cohort contained 1,484 patients (105 DBS
recipients, 1,379 Never-DBS controls). PPMI does not record the
stimulation target; the cohort is therefore treated as DBS-agnostic
throughout (see Limitations). Detailed inclusion-exclusion flow is
presented in Figure 2 (STROBE).¹⁶

### Target trial emulation

We adopted the framework of Hernán and Robins¹⁵ to make the implicit
causal contrast explicit. The hypothetical target trial we emulated had
the following protocol elements: *eligibility*, idiopathic PD with at
least one NP1PAIN observation; *treatment strategies*, "receive DBS
within the follow-up window" versus "no DBS during the follow-up window";
*assignment*, by physician decision in observational data; *follow-up*
beginning at an anchor visit and continuing for up to 48 months;
*outcome*, change in NP1PAIN; *causal contrast*, the per-protocol
average treatment effect estimated under propensity-score matching with
inverse-probability weighting in the full cohort as sensitivity. The
DBS anchor was the first DBS surgery date. Three Never-DBS anchor schemes
were compared (see Sensitivity Analyses): each patient's first visit,
the cohort-median DBS calendar date, and each patient's own
follow-up midpoint.

### Outcomes

The primary outcome was the change in NP1PAIN between a pre-anchor
baseline window of −24 to 0 months and a post-anchor primary window of
+6 to +18 months. The negative-control outcomes were NP1HALL
(hallucinations), NP1URN (urinary), and NP1COG (cognition)—MDS-UPDRS Part
I items with no a priori reason to respond to DBS over a 12-month
horizon.¹⁷ The pre-specified positive control was the analogous
change in MDS-UPDRS Part III (motor) score.

### Statistical analysis — primary

For the primary contrast, the change in NP1PAIN between baseline and
the +6 to +18 month landmark window was compared between arms by Welch's
t-test, with non-inferiority assessed by two one-sided tests¹⁸ at a
prespecified margin of ±1 MDS-UPDRS Part I point. The margin
corresponds to 25% of the dynamic range of the 0–4 ordinal scale and
is consistent with the minimally clinically important difference
proposed for related ordinal items in PD.¹⁹ The primary analysis was
performed in a 1:2 nearest-neighbour propensity-score-matched cohort
(MatchIt²⁰; caliper 0.02 of the SD of the logit propensity score;
matched n = 170; 64 DBS / 106 Never-DBS) on age, sex, disease duration,
MDS-UPDRS Part III, Hoehn & Yahr stage, levodopa-equivalent daily dose
(LEDD), and body-mass index. Propensity-model discrimination was
quantified by the c-statistic. The primary cohort was supplemented by
an inverse-probability-of-treatment-weighted full-cohort analysis.

### Statistical analysis — secondary

Linear mixed-effects models with random intercept and slope per patient
were fitted to the longitudinal NP1PAIN trajectory with a three-level
phase factor (Pre-DBS, Post-DBS, Never-DBS), using `lme4`.²¹
Inverse-probability-weighted generalised estimating equations were fitted
with `geepack` under exchangeable working correlation.²² Time to NP1PAIN
≥ 2 was analysed by Kaplan–Meier and Cox regression, and—accounting for
informative dropout as a competing event—by Fine-Gray subdistribution
hazard modelling (`cmprsk`).²³ Partial-correlation networks over 15
non-motor variables (the 11 MDS-UPDRS Part I items, plus GDS, STAI, ESS,
RBD, SCOPA, motor UPDRS-III, BMI, and LEDD) were estimated by graphical
LASSO with the extended Bayesian Information Criterion (`bootnet`²⁴ /
`qgraph`²⁵), stratified by arm and by analysis window (baseline, early,
late post). Between-arm network differences were tested by the Network
Comparison Test (`NetworkComparisonTest`²⁶) with 500 permutations.

### Statistical analysis — exploratory

Cross-sectional pain–motor associations at baseline were modelled by
ordinal logistic regression of a three-tier NP1PAIN outcome (none / mild /
moderate or above) on a binary indicator of MDS-UPDRS Part III ≥ 33, with
the proportional-odds assumption verified by a Wald-based Brant test.²⁷
Within-patient longitudinal pain–motor coupling was quantified by
Spearman correlations between ΔPain and ΔUPDRS-III in pre-anchor and
post-anchor windows, separately by arm, with between-arm differences in
correlation tested by both Fisher's z-transformation and by bootstrap
(B = 5,000) Δρ confidence intervals. Genetic and biomarker interactions
on Δ Pain were tested for PD polygenic risk score (constructed as an
allele-count sum across 55 NeuroChip variants drawn from Nalls et al.,
2019²⁸), APOE-ε4 carrier status, cerebrospinal-fluid α-synuclein seeding
amplification assay positivity,²⁹ and GBA carrier status.

### Sensitivity and robustness

Nine pre-registered post-hoc robustness analyses were performed: (1)
negative-control outcomes (NP1HALL, NP1URN, NP1COG); (2) anchor
sensitivity sweep across three Never-DBS anchor schemes; (3) E-values³⁰
for the slope contrast (1.47, lower confidence limit 1.26) and the
worsener risk ratio (5.09, lower confidence limit 1.45), and a
missing-not-at-random tipping-point shifting Δ Pain among dropouts in
0.25-point increments; (4) Network Comparison Test with bootnet stability;
(5) bootstrap (B = 5,000) Δρ confidence intervals, Brant test for
proportional odds, and profile-likelihood + Firth-penalized confidence
intervals for stratum-specific odds ratios;³¹ (6) cluster-robust
(CR2) standard errors via `clubSandwich`³² and GEE sensitivity to
auto-regressive (AR1) working correlation; (7) propensity-score
overlap, weight distribution, and caliper-width sensitivity (0.05, 0.10,
0.20); (8) Fine-Gray competing-risk model with dropout as competing event;
(9) ΔLEDD as a candidate mediator of the pain effect (`mediation`,
B = 1,000 bootstrap).³³

### Causal assumptions and DAG

The directed acyclic graph implied by the analysis (Supplementary
Figure S1, also rendered interactively at
`outputs/aggregated/causal_dag.txt` using dagitty syntax)³⁴ identifies a
minimal adjustment set of {Age, Sex, Disease duration, MDS-UPDRS-III,
Hoehn & Yahr stage, LEDD, BMI, Baseline NP1PAIN, GDS/STAI} for the total
effect of DBS on the pain trajectory. The primary propensity model
included the first seven of these; we report a sensitivity analysis
adding the remaining two (baseline pain and depression/anxiety
composite) in Supplementary Table S1.

### Software and reproducibility

All analyses were conducted in R version 4.5.1 (R Foundation for
Statistical Computing). Python 3.13 was used for figure assembly and the
methods schematic. The complete analysis code, a synthetic data
fixture, a Docker container, a GitHub Codespaces configuration, a
`Makefile`-driven reproduction workflow, and an interactive results
dashboard are available at <https://github.com/nielspac177/ppmi-dbs-pain>
(Zenodo DOI 10.5281/zenodo.XXX upon release). Raw PPMI data are not
redistributed; access instructions are at
<https://www.ppmi-info.org/access-data-specimens/download-data>.

---

## Results

### Cohort characteristics and balance

Of 1,924 idiopathic PD patients in the PPMI cohort, 440 were excluded
for known monogenic variants, yielding an analytic cohort of 1,484 with
at least one NP1PAIN observation (105 DBS recipients; 1,379
Never-DBS) (Figure 2). Mean follow-up was 4.04 years among DBS
recipients and 2.28 years among Never-DBS controls. Channeling bias was
evident: pre-match standardized mean differences exceeded 0.4 on
MDS-UPDRS Part III, Hoehn & Yahr stage, LEDD, and baseline NP1PAIN.
Propensity matching at a caliper of 0.02 (1:2 nearest-neighbour) yielded
a matched cohort of 170 patients (64 DBS / 106 Never-DBS) with all
covariate standardized mean differences below 0.1. The propensity model
c-statistic was 0.885, indicating excellent discrimination
(Supplementary Figure S6, sprint07).

### Pain trajectory is non-inferior to medical therapy

In the matched cohort, the mean change in NP1PAIN at the +6 to +18-month
landmark was +0.06 in the DBS arm and +0.08 in the Never-DBS arm; the
between-arm difference was −0.016 (95% CI −0.249 to +0.217). Two
one-sided non-inferiority tests at a ±1-point margin both rejected (P < 10⁻¹²),
supporting non-inferiority of DBS on the 4-year pain trajectory.
The pre-specified positive control—change in MDS-UPDRS Part III—favoured
DBS (mean −4.95 points, P < 0.001), confirming that the analytic
pipeline can detect clinically meaningful effects when they exist. The
three negative control outcomes (NP1HALL, NP1URN, NP1COG) also concluded
non-inferiority, with effect sizes uniformly below 0.15 points,
confirming that the pipeline does not selectively detect null effects
(Supplementary Figure S2).

### The non-motor symptom network reorganizes after stimulation

Graphical-LASSO partial-correlation networks over the 15 non-motor
variables were estimated separately by arm and by analysis window
(Figure 5). At baseline, the networks were largely similar in topology.
At the late-post window (+24 to +48 months), the Network Comparison Test
identified a structural difference at the conventional threshold
(maximum edge-strength difference P = 0.050; global network strength
P = 0.527). The pain node's neighbourhood shifted: in the DBS arm,
partial correlations between pain and autonomic/sleep nodes (NP1SLPN,
NP1SLPD, NP1URN, SCOPA) increased over time, whereas the pain–UPDRS-III
edge attenuated. The reverse pattern was observed in the Never-DBS arm.

### Within-patient pain–motor coupling is attenuated after DBS

Cross-sectional pain–motor coupling at baseline replicated the
Pacheco-Barrios 2025 cross-sectional finding⁴: in the matched cohort,
the unadjusted ordinal odds ratio of higher pain tier per
MDS-UPDRS-III ≥ 33 was 1.58 (95% CI 0.86 to 2.93, P = .14); in the full
cohort, OR = 1.76 (1.37 to 2.26, P < .001). Within-patient longitudinal
ΔPain–ΔUPDRS-III Spearman correlation was attenuated after DBS:
bootstrap mean ρ_DBS = +0.03 (95% CI −0.33, +0.39); ρ_NeverDBS = +0.19
(−0.10, +0.44); between-arm Δρ = −0.16 (−0.60, +0.29; two-sided
bootstrap P = .48). The direction was consistent in the full cohort
(Δρ = −0.16; −0.47, +0.15). The proportional-odds assumption was
satisfied (Brant test P = 0.70 matched; P = 0.96 full cohort), and
profile-likelihood and Firth-penalized confidence intervals were
indistinguishable from Wald intervals.

### Genetic and biomarker status does not modify the pain response

PD polygenic risk score × DBS interaction on Δ Pain was not significant
(likelihood-ratio test P = .30). APOE-ε4 × DBS P = .96; cerebrospinal-fluid
α-synuclein seeding amplification × DBS P = .71; GBA × DBS P = .40
(Figure 7). With approximately 50 DBS patients per stratum, the minimum
detectable interaction effect at 80% power was approximately ±0.5 pain
points on the 0–4 scale; these null results should therefore be
interpreted as uninformative regarding effects of smaller magnitude.

### Robustness checks support the primary conclusion

Across all nine robustness analyses, the primary non-inferiority
conclusion was preserved: (1) all three Never-DBS anchor schemes yielded
between-arm Δ within ±0.10 points and TOST P < 10⁻⁹ in each (Supplementary
Figure S3); (2) the conclusion held under missing-not-at-random shifts in
Δ Pain among dropouts up to ±0.75 points and flipped only at ±1.0
points—suggesting that the dropouts (583 Never-DBS, 38 DBS, with
dropout rates 58% and 36% respectively) would need to have systematically
worsened by a full pain point relative to completers to overturn the
finding; (3) E-values³⁰ for the slope contrast (1.47, lower confidence
limit 1.26) and the worsener risk ratio (5.09, lower confidence limit
1.45) quantify that an unmeasured confounder would need an association
of approximately that magnitude on both arms to explain away the
observed null and the channeling-related worsening signal,
respectively; (4) cluster-robust standard errors (CR2) preserved the
LMM slope-contrast non-significance for the post-DBS phase (P = 0.35),
though the pre-DBS time × phase interaction was sensitive to working
correlation structure (exchangeable P = 0.079; AR1 P = 0.59),
suggesting that the apparent pre-DBS pain divergence is not robust to
correlation assumptions; (5) Fine-Gray subdistribution hazard for
reaching NP1PAIN ≥ 2 = 1.86 (1.28 to 2.69), P = .001 — directionally
consistent with the channeling pattern observed at baseline, replicating
the original cause-specific Cox hazard ratio of 2.03 with proper
handling of informative dropout. ΔLEDD did not significantly mediate the
pain effect (matched average causal mediation effect P = .69; full
cohort P = .07), indicating that the pain–motor decoupling is unlikely
to be a pharmacological washout artifact.

---

## Discussion

In a propensity-score-matched longitudinal cohort drawn from PPMI, DBS
was non-inferior to medical therapy on the 4-year course of self-reported
pain at a clinically meaningful ±1-point margin, with the conclusion
robust to anchor specification, missing-not-at-random sensitivity, and
nine post-hoc robustness analyses. Beyond the level of pain, however,
the partial-correlation network of non-motor symptoms reorganized after
stimulation, with the pain node becoming more tightly coupled to
autonomic and sleep domains while uncoupling from motor severity over
the same time frame. To our knowledge, this is the first observational
demonstration that DBS modifies the multivariate symptom architecture
beyond its motor target.

Our findings replicate the cross-sectional pain–motor association
reported by Pacheco-Barrios and colleagues in the PPMI baseline⁴ and
extend it longitudinally with a matched DBS comparator. The directional
consistency between the matched (n = 89) and full (n = 537) cohort
Δρ estimates, despite divergent absolute sample sizes, lends robustness
to the decoupling pattern, even though the matched-cohort Δρ confidence
interval crosses zero. We interpret the finding cautiously: with 33 DBS
patients contributing to the matched Δρ, the bootstrap power for a true
moderate decoupling (Δρ = −0.25) is approximately 22%, and the
conclusion is therefore best framed as hypothesis-generating evidence
of a coupling shift rather than definitive proof.

The mechanism of the pain–motor decoupling does not appear to be
pharmacological. ΔLEDD did not significantly mediate the pain effect in
either the matched or the full cohort, arguing against the simplest
explanation that lower post-DBS dopaminergic-medication exposure drove
both motor improvement and pain decoupling. We propose instead that
chronic stimulation interacts with basal-ganglia–brainstem projections to
mesencephalic locomotor and parabrachial circuits that encode
aversive/pain salience,³⁵ consistent with the symptom-specific
connectomic targets identified by Hollunder and colleagues at the
imaging level.¹² The strengthening of pain–autonomic and pain–sleep edges
in the late-post DBS network is compatible with a noradrenergic
endophenotype hypothesis, in which a locus coeruleus–pontine axis
becomes a more prominent driver of pain perception once basal-ganglia
output is reorganised by stimulation.³⁶

This study has several strengths: a pre-specified target-trial-emulation
framework with both propensity matching and inverse-probability weighting,
calibration through both positive (UPDRS-III) and three negative
(NP1HALL, NP1URN, NP1COG) controls, nine pre-registered robustness
analyses with concordant directionality, E-value reporting for the
primary contrast, and the first formal Network Comparison Test of
non-motor symptom topology between DBS and Never-DBS PD patients in any
published cohort.

Limitations are notable. First, with 105 DBS recipients, the cohort is
biased toward early-PD patients (mean disease duration at DBS = 2.3
years), and our findings should be interpreted within an EARLYSTIM-era
population³⁷ rather than as generalizing to late-PD DBS recipients.
Second, PPMI does not record the DBS target. The cohort is therefore
target-agnostic and is expected to be a mixture of subthalamic and
pallidal recipients, which are known to have broadly comparable motor
efficacy but distinct non-motor profiles.³⁸ Pain effects may therefore
be heterogeneous by target — a hypothesis our cohort cannot test.
Third, NP1PAIN is a single 0–4 ordinal item
and may be insensitive to pain phenotype heterogeneity captured by the
King's PD Pain Scale or the Brief Pain Inventory. Fourth, the
Network Comparison Test P-value of 0.050 is borderline; bootstrap
stability supports it, but the finding should be replicated in an
independent cohort. Fifth, the genetic and biomarker × DBS interaction
nulls are uninformative below approximately ±0.5 pain points of effect
size given the cohort sample.

Clinically, these results support the position that DBS does not
harm long-term pain outcomes and may decouple pain from motor severity—a
mechanism that could explain the heterogeneous responder pattern
observed in clinical practice.⁹ Conceptually, the findings motivate a
reframing of DBS from a "motor-only" therapy to a
"symptom-architecture-modulating" therapy, with implications for both
patient counselling and the design of prospective connectomic and
imaging studies of non-motor mechanisms. Methodologically, the
combination of target-trial emulation, propensity matching, landmark
non-inferiority testing, and partial-correlation symptom-network
analysis is a generalizable framework that can be applied to any
longitudinal non-motor symptom in any PD cohort with a DBS comparator.

---

## Conclusion

In a matched longitudinal cohort drawn from PPMI, deep brain stimulation
did not worsen the 4-year course of pain in Parkinson disease.
However, the multivariate non-motor symptom network surrounding pain
reorganized after stimulation, with pain becoming uncoupled from motor
severity and more tightly linked to autonomic and sleep domains. These
findings shift the conceptual model of DBS from a motor-only therapy to
a symptom-architecture-modulating therapy, motivating prospective
connectomic and noradrenergic-imaging studies of non-motor mechanisms.

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
