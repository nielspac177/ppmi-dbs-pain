# ADR-0009 · Code/site separation via two-branch architecture

- Status: **Accepted**
- Date: 2026-05-22

## Context

The repository serves two distinct audiences with different needs:

1. **Reviewers and replicators** want a clean, focused codebase they can
   trust: terse README, clear file structure, reproducibility
   infrastructure, no marketing language.
2. **Readers, collaborators, and citing authors** want a beautiful
   summary of the findings: interactive dashboard, methods schematic,
   KPI cards, infographics.

Mixing these two on the same branch produces a confusing artefact —
neither a clean replication target nor a polished public face. Reviewer
comments on v1 of this repo specifically flagged the marketing-style
README and the embedded `docs/dashboard.html` as out of place for a
reproducibility-focused repository.

## Decision

Adopt the standard scientific-software two-branch architecture:

- **`main` branch** — strictly reproducibility-focused. Code,
  tests, data-access docs, manuscript files, ADRs, synthetic data
  fixture. No HTML, no rendered dashboards, no marketing copy.
- **`gh-pages` branch** — orphan branch containing the public
  website. Minimal-academic aesthetic (Tailwind + Inter, navy/grey
  palette, JAMA/Nature-website-style). Auto-deployed to
  <https://nielspac177.github.io/ppmi-dbs-pain/>.

The source for the site lives **only on the `gh-pages` branch**.
A build script `scripts/build_site.py` on the `main` branch
generates the site from the analysis outputs and pushes it to
`gh-pages` via a git worktree.

## Consequences

**Positive**
- `main` branch is a clean replication target.
- The website can iterate on aesthetics without polluting the code
  history.
- GitHub Pages source is configured to `gh-pages` branch; one click
  to deploy.
- Reviewers cloning `main` see only what is needed to verify the
  pipeline.

**Negative**
- Two branches to keep mentally distinct. Mitigated by
  `scripts/build_site.py` being the single entry point for
  regenerating the site.
- Site updates require a separate commit on `gh-pages`. Mitigated by
  the script auto-pushing via git worktree.
- The first time a reviewer asks "where is the dashboard?", they need
  to be pointed at the URL not the repo. `README.md` calls this out
  explicitly.

## Alternatives considered

- **Single branch with `/docs` GitHub Pages source.** Mixes concerns;
  produces the original v1 problem.
- **Two separate repositories.** Highest mental clarity but harder
  to keep in sync — versioning a paper plus its website across two
  repos is unnecessary overhead.
- **GitHub Actions auto-build on push.** Considered for v1.1; will
  add once site stabilises. The current manual `scripts/build_site.py`
  workflow is simpler and adequate.
