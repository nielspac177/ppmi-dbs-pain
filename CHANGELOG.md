# Changelog

All notable changes to this project will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial public release with full code, synthetic data fixture,
  Docker/Codespaces configuration, Quarto book skeleton, and
  interactive results dashboard.
- 9 robustness "sprint" analyses (post-hoc, 2026-05-19): negative
  controls, anchor sweep, E-value + MNAR, NCT + bootnet, bootstrap
  Δρ + Brant + Firth, cluster-robust SE + GEE AR(1), PSM diagnostics,
  Fine-Gray competing-risk, ΔLEDD mediation.
- Causal DAG via dagitty (`R/build_causal_dag.R`).
- Pipeline callgraph (`scripts/build_callgraph.py`).
- Sankey flowchart (`scripts/build_sankey.py`).
- Interactive HTML results dashboard (`scripts/build_dashboard.py`).
- `ppmiTTE` R package skeleton (target-trial-emulation utilities,
  WIP — extraction from helpers).

### Changed
- Replaced hardcoded `PROJECT_ROOT` in helpers with `here::here()` +
  `config.yml`-driven paths.
- Added Okabe-Ito palette, `theme_pain_pub()`, and `save_fig_pub()`
  (PNG + PDF + TIFF) to `R/helpers/pain_helpers.R`.

### Deprecated
- Legacy patch scripts (`final_fixes.R`, `fix_labels_v3.R`,
  `fix_network_figure.R`) moved to `archive/` with explanation.

### Fixed
- POSIXct → Date arithmetic bug in symmetric-midpoint anchor
  (originally surfaced 2026-04-20); now extracted to
  `compute_symmetric_midpoint_anchors()` so the fix lives in one place.
- `time_pos` axis-orientation artifact (originally 2026-04-20).

## [0.9.0-preprint] — 2026-04-20 (pre-public, internal tag)

- Manuscript v11 produced; analysis pipeline as in `Pain_paper_v2/`.
