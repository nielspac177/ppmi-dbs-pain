# MANIFEST — every script labeled

Labels:
- `[primary]` — pre-specified analysis for the main paper
- `[secondary]` — pre-specified secondary analysis
- `[exploratory]` — pre-specified exploratory analysis
- `[robustness]` — post-hoc robustness analysis added 2026-05-19
- `[infra]`  — pipeline infrastructure (figure rebuilds, docx assembly)
- `[deprecated]` — historical patch; kept only for audit trail

## R analysis scripts (`R/`)

| Path | Label | What it does |
|---|---|---|
| `R/helpers/pain_helpers.R` | [infra] | Shared data loaders, palette, output helpers, symmetric-midpoint anchor logic |
| `R/build_fig5_and_tables.R` | [primary] | LMM Pre/Post-DBS slope contrasts (Fig 5 + Table 2) |
| `R/build_gee_table3.R` | [primary] | GEE Table 3 (IPW-weighted) |
| `R/build_replication_figs.R` | [primary] | STROBE figure + wide-window LMM Supp Fig |
| `R/build_delta_24m_landmark.R` | [primary] | 24-month landmark Δ Pain |
| `R/build_delta_matched_6_12mo.R` | [primary] | Matched-cohort stratified Δ Pain at 6/12 mo |
| `R/build_stratified_delta_by_window.R` | [secondary] | Δ Pain by baseline-pain stratum × time |
| `R/build_alluvial_pain.R` | [secondary] | Alluvial NP1PAIN trajectories (full cohort) |
| `R/build_alluvial_pain_matched.R` | [secondary] | Alluvial trajectories (matched cohort) |
| `R/25_genetics_arm_pain.R` | [exploratory] | PD-PRS / APOE / SAA / GBA × DBS interactions |
| `R/26_pain_motor_coupling.R` | [exploratory] | Pain–motor coupling (full cohort) |
| `R/26b_pain_motor_coupling_matched.R` | [exploratory] | Pain–motor coupling (matched cohort) |
| `R/26c_pain_as_outcome.R` | [exploratory] | Pain as outcome ordinal/binary logit |
| `R/make_radar_figs.R` | [secondary] | Radar plots for clusters (user pref: always radar + clinical labels) |
| `R/build_paper_docx.R` | [infra] | Word doc assembly (legacy) |
| `R/build_paper_standalone.R` | [infra] | Standalone build of paper.docx |
| `R/build_original_figures_hires.R` | [infra] | High-res rebuilds for submission |
| `R/build_causal_dag.R` | [robustness] | Causal DAG (dagitty) — adjustment set |

## Analysis scripts (`analyses/`)

| Path | Label | What it does |
|---|---|---|
| `analyses/01_negative_controls.R` | [robustness] | NP1HALL/URIN/COG as negative controls |
| `analyses/02_anchor_sensitivity.R` | [robustness] | 3 anchor schemes vs primary TOST |
| `analyses/03_evalue_mnar.R` | [robustness] | E-value supplementary table + MNAR tipping point |
| `analyses/04_nct_bootnet.R` | [robustness] | Network Comparison Test + bootnet stability |
| `analyses/05_bootstrap_brant_firth.R` | [robustness] | Bootstrap Δρ + Brant + profile/Firth CIs |
| `analyses/06_robust_ses.R` | [robustness] | Cluster-robust SE (CR2) + GEE AR(1) |
| `analyses/07_psm_diagnostics.R` | [robustness] | PSM overlap + weight dist + c-stat + caliper sweep |
| `analyses/08_competing_risk.R` | [robustness] | Fine-Gray subdistribution hazard |
| `analyses/09_ledd_mediation.R` | [robustness] | ΔLEDD mediation analysis |

## Python build scripts (`scripts/`)

| Path | Label | What it does |
|---|---|---|
| `scripts/_build_methods_figure.py` | [infra] | Methods schematic figure |
| `scripts/_build_docx_v7.py` | [infra] | docx assembly (legacy version) |
| `scripts/_build_docx_v9.py` | [infra] | docx assembly (current version) |
| `scripts/_build_docx_v9_add_methods.py` | [infra] | docx inserts methods schematic |
| `scripts/build_callgraph.py` | [infra] | Pipeline callgraph (Mermaid + PNG) |
| `scripts/build_dashboard.py` | [infra] | Interactive HTML results dashboard |
| `scripts/build_sankey.py` | [infra] | Sankey flowchart of cohort + analyses |

## Notebooks (`notebooks/`)

36 Jupyter notebooks (numbered 00–23 + b/c variants). See README in
each notebook for purpose. The numbered notebooks form the original
pipeline; the same logic is being progressively migrated to `R/` scripts.

## Archived (`archive/`)

| Path | Label |
|---|---|
| `archive/final_fixes.R` | [deprecated] — superseded by `R/helpers/pain_helpers.R` |
| `archive/fix_labels_v3.R` | [deprecated] |
| `archive/fix_network_figure.R` | [deprecated] |

## Outputs

- `outputs/figures/` — rebuilt by `make figures` (gitignored except for `Figure_callgraph` and `Figure_causal_DAG`)
- `outputs/tables/` — rebuilt by `make analysis` and `make analyses`
- `outputs/objects/` — RDS checkpoints, rebuilt by `make analysis`
- `outputs/aggregated/` — **committed, PPMI-DUA-safe** summary tables
