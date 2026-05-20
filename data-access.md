# Data access

## Raw PPMI data is NOT included in this repository

The Parkinson's Progression Markers Initiative (PPMI) Data Use Agreement
prohibits redistribution of patient-level data. To reproduce the manuscript
results *exactly* you must apply for PPMI access yourself.

## How to obtain access

1. Register at <https://www.ppmi-info.org/access-data-specimens/download-data>.
2. Sign the PPMI Data Use Agreement.
3. Download the **November 2024 Curated Data Cut**.

Typical turnaround for access approval is ~1 week.

## Files required by this pipeline

Once you have access, place the following files in your local PPMI data
directory (e.g. `~/data/ppmi/`):

| Expected filename | Source (PPMI download) | Description |
|---|---|---|
| `PPMI_basic1.xlsx` | Curated Cut, basic1 | Patient-level visits, demographics, MDS-UPDRS, LEDD |
| `ppmi_rel_matched_long_z.csv` | derived | Propensity-matched long-format cohort (1:2, z-scored covariates) |
| `ppmi_rel_matched_long_six.csv` | derived | Same, with 6-month time bins |
| `MDS-UPDRS_Part_III_04Nov2024.csv` | Curated Cut, MDS-UPDRS III | Motor scores by visit |
| `MDS-UPDRS_Part_I_04Nov2024.csv` | Curated Cut, MDS-UPDRS I | Non-motor scores (incl. NP1PAIN) |
| `Medical_Conditions_Log_04Nov2024.csv` | Curated Cut, MedCondLog | Free-text MHTERM for analgesic + pain-phenotype matching |
| `ppmi_database.db` | MJF-foundation supplementary | Genetic_status table (PD-PRS, APOE-ε4, SAA, GBA) — for `R/25_genetics_arm_pain.R` |

The derived `ppmi_rel_matched_long_*.csv` files are produced by the original
PSM script (notebook `23_psm_validation.ipynb`); we plan to provide that
recipe as `R/00_build_matched_cohort.R` in a future release.

## Configuring local paths

After downloading:

```bash
cp config.example.yml config.yml
```

Then edit `config.yml`:

```yaml
data:
  use_synth: false                       # turn off synthetic mode
  ppmi_data_root: "/Users/you/data/ppmi" # your local download path
```

Now `make all` will use real PPMI data and reproduce the manuscript numbers.

## What if I cannot get PPMI access?

The repository ships with a **synthetic fixture** (`data-synth/`) that preserves
variable names and rough distributions but is *not real data*. You can:

- Run the full pipeline (`make all`) on the synthetic cohort
- Verify the code executes end-to-end
- Read and understand the methods

…but you cannot reproduce the manuscript numbers without real PPMI data.

## Aggregated outputs (DUA-safe)

`outputs/aggregated/` contains aggregated summary tables (e.g. cohort
counts per arm, KM survival probabilities at canonical timepoints, mediation
point estimates) derived from real PPMI data. These are *aggregated* and
contain no patient-level rows, which is permitted under PPMI DUA. Reviewers
can spot-check the headline numbers against the manuscript here.
