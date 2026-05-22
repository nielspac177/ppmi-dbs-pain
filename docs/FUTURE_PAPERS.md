# Future-paper hypothesis bank — DBS non-motor series

Hypotheses for the next three papers in Niels Pacheco-Barrios's DBS
non-motor series (PPMI cohort), each leveraging the same target-trial
emulation + sprint framework established in the pain paper.

---

## Paper 2 — SLEEP

### Testable hypotheses

H2.1 (Primary). **DBS is non-inferior to medical therapy on RBDSQ
trajectory over 48 months at a ±1-point margin.**
- Outcome: RBDSQ (REM-sleep behaviour disorder questionnaire), 0–13.
- Primary contrast: ΔRBDSQ at +6 to +18 mo vs −24 to 0 mo baseline.
- Falsified by: TOST at ±1 fails to reject in primary cohort.

H2.2 (Network). **The sleep sub-network of the 15-node GLASSO
reorganises after DBS** (NCT max-edge P < 0.05 at late-post).
- Outcome: Pain–NP1SLPN / NP1SLPD / ESS / RBD partial correlations.
- Builds on the late-post network reorganisation finding (Sprint 04).

H2.3 (LEDD mediation). **The sleep effect of DBS is partially mediated
by ΔLEDD** (matched ACME P < 0.05), in contrast to the pain effect
(matched ACME P = 0.69).
- A divergent mediation pattern between pain and sleep would suggest
  the sleep response is pharmacological while the pain response is
  stimulation-circuit-driven.

### Strongest single variable

**RBDSQ** (REM-sleep behaviour disorder questionnaire). PPMI ships this
as `RBDSQ` or item-level. Captures REM-sleep behaviour disorder, the
single most validated sleep marker in early PD. Ceiling/floor effects
are mild on a 0–13 scale.

### Primary outcome and analysis

Mirror the pain paper:
- Sprint 01-equivalent: NP1HALL, NP1COG as negative controls.
- Sprint 02-equivalent: 3 anchor sweep.
- Sprint 04-equivalent: NCT on 15-node network with sleep-focused
  pain neighbourhood.
- Sprint 09-equivalent: ΔLEDD mediation; expected positive (unlike pain).

### Major risk

**Circadian confounding.** Sleep measures are visit-time-dependent
(morning vs afternoon). RBDSQ is a recalled measure (less affected
than ESS / Epworth, which are state-dependent). Add a visit-hour
covariate to the IPCW propensity model.

---

## Paper 3 — AUTONOMIC

### Testable hypotheses

H3.1 (Primary). **DBS is non-inferior to medical therapy on SCOPA-AUT
trajectory over 48 months at a ±3-point margin** (3 = approximately
0.5 SD on a 0–69 scale).
- Outcome: SCOPA-AUT (SCales for Outcomes in Parkinson's Disease –
  Autonomic).

H3.2 (Pain–autonomic coupling). **The pain–autonomic edge strengthens
after DBS** (replicating the Sprint 04 finding) — specifically the
SCOPA → NP1PAIN partial correlation in the late-post window.
- The pain paper provided the descriptive pattern; the autonomic
  paper makes it a primary hypothesis.

H3.3 (Sex × DBS). **The autonomic effect of DBS is sex-modified**:
female DBS recipients have larger ΔSCOPA-AUT than males.
- Motivated by Jimena's thesis finding of DBS × SEX P = 0.017 on
  BMI; suggests a broader sex-modified autonomic response.

H3.4 (Orthostatic hypotension). **DBS is associated with a higher
rate of incident orthostatic hypotension** (PPMI orthostatic BP visits,
≥ 20 mmHg systolic drop).
- Time-to-event endpoint via Fine-Gray.

### Strongest single variable

**SCOPA-AUT total** (0–69, validated multi-domain autonomic scale).
Has more dynamic range than the 0–4 NP1URIN proxy used in the pain
paper. Item-level breakdown (cardiovascular, gastrointestinal,
urinary, thermoregulatory, sexual) supports network analysis at the
sub-system level.

### Primary outcome and analysis

- Sprint 01-equivalent: NP1HALL, NP1COG as negatives; UPDRS-III as
  positive.
- Sprint 04-equivalent: SCOPA item-level GLASSO; NCT on autonomic
  sub-network.
- Sprint 08-equivalent: Fine-Gray for time to incident orthostatic
  hypotension.
- New analysis: sex-stratified Δ-Δ.

### Major risk

**Differential dropout.** Autonomic symptoms are among the strongest
predictors of PPMI dropout (rough proxy for advancing disease). The
dropout asymmetry seen in the pain paper (61.9 % Never-DBS vs 34.9 %
DBS) will likely be larger here. IPCW is non-optional, not a
sensitivity. Promote to primary estimator from the start.

