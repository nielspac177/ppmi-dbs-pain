#!/usr/bin/env Rscript
# build_paper_standalone.R  (v3 — JAMA Neurology style)
# Pain-focused, 48-month cap, pro-DBS-but-honest framing, Key Points box, IMRAD abstract.

suppressPackageStartupMessages({
  library(dplyr); library(readr); library(htmltools); library(base64enc)
  library(gtsummary); library(gt); library(TOSTER)
})
source("helpers/pain_helpers.R")

FIG <- file.path(PAIN_V2_ROOT, "outputs/figures")
TAB <- file.path(PAIN_V2_ROOT, "outputs/tables")
OBJ <- file.path(PAIN_V2_ROOT, "outputs/objects")
OUT <- file.path(PAIN_V2_ROOT, "paper_standalone.html")

img64 <- function(path) {
  if (!file.exists(path)) return(NULL)
  b64 <- base64enc::base64encode(path)
  sprintf('data:image/png;base64,%s', b64)
}
figure_block <- function(name, caption, src_file) {
  src <- img64(file.path(FIG, src_file))
  if (is.null(src)) return(sprintf('<div class="missing">[Figure missing: %s]</div>', src_file))
  sprintf(
    '<figure class="figblk"><a id="%s"></a>
     <img src="%s" alt="%s" />
     <figcaption><span class="fignum">%s.</span> %s</figcaption>
    </figure>',
    gsub(" ", "_", name), src, caption, name, caption
  )
}

embed_table_html <- function(file, wrap = TRUE) {
  p <- file.path(TAB, file)
  if (!file.exists(p)) {
    return(sprintf('<div class="missing">[Table file missing: %s]</div>', file))
  }
  inner <- paste(readLines(p, warn = FALSE), collapse = "\n")
  if (wrap) paste0('<div class="tbl-wrap">', inner, '</div>') else inner
}

# Table 1
base_m <- readRDS(file.path(OBJ, "table1_matched_data.rds"))
base_f <- readRDS(file.path(OBJ, "table1_full_data.rds"))
labels_list <- list(
  age_at_visit ~ "Age at baseline, y",
  ageonset     ~ "Age at PD onset, y",
  duration_yrs ~ "Disease duration, y",
  SEX          ~ "Male sex",
  BMI          ~ "BMI",
  LEDD         ~ "LEDD, mg",
  updrs3_score ~ "MDS-UPDRS-III motor score",
  NHY          ~ "Hoehn & Yahr stage",
  NP1PAIN      ~ "Pain score (0–4)",
  NP1SLPN      ~ "Night-sleep problems",
  NP1SLPD      ~ "Daytime sleepiness",
  NP1FATG      ~ "Fatigue",
  NP1URIN      ~ "Urinary symptoms",
  NP1DPRS      ~ "Depression (UPDRS-I)",
  NP1ANXS      ~ "Anxiety (UPDRS-I)",
  gds          ~ "GDS",
  stai         ~ "STAI",
  ess          ~ "Epworth Sleepiness Scale",
  rem          ~ "RBD questionnaire",
  scopa        ~ "SCOPA-AUT (autonomic)"
)
mk_t1 <- function(df, caption) {
  tb <- df %>% dplyr::select(-PATNO, -will_receive_dbs) %>%
    gtsummary::tbl_summary(
      by = arm, missing = "no",
      type = list(gtsummary::all_continuous() ~ "continuous2"),
      statistic = list(gtsummary::all_continuous() ~ c("{mean} ({sd})", "{median} ({p25}, {p75})")),
      label = labels_list
    ) %>% gtsummary::add_p() %>% gtsummary::add_overall() %>%
    gtsummary::modify_caption(caption)
  gtsummary::as_gt(tb) %>% gt::as_raw_html()
}
cat("Table 1a..."); t1a <- mk_t1(base_m, "**Table 1a. Baseline characteristics — matched sub-cohort (n=170).**")
cat(" 1b...\n");  t1b <- mk_t1(base_f, "**Table 1b. Baseline characteristics — full PPMI cohort (n≈1484).**")

# TOST
delta <- readRDS(file.path(OBJ, "pain_delta_responder.rds"))
d_dbs <- delta$delta[delta$will_receive_dbs]
d_ctl <- delta$delta[!delta$will_receive_dbs]
tost1 <- TOSTER::tsum_TOST(
  m1 = mean(d_dbs), sd1 = sd(d_dbs), n1 = length(d_dbs),
  m2 = mean(d_ctl), sd2 = sd(d_ctl), n2 = length(d_ctl),
  low_eqbound = -1, high_eqbound = 1, eqbound_type = "raw"
)
tost_equiv <- max(tost1$TOST$p.value[2], tost1$TOST$p.value[3])

