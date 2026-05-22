# ppmi-dbs-pain

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![R](https://img.shields.io/badge/R-4.5.1-blue?logo=R)](https://www.r-project.org/)
[![Reproduce](https://img.shields.io/badge/make-all-brightgreen)](REPRODUCE.md)

Code and reproducibility artefacts for **Pacheco-Barrios & Rolston (in preparation)**, a target-trial-emulation matched longitudinal analysis of deep brain stimulation effects on pain trajectory in the Parkinson's Progression Markers Initiative.

> This repository exists so reviewers and replicators can verify our pipeline end-to-end. The findings, dashboard, and reader-facing summaries are on the public website at **<https://nielspac177.github.io/ppmi-dbs-pain/>**.

---

## What's in this repo

- `R/` — primary analysis code (cohort building, LMM, GEE, GLASSO, mediation).
- `analyses/` — 16 numbered robustness analyses (negative controls, anchor sensitivity, E-value, MNAR tipping-point, NCT + bootnet, bootstrap Δρ, robust SE, AR(1), PSM diagnostics, Fine-Gray, ΔLEDD mediation, IPCW, bootstrap-distribution genetics, TOST margin grid, sequential-trial emulation, independent-complement Δρ, multi-mediator, demographics).
- `R/helpers/pain_helpers.R` — shared utilities (`here()`-driven, no hardcoded paths).
- `R/helpers/make_synthetic_cohort.R` — seeded synthetic PPMI fixture generator.
- `tests/testthat/` — unit tests (anchor logic, POSIXct fix, Okabe-Ito palette, bootstrap invariants, TOST, synth schema).
- `scripts/` — Python build scripts (methods schematic, docx assembly, callgraph, Sankey, site).
- `data-synth/` — synthetic PPMI fixture (clearly labelled FAKE DATA).
- `manuscript/` — manuscript draft, peer review, response to reviewers, future-paper hypothesis bank.
- `adr/` — Architecture Decision Records (MADR format) for every irreversible design choice.
- `notebooks/` — 36 Jupyter notebooks (original pipeline, gradually migrating to `R/`).
- `ppmiTTE/` — extracted R package skeleton for the TTE framework.
- `outputs/` — gitignored; rebuilt by `make all`. `outputs/aggregated/` contains DUA-safe summaries (committed).

---

## Reproducing the analyses

```bash
git clone https://github.com/nielspac177/ppmi-dbs-pain.git
cd ppmi-dbs-pain
make env          # restore renv + Python deps
make synth-data   # regenerate synthetic PPMI fixture (deterministic; seed 20260519)
make all          # primary + analyses + figures
```

Full instructions, including the path for *exact* replication using real PPMI data (data not redistributed; see `data-access.md`), are in [`REPRODUCE.md`](REPRODUCE.md).

For a one-click reviewer environment, click **Code → Codespaces → Create** on the GitHub page; the devcontainer launches R 4.5.1, all CRAN packages, Python 3.13, and Quarto preinstalled.

---

## Files reviewers should look at first

| For… | Read |
|---|---|
| Reproducing the pipeline | [`REPRODUCE.md`](REPRODUCE.md) |
| Provenance of every script | [`MANIFEST.md`](MANIFEST.md) |
| What was pre-specified vs post-hoc | [`PRE_REGISTRATION.md`](PRE_REGISTRATION.md) |
| Causal-inference assumptions | [`adr/ADR-0005-symmetric-anchor.md`](adr/ADR-0005-symmetric-anchor.md), [`adr/ADR-0008-target-agnostic-dbs.md`](adr/ADR-0008-target-agnostic-dbs.md) |
| Statistical-method choices | [`adr/`](adr/) (8 ADRs) |
| Manuscript draft | [`manuscript/MANUSCRIPT_DRAFT.md`](manuscript/MANUSCRIPT_DRAFT.md) |
| Internal peer review | [`manuscript/PEER_REVIEW.md`](manuscript/PEER_REVIEW.md) |
| How we addressed reviewer comments | [`manuscript/RESPONSE_TO_REVIEWERS.md`](manuscript/RESPONSE_TO_REVIEWERS.md) |
| Data access | [`data-access.md`](data-access.md) |

---

## Citation

If you use this code, please cite the manuscript (in preparation) and the software release (Zenodo DOI to be assigned at submission). See [`CITATION.cff`](CITATION.cff).

---

## License

- **Code** — [MIT](LICENSE).
- **Figures + aggregated outputs + manuscript excerpts** — [CC-BY-4.0](LICENSE-figures.md).
- **Raw PPMI data** — not redistributed; see [`data-access.md`](data-access.md).

---

## Reporting bugs / replication failures

Open an issue using the [replication template](.github/ISSUE_TEMPLATE/replication-issue.yml). For security-sensitive issues, see [`SECURITY.md`](SECURITY.md). Contributions welcome — see [`CONTRIBUTING.md`](CONTRIBUTING.md), including an explicit invitation for adversarial collaboration.