---

## Paper 4 — COGNITION

### Testable hypotheses

H4.1 (Primary). **DBS is non-inferior to medical therapy on MoCA
trajectory over 48 months at a ±2-point margin** (2 = the published
MCID for MoCA in PD).
- Outcome: MoCA total (0–30).

H4.2 (Dementia-free survival). **DBS does not reduce dementia-free
survival** (HR for incident MDS-PD-MCI or PDD ≤ 1.2; non-inferiority
margin).
- Outcome: time to MDS-PD-MCI diagnosis or MDS-PDD diagnosis.
- Fine-Gray with death as competing risk.

H4.3 (Domain heterogeneity). **DBS has differential effects across
cognitive domains**: executive function (Letter Number Sequencing)
declines faster post-DBS; memory (HVLT) is preserved.
- Multivariate trajectory analysis with domain as outcome.

H4.4 (APOE-ε4 × DBS interaction). **APOE-ε4 carriers have a larger
DBS-associated MoCA decline.**
- Bayesian re-analysis since frequentist is underpowered.

### Strongest single variable

**MoCA total** for the headline. Domain scores for H4.3. Use the LNS
(Letter Number Sequencing) test for executive function — the most
sensitive PPMI cognitive variable to DBS-related decline in prior
literature.

### Primary outcome and analysis

- Sprint 01-equivalent: NP1PAIN, NP1HALL as negatives (MoCA-irrelevant);
  UPDRS-III as positive.
- Sprint 04-equivalent: cognitive sub-network (MoCA, LNS, HVLT,
  semantic fluency, Symbol Digit) with arm stratification.
- Sprint 08-equivalent: dementia-free survival.
- Sprint 11-equivalent: Bayesian APOE × DBS posterior on ΔMoCA.

### Major risk

**Floor / ceiling effects.** MoCA is bounded 0–30 with strong ceiling
at 26–30. PPMI baseline mean ≈ 27 → very little room to improve and a
floor effect for decliners. Pre-specify an additional analysis using
the SCOPA-COG or the Cognitive Reserve Index as a more sensitive
continuous endpoint.

---

## Paper 5 (spinoff) — PAIN PHENOTYPE STRATIFICATION

### Testable hypotheses

H5.1 (Phenotype recovery). **PD pain phenotypes (musculoskeletal,
dystonic, central, neuropathic, autonomic-driven) are recoverable in
PPMI from the medical-conditions log keyword matching plus the
non-motor symptom GLASSO network.**

H5.2 (Differential DBS response). **DBS preferentially benefits
dystonic and musculoskeletal pain phenotypes** (Marques 2018, KPPS
literature) but is **neutral or detrimental for central pain.**

H5.3 (Phenotype-specific genetic moderation). **GBA carriers show a
disproportionately high autonomic-driven pain phenotype.**

### Strongest single variable

Composite **pain phenotype** label derived from:
- `Medical_Conditions_Log` MHTERM keyword matching (already
  implemented in `pain_helpers.R::PAIN_PHENOTYPE_PATTERNS`).
- NP1PAIN trajectory shape (latent-class trajectory modelling).
- Pain neighbourhood in the GLASSO network (a patient whose pain
  edge weights load on NP1FATG + NP1SLPN is "fatigue-coupled pain";
  one whose pain edges load on SCOPA is "autonomic-driven pain").

### Primary outcome and analysis

Latent-class growth-curve model on NP1PAIN trajectory, conditioned on
phenotype label. Cluster the resulting trajectories. DBS × phenotype
interaction on ΔPain.

### Major risk

**Phenotype noise from keyword matching.** Medical-conditions log
text is heterogeneous and often missing for non-pain conditions.
Validate the phenotype recovery against a clinician-rated subsample
(if available) or against the KPPS sub-scale items.

---

## Cross-cutting infrastructure

Every paper in this series should reuse:

- `R/helpers/pain_helpers.R` (or its `ppmiTTE` package equivalent) for
  cohort building, anchors, and Okabe-Ito palette.
- The 11-sprint robustness convention (`MANIFEST.md` + ADR-0003).
- The Tailwind + Plotly dashboard (`scripts/build_dashboard.py` is
  generic — point it at a new `outputs/tables/sprint*.csv` set).
- The Causal DAG template (`R/build_causal_dag.R` — copy + adjust
  outcome node).
- The Quarto book template (`docs/_quarto.yml`).
- The peer-review harness (`scripts/ai_peer_review.py` — see next
  section).

Each new paper takes ~2 weeks once the infrastructure is in place,
versus the ~3 months the pain paper required.