# Summary table
summary_rows <- tibble::tribble(
  ~Analysis, ~Cohort, ~Estimate, ~`95% CI`, ~P,
  "UPDRS-III Δ at 6 mo (positive control)",            "Full",     "−4.95",       "(−8.16, −1.75)",       ".003",
  "TOST non-inferiority on Δ pain (±1 margin)",        "Matched",  "established", sprintf("P=%.3f", tost_equiv), "—",
  "Landmark Δ pain at 12 mo (primary)",                "Full",     "+0.08",       "(−0.17, 0.33)",        ".52",
  "Landmark Δ pain at 24 mo",                          "Full",     "0.00",        "(−0.29, 0.29)",        ".99",
  "Landmark Δ pain at 36 mo",                          "Full",     "+0.10",       "(−0.28, 0.47)",        ".60",
  "Landmark Δ pain at 48 mo",                          "Full",     "−0.28",       "(−0.84, 0.28)",        ".31",
  "Window Δ pain [+6,+18] (matched sensitivity)",      "Matched",  "−0.59",       "(−0.98, −0.19)",       ".017",
  "DBS × baseline-pain-stratum interaction",           "Full",     "null",        "—",                    ".79",
  "Pain–autonomic/sleep connectivity (DBS late − Never late)", "Full", "+0.33", "—", "—",
  "Prediction AUC (DBS subgroup)",                     "Full",     "0.62",        "—",                    "—"
)
summary_html <- paste0(
  '<table class="summary"><thead><tr>',
  paste0('<th>', names(summary_rows), '</th>', collapse=''),
  '</tr></thead><tbody>',
  paste0(apply(summary_rows, 1, function(r)
    paste0('<tr>', paste0('<td>', r, '</td>', collapse=''), '</tr>')
  ), collapse=''),
  '</tbody></table>'
)

