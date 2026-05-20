# Security policy

This is a research code repository for an observational analysis. It has
no online attack surface beyond the GitHub-hosted source, but we take the
following commitments seriously:

## Patient data

- **Raw PPMI data is never committed** to this repository under any
  branch, tag, or release. See [data-access.md](data-access.md).
- If you discover any committed file that appears to contain
  patient-level data, please report it privately to
  nielspacheco1997@gmail.com — do not open a public issue.

## Reporting vulnerabilities

For software-security issues (e.g. shell-injection in a build script,
secret leakage), please email nielspacheco1997@gmail.com with the subject
line `[security] ppmi-dbs-pain`. You can expect an acknowledgement within
72 hours.

## Supported versions

Only the `main` branch is supported. Tagged releases are immutable.
