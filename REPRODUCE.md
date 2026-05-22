# REPRODUCE.md — replicating the published results

## TL;DR

```bash
# clone, restore environment, run on synthetic fixture (no PPMI access)
git clone https://github.com/nielspac177/ppmi-dbs-pain.git
cd ppmi-dbs-pain
make env       # installs renv + Python deps
make all       # ~15 min on a modern laptop; produces all outputs/
```

For *exact* replication of manuscript numbers, see "With real PPMI data" below.

---

## Computational environment

- **R**: 4.5.1 (locked via `renv.lock`)
- **Python**: 3.13+ (locked via `pyproject.toml` + `uv.lock`)
- **OS**: macOS 14+, Ubuntu 24.04, or any platform supporting Docker
- **Memory**: ≥ 8 GB recommended (bootnet bootstrap is the heaviest step)
- **Disk**: ≤ 2 GB after full run

A `Dockerfile` and `.devcontainer/devcontainer.json` are provided for
hassle-free reproduction. GitHub Codespaces will launch this automatically.

---

## With the synthetic fixture (default)

1. `make env` — `renv::restore()` + `uv pip install -r requirements.txt`
2. `make synth-data` — regenerates the synthetic PPMI cohort (deterministic, seeded)
3. `make analysis` — runs the primary, secondary, exploratory analyses
4. `make analyses` — runs the nine robustness analyses
5. `make figures` — rebuilds all figures (PNG + PDF + 600 dpi TIFF)
6. `make all` — does all of the above in correct dependency order
7. `make dashboard` — rebuilds the interactive results dashboard
8. `make book` — renders the Quarto book to `docs/_site/`

The synthetic fixture preserves variable names and approximate marginals;
absolute numbers will *differ* from the manuscript but qualitative patterns
should match.

---

## With real PPMI data

1. Apply for PPMI access at <https://www.ppmi-info.org/access-data-specimens/download-data>.
2. Download the November 2024 Curated Data Cut.
3. Copy / symlink the files listed in [data-access.md](data-access.md) into a local folder, e.g. `~/data/ppmi/`.
4. Copy `config.example.yml` to `config.yml` and:
   - set `use_synth: false`
   - set `ppmi_data_root: "/Users/you/data/ppmi"`
5. `make all`

Expected exact-replication of all manuscript figures and tables.

---

## What each analysis produces

| Sprint | Script | Headline output | Output table(s) | Output figure |
|---|---|---|---|---|
| 1 | `analyses/01_negative_controls.R` | Pipeline doesn't selectively detect nulls | `Analysis 01_negative_controls.csv` | `Analysis 01_negative_controls.{png,pdf}` |
| 2 | `analyses/02_anchor_sensitivity.R` | Primary TOST invariant to 3 anchor schemes | `Analysis 02_anchor_sensitivity.csv` | `Analysis 02_anchor_sensitivity.{png,pdf}` |
| 3 | `analyses/03_evalue_mnar.R` | E-value table; TOST flips at ±1-point MNAR shift | `Analysis 03_evalue_table_E1.csv`, `Analysis 03_mnar_tipping.csv`, `Analysis 03_dropout_by_arm.csv` | `Analysis 03_mnar_tipping.{png,pdf}` |
| 4 | `analyses/04_nct_bootnet.R` | Late-post NCT P = 0.050 | `Analysis 04_nct_global.csv`, `Analysis 04_pain_edge_ci.csv` | `Analysis 04_pain_neighbours.{png,pdf}` |
| 5 | `analyses/05_bootstrap_brant_firth.R` | Bootstrap Δρ + Brant P > 0.7 (PO holds) | `Analysis 05_bootstrap_drho.csv`, `Analysis 05_brant_polr.csv`, `Analysis 05_profile_firth_ci.csv` | — |
| 6 | `analyses/06_robust_ses.R` | Cluster-robust SE + AR(1) sensitivity | `Analysis 06_lmm_robust_se.csv`, `Analysis 06_gee_corstr_sens.csv` | — |
| 7 | `analyses/07_psm_diagnostics.R` | c-statistic = 0.885; caliper sensitivity | `Analysis 07_weight_distribution.csv`, `Analysis 07_caliper_sensitivity.csv` | `Analysis 07_psm_overlap.{png,pdf}`, `Analysis 07_love_plot.{png,pdf}` |
| 8 | `analyses/08_competing_risk.R` | Fine-Gray HR 1.86 (1.28–2.69) | `Analysis 08_finegray.csv`, `Analysis 08_cs_cox.csv`, `Analysis 08_event_data.csv` | `Analysis 08_cif_pain_worsening.{png,pdf}` |
| 9 | `analyses/09_ledd_mediation.R` | ΔLEDD does not mediate | `Analysis 09_mediation_results.csv` | — |

---

## Troubleshooting

- **`bootnet` errors with "empty network"** → too aggressive EBICglasso default. Analysis 04 already falls back to fixed-ρ GLASSO when this happens.
- **`brant::brant()` `'invalid times argument'`** → known issue when called inside an R function (brant walks `parent.frame()`). Analysis 05 uses a manual Wald-based PO test as a workaround.
- **`clubSandwich::vcovCR` "prior weights not supported"** → fit unweighted refit for robust-SE comparison only (Analysis 06).
- **Permission denied on `/Volumes/...`** → you have hardcoded paths from an earlier checkout; pull again or reset `config.yml`.

For other issues, please file a bug report using the
[issue template](.github/ISSUE_TEMPLATE/replication-issue.yml).