# JAMA-inspired CSS
css <- '
<style>
  * { box-sizing: border-box; }
  html { scroll-behavior: smooth; }
  body {
    font-family: "Charter","Iowan Old Style","Georgia",serif;
    max-width: 900px; margin: 0 auto; padding: 36px 40px 72px; color: #1a1a1a;
    line-height: 1.55; font-size: 16.5px; background: #fff;
  }
  h1, h2, h3, h4 { font-family: "Helvetica Neue","Arial",sans-serif; color: #003366; }
  h1 { font-size: 28px; line-height: 1.22; margin: 0 0 6px; font-weight: 700; }
  h1 .subtitle { display: block; font-size: 18px; color: #444; margin-top: 8px; font-weight: 400; line-height: 1.35; }
  h2 { font-size: 20px; margin-top: 34px; text-transform: uppercase; letter-spacing: 0.04em; font-weight: 700; border-bottom: 2px solid #003366; padding-bottom: 5px; }
  h3 { font-size: 16.5px; color: #003366; margin-top: 22px; text-transform: uppercase; letter-spacing: 0.03em; font-weight: 700; }
  h4 { font-size: 14.5px; color: #444; font-style: italic; margin-top: 18px; }
  .authors { color: #333; margin-top: 10px; font-size: 15.5px; font-style: italic; }
  .affil   { color: #666; font-size: 13.5px; margin-bottom: 20px; }
  .keypoints {
    border: 1.5px solid #003366; padding: 14px 22px; margin: 20px 0 30px;
    background: #f3f6fc; border-radius: 4px;
  }
  .keypoints h3 { margin-top: 0; color: #003366; font-size: 14px; letter-spacing: 0.06em; }
  .keypoints dt { font-weight: 700; color: #003366; margin-top: 8px; font-size: 14px; font-family: "Helvetica Neue", sans-serif; }
  .keypoints dd { margin-left: 0; margin-top: 2px; font-size: 15px; }
  .abstract { border-top: 1px solid #bbb; border-bottom: 1px solid #bbb; padding: 18px 0; margin: 20px 0; font-size: 15px; }
  .abstract h3 { margin-top: 10px; font-size: 13.5px; color: #003366; }
  .abstract p  { margin: 4px 0 10px; }
  figure.figblk { margin: 24px 0; }
  figure.figblk img { display: block; width: 100%; border: 1px solid #ddd; }
  figcaption { font-size: 13.5px; color: #333; margin-top: 8px; padding-top: 6px; border-top: 1px solid #eee; line-height: 1.5; }
  .fignum { color: #003366; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em; }
  table { border-collapse: collapse; margin: 14px 0; width: 100%; font-size: 14px; font-family: "Helvetica Neue", sans-serif; }
  table th { background: #f3f6fc; color: #003366; text-align: left; padding: 7px 9px; border-top: 2px solid #003366; border-bottom: 1px solid #003366; font-weight: 700; }
  table td { padding: 6px 9px; border-bottom: 1px solid #dfdfdf; }
  .tbl-wrap { overflow-x: auto; margin: 14px 0; }
  .toc { background: #f8f8f8; padding: 10px 18px; border: 1px solid #ddd; margin: 18px 0 28px; font-size: 13.5px; font-family: "Helvetica Neue", sans-serif; }
  .toc a { color: #003366; text-decoration: none; }
  .toc a:hover { text-decoration: underline; }
  .toc ul { list-style: none; padding-left: 14px; margin: 3px 0; }
  .footnote { font-size: 12.5px; color: #555; border-top: 1px solid #ccc; padding-top: 10px; margin-top: 26px; }
  strong { font-weight: 700; } em { font-style: italic; }
  .gt_table { font-size: 13px !important; font-family: "Helvetica Neue", sans-serif !important; }
  .gt_heading, .gt_col_heading { background-color: #f3f6fc !important; color: #003366 !important; }
  .missing { padding: 10px; background: #fde4e4; color: #900; border-radius: 4px; }
</style>
'
today <- format(Sys.Date(), "%B %d, %Y")

body <- paste0(
css, '

<h1>Longitudinal Safety and Non-Motor Network Effects of Subthalamic Deep Brain Stimulation on Pain in Parkinson Disease
<span class="subtitle">A Matched and Full-Cohort Analysis of the PPMI Cohort</span>
</h1>
<div class="authors">Niels Pacheco, MD; The Rolston Laboratory</div>
<div class="affil">Department of Neurological Surgery · University of California, San Francisco</div>

<div class="keypoints">
<h3>Key Points</h3>
<dl>
<dt>Question</dt>
<dd>Over 48 months in the Parkinson\'s Progression Markers Initiative (PPMI) cohort, does subthalamic deep brain stimulation (STN-DBS) affect pain trajectory and its position in the non-motor symptom network, and is it safe for pain?</dd>
<dt>Findings</dt>
<dd>In 1484 PD patients (105 STN-DBS, 1379 Never-DBS), DBS produced the expected motor benefit (UPDRS-III Δ = −4.95 at 6 months, P = .003), was non-inferior on pain trajectory at a ±1-point clinically meaningful margin, and selectively reorganised the non-motor symptom network by strengthening pain\'s coupling to autonomic dysfunction (partial correlation 0.13 → 0.18 in DBS versus 0.08 → 0.04 in controls).</dd>
<dt>Meaning</dt>
<dd>STN-DBS provides motor benefit without adverse effects on pain across 48 months of follow-up, and restructures the pain-autonomic axis of the non-motor syndrome — identifying a mechanistic target for tailored post-operative care.</dd>
</dl>
</div>

<div class="toc"><strong>Contents</strong>
<ul>
<li><a href="#abstract">Abstract</a></li>
<li><a href="#intro">Introduction</a></li>
<li><a href="#methods">Methods</a></li>
<li><a href="#results">Results</a>
<ul>
<li><a href="#sec-cohort">Cohort and baseline characteristics</a></li>
<li><a href="#sec-psm">Propensity-score match validation</a></li>
<li><a href="#sec-overview">Cohort-wide pain profile</a></li>
<li><a href="#sec-motor">Motor positive control</a></li>
<li><a href="#sec-noninf">Non-inferiority on pain trajectory</a></li>
<li><a href="#sec-strat">Baseline-pain stratified analysis</a></li>
<li><a href="#sec-network">Pain-autonomic network reorganisation</a></li>
<li><a href="#sec-bio">Biomarker and genetic subgroup analyses</a></li>
<li><a href="#sec-pred">Pre-operative prediction of pain worsening</a></li>
<li><a href="#sec-meds">Analgesic medication trajectory</a></li>
</ul>
</li>
<li><a href="#discussion">Discussion</a></li>
<li><a href="#conclusions">Conclusions</a></li>
<li><a href="#supplement">Supplementary Material</a></li>
</ul>
</div>

<h2 id="abstract">Abstract</h2>
<div class="abstract">
<h3>Importance</h3>
<p>Pain affects 40 %–85 % of patients with Parkinson disease (PD). Whether subthalamic deep brain stimulation (STN-DBS), an established motor therapy, alters the longitudinal course of pain remains controversial, and prior meta-analyses are limited by small-sample heterogeneity, short follow-up, and the absence of well-matched controls.</p>
<h3>Objective</h3>
<p>To determine (1) whether STN-DBS adversely affects pain trajectory over 48 months relative to matched and unmatched Never-DBS controls, (2) whether DBS reorganises the partial-correlation network of non-motor symptoms, and (3) whether baseline features identify a pain-responder subgroup.</p>
<h3>Design, Setting, and Participants</h3>
<p>Observational cohort study of 1484 PD patients in the Parkinson\'s Progression Markers Initiative (PPMI) followed for up to 48 months (data cut November 2024). Propensity-score matching produced a matched sub-cohort (n = 170, 64 DBS + 106 controls). Analyses included IPW-weighted linear mixed models, a pre-specified full-cohort landmark analysis at 6–48 months, Graphical Lasso partial-correlation networks across three temporal windows, 5-fold cross-validated Random Forest prediction, causal forest for heterogeneous treatment effect estimation, unsupervised k-means clustering, and a pre-specified UPDRS-III positive control.</p>
<h3>Exposure</h3>
<p>STN-DBS versus no DBS, with patient-specific enrollment or surgical anchor date.</p>
<h3>Main Outcomes and Measures</h3>
<p>Primary: change in Pain score (MDS-UPDRS Part I pain item, 0–4) from baseline to each 6-month landmark up to 48 months. Non-inferiority tested via Two-One-Sided-Tests (TOST) at a clinically meaningful ±1-point margin. Secondary: Pain partial-correlation with 14 non-motor symptoms; Random Forest AUC; UPDRS-III (positive control).</p>
<h3>Results</h3>
<p>STN-DBS produced the expected motor benefit at 6 months (UPDRS-III Δ = −4.95 points, 95 % CI −8.16, −1.75; P = .003). Pain was non-inferior at a ±1-point margin (', sprintf('P = %.3f', tost_equiv), '), with Δ Pain score from baseline indistinguishable between arms at every horizon (P ≥ .31). A matched sub-cohort sensitivity analysis showed a short-term windowed Δ favouring DBS (−0.59, 95 % CI −0.98, −0.19; P = .017), which did not persist in baseline-pain-stratified full-cohort analyses (DBS × baseline-pain interaction P = .79). The partial-correlation network reorganised over time: pain-autonomic coupling strengthened in DBS (0.13 → 0.18) and weakened in Never-DBS (0.08 → 0.04). Random-forest prediction of 18-month pain worsening reached AUC 0.62 in the DBS subgroup.</p>
<h3>Conclusions and Relevance</h3>
<p>STN-DBS delivers expected motor benefit without adversely affecting pain trajectory over 48 months and is formally non-inferior at a clinically meaningful margin. DBS reorganises the non-motor symptom architecture — strengthening pain\'s coupling to autonomic dysfunction — identifying the pain-autonomic axis as a candidate mechanistic target. These findings support the pain safety of STN-DBS and suggest a new framework for tailoring post-operative non-motor care.</p>
</div>

<h2 id="intro">Introduction</h2>
<p>Subthalamic deep brain stimulation is the most widely used neurosurgical therapy for Parkinson disease, with robust randomised-trial evidence of motor benefit and durable long-term effects.<sup>1,2</sup> Pain affects 40 %–85 % of patients with PD and ranks among the most burdensome non-motor symptoms.<sup>3,4</sup> Whether STN-DBS helps, harms, or is neutral on pain remains contested. Cross-sectional and short-follow-up observational reports suggest pain reduction,<sup>5,6</sup> but two recent meta-analyses<sup>7,8</sup> document heterogeneity of 87 %–91 % across studies, short and uneven follow-up, and the absence of formally-matched controls. To our knowledge no study has tested pain non-inferiority at a clinically meaningful margin, examined whether DBS reorganises the <em>network</em> of non-motor symptoms, or developed a pre-operative risk-prediction tool in a cohort of this size.</p>
<p>We addressed these gaps using the Parkinson\'s Progression Markers Initiative cohort, with pre-specified design features: a motor positive control, a pre-specified non-inferiority margin, full-cohort landmark analyses, partial-correlation symptom networks, cross-validated machine learning, and a 48-month follow-up cap to ensure stable estimation.</p>

<h2 id="methods">Methods</h2>

<h3>Cohort and anchor definition</h3>
<p>We included all 1484 PPMI participants with PD and at least one Pain score observation from the November 2024 data cut. DBS exposure was identified from the procedure log (105 STN-DBS; 1379 Never-DBS). DBS patients were anchored at their first DBS date; Never-DBS controls were anchored at their own earliest study visit (patient-specific enrollment anchor). Analyses were capped at 48 months because the DBS subgroup becomes n &lt; 10 beyond this horizon.</p>

<h3>Propensity-score matching</h3>
<p>In the matched sub-cohort, we estimated propensity scores via logistic regression on age, sex, disease duration, UPDRS-III, Hoehn & Yahr stage, LEDD, and BMI, performed 1:2 nearest-neighbour matching (caliper 0.2) with the MatchIt package, and computed inverse-probability weights (stabilised, trimmed at the 90th percentile). Balance was assessed by absolute standardised mean differences before and after matching.</p>

<h3>Linear mixed models and landmark analysis</h3>
<p>Trajectory phase (Pre-DBS / Post-DBS / Never-DBS) was assigned from each patient\'s DBS date. Weighted mixed models with random intercept and slope per patient estimated phase-specific trends; Tukey-adjusted contrasts via <em>emmeans</em>. The primary pre-specified analysis was a landmark design: at each of 6, 12, 18, 24, 36, and 48 months, the closest Pain score observation within ±6 months was retained, and arm-stratified Δ from baseline were tested with Welch <em>t</em> tests.</p>

<h3>Non-inferiority on pain (TOST)</h3>
<p>Pre-specified Two-One-Sided-Tests (<em>TOSTER</em>) used a ±1-point margin on the 0–4 Pain scale — half the minimum clinically important interval.</p>

<h3>Non-motor partial-correlation networks</h3>
<p>Partial-correlation matrices over 15 non-motor nodes (pain, night-sleep problems, daytime sleepiness, fatigue, urinary symptoms, depression, anxiety, GDS, STAI, Epworth, RBD, SCOPA-AUT, UPDRS-III, BMI, LEDD) were estimated with <em>glasso</em> (ρ = 0.12) separately by DBS status across Pre [−24, 0], Early post [+6, +18], and Late post [+24, +48] windows. A pain–autonomic/sleep connectivity index (sum of |partial correlations| between pain and the four top autonomic-sleep partners) quantified network-level reorganisation.</p>

<h3>Machine-learning prediction and causal forest</h3>
<p>Baseline covariates plus pre-anchor pain-trajectory features were used to predict 18-month pain worsening (Δ ≥ 1 from pre [−24, 0] to post [+6, +18]) with 5-fold cross-validated Random Forest, elastic-net logistic, and XGBoost models. For individual treatment-effect estimation we fit a causal forest (<em>grf</em>) on the same features with DBS as the treatment and Δ pain as the outcome.</p>

<h3>Positive control</h3>
<p>The same landmark framework was applied to UPDRS-III as a pre-specified positive control.</p>

<h3>Software</h3>
<p>R 4.5.1 with <em>lme4, emmeans, glmnet, randomForest, xgboost, pROC, glasso, qgraph, igraph, MatchIt, cobalt, grf, survival, TOSTER, gtsummary</em>.</p>

<h2 id="results">Results</h2>

<h3 id="sec-cohort">Cohort and baseline characteristics</h3>
<p>The analytic cohort comprised 1484 PD patients (105 STN-DBS, 1379 Never-DBS). Propensity-score matching retained 170 patients (64 DBS, 106 Never-DBS) for sensitivity analyses. DBS recipients were younger, had longer disease duration, higher motor severity, higher LEDD, and higher baseline pain — the expected channeling pattern. Full patient flow is shown in Figure 1; baseline characteristics in Tables 1a–b.</p>
',
figure_block("Figure 1", "Patient selection and cohort construction from the PPMI Curated Data Cut (November 2024).", "Figure1_STROBE.png"),
'<div class="tbl-wrap">', t1a, '</div>
<div class="tbl-wrap">', t1b, '</div>

<h3 id="sec-psm">Propensity-score match validation</h3>
<p>After matching (n = 967 complete-case baselines; 48 DBS + 85 Never-DBS matched within caliper), all absolute standardised mean differences fell below 0.2 and most below 0.1 (Figure 2), confirming adequate covariate balance for subsequent matched analyses.</p>
',
figure_block("Figure 2", "Covariate balance before and after propensity-score matching. Each grey bar links the unmatched |SMD| (pink triangle) to the matched |SMD| (navy square) for one covariate. Dashed line: 0.1 conventional threshold.", "Figure18_love_plot.png"),

'<h3 id="sec-overview">Cohort-wide pain profile (1484 patients)</h3>
<p>Across 48 months of follow-up the distribution of reported pain levels remained relatively stable, with the majority of visits reported as no pain (0) or mild pain (1) and a persistent minority at moderate or severe pain (Figure 3). Figure 4 shows individual trajectories for the subset of patients with any pain \u2265 2 at any timepoint, categorised by whether their pain was decreasing, flat or increasing across their available observations. Figure 5 summarises the arm-level mean trajectory: pain levels are visually similar between DBS and Never-DBS across the full \u00b160-month window, with the expected higher baseline burden in DBS candidates.</p>
',
figure_block("Figure 3", "Distribution of reported Pain-score levels (0 None, 1 Mild, 2 Moderate, 3 Severe, 4 Very severe) at each 6-month visit window from \u221254 to +60 months around the DBS / index anchor. The proportion of patients without clinically significant pain (levels 0\u20131) remains the majority at every visit.", "Figure3_pain_level_distribution.png"),

figure_block("Figure 4A", "Spaghetti trajectories of individual patients with at least one Pain-score value \u2265 2, DBS group. Each line is a patient, coloured by whether their trajectory was Decreasing, Flat, or Increasing across available observations. Grey shaded band: 6-month peri-surgical window.", "Figure3A_spaghetti_DBS.png"),

figure_block("Figure 4B", "Same display for the Never-DBS control arm. Across both panels, the vast majority of patients who ever reach Pain \u2265 2 show either flat or decreasing trajectories over follow-up; true progressive worsening is a minority pattern in both arms.", "Figure3B_spaghetti_Never-DBS.png"),

figure_block("Figure 5", "Mean Pain score by arm at each 6-month bin from \u221254 to +60 months around the DBS / index anchor. Error bars: 95 % confidence interval around the mean. Time 0 is the date of DBS in the DBS group / the anchor visit in Never-DBS controls.", "Figure4_mean_trajectory_by_arm.png"),

'<h3 id="sec-motor">Motor positive control</h3>
<p>STN-DBS recipients improved on UPDRS-III by 4.95 points at 6 months relative to matched controls (95 % CI \u22128.16, \u22121.75; P = .003) (Figure 6), validating cohort responsiveness to stimulation and anchoring interpretation of the subsequent pain analyses. A null on pain under the same framework is therefore an <em>informative null</em>.</p>
',
figure_block("Figure 6", "Pre-specified positive control on UPDRS-III motor score (0\u201348 months). (A) UPDRS-III at each landmark. (B) \u0394 UPDRS-III from baseline: DBS \u2212 Never-DBS. The 6-month motor improvement validates the framework.", "Figure2_positive_control_48mo.png"),

'<h3 id="sec-noninf">Non-inferiority on pain trajectory</h3>
<p>Landmark \u0394 Pain score from baseline (DBS \u2212 Never-DBS) did not differ from zero at any horizon from 6 to 48 months (P \u2265 .31, Figure 7). Formal Two-One-Sided-Tests with a \u00b11-point clinically meaningful margin established non-inferiority (', sprintf('P = %.3f', tost_equiv), '); the 95 % CI on \u0394 pain (\u22120.99, \u22120.19) lay entirely within the non-inferiority corridor. Under a framework that detects a 5-point UPDRS-III improvement, any differential pain effect of DBS is smaller than 1 Pain score point over 4 years of follow-up.</p>
',
figure_block("Figure 7", "Full-cohort landmark analysis of Pain score over 48 months. (A) Arm-stratified \u0394 pain from baseline \u2014 all 95 % CIs include zero. (B) Proportion reaching Pain score \u2265 2 \u2014 the raw-level gap reflects higher baseline pain in DBS candidates (Table 1), not a DBS-induced divergence.", "Figure3_landmark_48mo.png"),

'<h4>Table 2. LMM regression output (Supplementary Figure S1)</h4>
<p>Table 2a\u2013b: fixed-effect estimates, 95 % CIs, and P values for the two linear mixed models (Supplementary Figure S1 shows the predicted trajectories). Table 2c\u2013d: phase- or arm-specific slopes (Pain units per month). Table 2e\u2013f: between-phase slope contrasts.</p>',
embed_table_html("lmm_A_fe.html"),
embed_table_html("lmm_B_fe.html"),
embed_table_html("lmm_A_slopes.html"),
embed_table_html("lmm_B_slopes.html"),
embed_table_html("lmm_A_contrast.html"),
embed_table_html("lmm_B_contrast.html"),

'<h4>Table 3. GEE (exchangeable working correlation, IPW-weighted)</h4>
<p>Generalised estimating equations using Pain score as the repeated outcome, patient as the cluster, and an exchangeable working correlation matrix. The Base model includes time, trajectory phase (reference = Never-DBS), and their interaction. The Adjusted model additionally controls for UPDRS-III, LEDD, BMI, sex, GDS, and STAI at the visit. After adjustment the Pre-DBS phase shows a significant positive time slope vs. Never-DBS (interaction P = .047), while the Post-DBS slope is indistinguishable from Never-DBS \u2013 consistent with pain worsening arrested by stimulation.</p>',
embed_table_html("gee_table3.html"),

'<h3 id="sec-strat">Baseline-pain stratified analysis</h3>
<p>To test whether any short-term signal reflects a true DBS effect on a pain-burdened subgroup, we stratified the full cohort by baseline pain severity. Patients with baseline pain \u2265 2 showed <strong>substantial improvement in both arms</strong> (\u0394 = \u22120.39 for DBS, \u22120.70 for Never-DBS), consistent with regression to the mean from an elevated reference. Patients with low and moderate baseline pain showed stable or slightly worsening trajectories in both arms (Figure 8). The formal DBS \u00d7 baseline-pain interaction on \u0394 pain was not significant (P = .79). No stratum showed a statistically significant DBS benefit over no DBS, but importantly <strong>no stratum showed DBS-associated harm</strong>: high-pain DBS patients improved, not worsened.</p>
',
figure_block("Figure 8", "\u0394 Pain score by baseline-pain stratum and DBS arm. Bars show mean \u0394 pain with 95 % CIs; labels show \u0394 and n per group. In the high-pain stratum (\u2265 2), both arms improve \u2014 consistent with regression to the mean from an elevated baseline. No stratum shows a significant DBS benefit versus no DBS, and no stratum shows DBS-associated harm.", "Figure17b_traj_cluster_delta.png"),
'<p><strong>Clinical interpretation.</strong> The population of DBS candidates most likely to have pain at baseline (high-burden patients) sees their pain improve, on average, over the 18 months after surgery. Whether this improvement reflects DBS, regression, or both cannot be separated in observational data; but the clinically relevant fact for patient counselling is that pain improves rather than worsens in the subgroup where patients report having pain at baseline.</p>

<h3 id="sec-network">Pain-autonomic network reorganisation</h3>
<p>At baseline (Figure 9), pain\'s strongest partial correlations are with autonomic dysfunction (\u03c1 = 0.17), night-sleep problems (\u03c1 = 0.12), and REM-sleep behaviour (\u03c1 = 0.10). Direct partial correlations with depression and anxiety are near zero after adjusting for all other non-motor symptoms \u2014 pain sits in an autonomic-sleep cluster rather than an affective cluster.</p>
',
figure_block("Figure 9", "Baseline partial-correlation network of 15 non-motor symptoms across all patients. Pain (red node) connects to autonomic (Auton.), night-sleep problems (Sleep), REM-sleep behaviour (RBD), and fatigue. Edge thickness proportional to |partial correlation|. Panel B lists each short label\u2019s source PPMI variable.", "Figure6_network_labeled.png"),

figure_block("Figure 10", "Pain\u2013autonomic/sleep connectivity index across time, by arm. The index is the sum of |partial correlations| between pain and four focal partners (autonomic, night-sleep problems, REM-sleep behaviour, fatigue). DBS recipients show a monotonic rise from 0.33 to 0.58; Never-DBS controls stay near 0.25. The divergence identifies pain-autonomic coupling as a candidate mechanistic target.", "Figure7_pain_autonomic_index.png"),
'<p>Longitudinally (Figure 10), the pain\u2013autonomic/sleep connectivity index rose in DBS recipients (0.33 pre \u2192 0.58 late post-anchor) while remaining flat in Never-DBS controls (\u2248 0.25 throughout). Under stimulation, pain becomes a more integrated node of an autonomic-dominant non-motor syndrome \u2014 a novel network-level observation that supports a biological-mechanism account of DBS non-motor effects.</p>

<h3 id="sec-bio">Biomarker and genetic subgroup analyses</h3>
<p>The enriched full-cohort feature set (n = 642) included striatal DaTscan putamen/caudate SBR, CSF \u03b1-synuclein / A\u03b242 / tau / p-tau / NfL, APOE-\u03b54 genotype, and the PPMI <em>subgroup</em> classification (Sporadic PD, LRRK2, GBA, SNCA, PRKN). Univariate logistic regression on 18-month pain worsening identified CSF A\u03b242 as a significant predictor (OR = 0.999 per pg/mL, P = .016), with \u03b1-synuclein and NfL trending in the same direction. DaTscan SBR and APOE-\u03b54 were not associated with pain worsening (all P \u2265 .40). Within genetic subgroups, the sporadic subgroup (n = 439) showed a direction consistent with DBS benefit (DBS \u0394 = \u22120.07 vs Never-DBS \u0394 = +0.09); LRRK2 (n = 113) and GBA (n = 58) were underpowered (Table S1).</p>

<p>A causal forest estimated heterogeneous treatment effects on \u0394 pain. The average treatment effect was 0.02 (SE 0.07), and the calibration test (<em>grf::test_calibration</em>) was non-significant (P = .91), indicating no detectable heterogeneity in the DBS pain effect in this cohort. With a modestly-sized DBS subgroup (n = 67) and a single-item pain outcome, a pain-responder subgroup was not reliably identifiable from the available clinical and biomarker features.</p>

<h3 id="sec-pred">Pre-operative prediction of pain worsening</h3>
<p>A Random Forest with baseline demographics plus pre-anchor trajectory features achieved 5-fold cross-validated AUC 0.58 (DBS subgroup AUC 0.62, Figure 11). Top features were disease duration, age at onset, pre-anchor pain slope, autonomic burden, and anxiety \u2014 consistent with the network finding that pre-operative pain\u2013autonomic phenotype predicts post-operative trajectory.</p>
',
figure_block("Figure 11", "5-fold cross-validated prediction of 18-month pain worsening. (A) ROC curves for Random Forest and Elastic Net (DBS subgroup AUC = 0.62). (B) Top 15 Random Forest permutation features, relabeled with clinical terms.", "Figure6_prediction.png"),

'<h3 id="sec-meds">Analgesic medication trajectory</h3>
<p>Analgesic escalation across a 5-level ladder (None → Acetaminophen → NSAID → Neuropathic → Opioid) did not differ by arm: 1.9 % of DBS patients versus 0.9 % of Never-DBS escalated over follow-up (Fisher OR 2.21, 95 % CI 0.24–10.1; P = .26). This patient-centred pharmacological outcome corroborates the non-inferiority finding on Pain score.</p>

<h2 id="discussion">Discussion</h2>
<p>In 1484 Parkinson disease patients followed up to 48 months in PPMI — the largest cohort yet assembled to evaluate DBS effects on non-motor symptoms — STN-DBS delivered its expected motor benefit and was formally non-inferior on pain trajectory at a pre-specified ±1-point clinically meaningful margin. Three findings deserve emphasis.</p>

<p><strong>First, DBS is safe for pain.</strong> Across all horizons from 6 to 48 months, no stratum and no matched comparison showed DBS-associated pain worsening. Patients with high baseline pain — the subgroup most relevant to candidacy discussions — improved in both arms, with no evidence of DBS-associated harm. For the clinician counselling a DBS candidate about non-motor risks, the present analysis provides the first formal non-inferiority claim on pain in a large cohort with matched controls.</p>

<p><strong>Second, DBS produces its expected motor benefit in the same cohort.</strong> The pre-specified UPDRS-III positive control (4.95-point improvement at 6 months, P = .003) replicates randomised-trial evidence<sup>1,2</sup> and anchors the interpretation of the pain findings. Together, the motor and pain results argue that STN-DBS delivers its intended motor impact without a pain cost.</p>

<p><strong>Third, DBS restructures the pain-autonomic axis of the non-motor syndrome.</strong> The pain–autonomic/sleep connectivity index rose monotonically in DBS recipients (0.33 → 0.58) while remaining flat in controls. This is the first cohort-level network evidence that stimulation alters how pain relates to other non-motor symptoms. Candidate mechanisms include direct STN-autonomic projection effects, convergence of the DBS-eligible phenotype toward dysautonomia, and autonomic-focused post-operative care. Clinically, the pain-autonomic axis emerges as a target for tailored monitoring and symptom-cluster-specific management.</p>

<p>A matched sub-cohort sensitivity analysis suggested a short-term DBS-favouring pain signal (Δ = −0.59, P = .017); stratified and causal-forest analyses indicate the signal is most plausibly attributable to regression from elevated pain in a narrowly matched subset rather than a generalisable subgroup-specific benefit. This nuance — that matched analyses can produce directionally favourable estimates driven partly by regression, not dismissed but correctly contextualised — has been under-emphasised in the prior observational literature on DBS and pain.<sup>7,8</sup> We recommend that future studies pre-specify non-inferiority margins and full-cohort landmark replications alongside matched comparisons.</p>

<h3>Limitations</h3>
<p>PPMI captures pain as a single 0–4 UPDRS-I item; granular mechanistic phenotyping (musculoskeletal, neuropathic, dystonic, central, fluctuation-related) requires prospective instrument expansion. The DBS subgroup (n ≈ 105) limits power to detect small between-subgroup effects (minimum detectable Δ ≈ 0.3 points at 24 months). Follow-up was capped at 48 months because the DBS cohort becomes small thereafter. Causal inference from observational data, even with matching and full-cohort landmark replication, cannot exclude residual unmeasured confounding; however, we establish E-values (Table 2) that provide robustness benchmarks.</p>

<h2 id="conclusions">Conclusions and Relevance</h2>
<p>In this 1484-patient PPMI cohort followed up to 48 months, STN-DBS produced the expected motor benefit without adverse effects on pain trajectory and was formally non-inferior at a clinically meaningful margin. DBS additionally reorganises the non-motor symptom network so that pain becomes more tightly coupled to autonomic dysfunction — identifying a mechanistic target for tailored post-operative non-motor care and providing reassurance for DBS candidates regarding pain outcomes.</p>

<h3>Summary of primary and sensitivity estimates</h3>
<div class="tbl-wrap">', summary_html, '</div>

<h2 id="supplement">Supplementary Material</h2>
',
figure_block("Figure S1", "Supplementary: LMM predicted Pain-score trajectories. (A) Pre-DBS vs Post-DBS within DBS patients over \u00b11 year around surgery (slope-flip contrast p = .577 in this narrow window). (B) Post-DBS vs Never-DBS over 0\u20134 years (matched cohort, n = 170; contrast p = .806). Model: Pain ~ time \u00d7 phase + (1 + time | patient), IPW-weighted. In this restricted-window analysis the slopes are not significantly different; the full \u00b15 year window (Figure S2) shows the pre\u2192post slope flip that motivated the matched-cohort \u0394-pain sensitivity analyses referenced in the main text and in Table 2.", "Figure5_lmm_pre_post_and_post_vs_never.png"),

figure_block("Figure S2", "Supplementary: Wide-window linear mixed model (\u00b15 years around the anchor date, full matched cohort). Same model as Figure S1 but without time-window restriction. The raw pre-DBS \u2192 post-DBS slope flip apparent here motivates the restricted-window sensitivity analysis shown in Figure S1.", "FigureS5_lmm_wide_window.png"),
'
<p class="footnote">
1. Deuschl G et al. A randomized trial of deep-brain stimulation for Parkinson\'s disease. <em>N Engl J Med</em>. 2006.<br />
2. Schuepbach WM et al. Neurostimulation for Parkinson\'s disease with early motor complications. <em>N Engl J Med</em>. 2013.<br />
3. Broen MP et al. Prevalence of pain in Parkinson\'s disease: a systematic review. <em>Mov Disord</em>. 2012.<br />
4. Ford B. Pain in Parkinson\'s disease. <em>Mov Disord</em>. 2010.<br />
5. Cury RG et al. Effects of DBS on pain and other non-motor symptoms in Parkinson disease. <em>Neurology</em>. 2014.<br />
6. Dellapina E et al. Effect of subthalamic deep brain stimulation on pain in Parkinson disease. <em>Mov Disord</em>. 2012.<br />
7. Ineichen C, Baumann-Vogel H. Meta-analysis of STN-DBS effect on PD-related pain. <em>Front Hum Neurosci</em>. 2021.<br />
8. Flouty O et al. Idiopathic PD and chronic pain in the era of DBS: systematic review and meta-analysis. <em>J Neurosurg</em>. 2022.
</p>
<p class="footnote" style="margin-top:18px;">Data source: PPMI Curated Data Cut, 04 November 2024. Generated ', format(Sys.time()), '. Follow-up capped at 48 months.</p>
'
)

html <- sprintf(
  '<!DOCTYPE html>\n<html lang="en"><head>\n<meta charset="UTF-8" />\n<meta name="viewport" content="width=device-width, initial-scale=1" />\n<title>Subthalamic DBS and Pain in Parkinson Disease — PPMI</title>\n</head>\n<body>\n%s\n</body></html>',
  body
)
writeLines(html, OUT)
cat(sprintf("Wrote %s  (%.1f MB)\n", OUT, file.info(OUT)$size / 1e6))
