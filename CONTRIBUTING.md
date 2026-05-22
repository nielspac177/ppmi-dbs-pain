# Contributing

Thank you for your interest in `ppmi-dbs-pain`. This repository accompanies
a manuscript in preparation; we welcome contributions, replication reports,
and **adversarial collaboration**.

## How to contribute

### Bug reports / replication failures

Use the [Replication issue template](.github/ISSUE_TEMPLATE/replication-issue.yml).
Please include:
- which script failed,
- the full error message,
- output of `sessionInfo()` (R) or `python -V` + `pip list`,
- whether you ran on the synthetic fixture or real PPMI data.

### Adversarial collaboration

We explicitly invite skeptics and methodologists to submit PRs adding
sensitivity analyses, alternative model specifications, or improved
robustness checks. Open an issue first to discuss; we will work with you
to integrate the analysis as a `sprintNN_*.R` script that runs alongside
the existing nine.

### Code contributions

1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/my-change`).
3. Follow the existing code style:
   - R: `dplyr::` namespace prefixes, `set.seed()` at the top of every
     stochastic script, output via the helpers in
     `R/helpers/pain_helpers.R`.
   - Python: PEP-8, type hints on public functions.
4. Add or update unit tests under `tests/testthat/`.
5. Run `make tests` locally — CI will rerun on push.
6. Submit a PR. CI must pass before merge.

### Commit style

Conventional Commits format:
- `feat:` new analysis or feature
- `fix:` bug fix in existing analysis
- `docs:` documentation only
- `test:` test additions
- `refactor:` no behaviour change
- `chore:` build / dependency updates

## Pre-registration

The original analysis plan is in `PRE_REGISTRATION.md`. Sprint analyses
01–09 were added post-hoc on 2026-05-19 in response to internal critical
review; all are explicitly labeled `[robustness]` in `MANIFEST.md` to
preserve the audit trail.
