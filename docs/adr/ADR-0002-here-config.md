# ADR-0002 · `here::here()` + `config.yml` paths

- Status: **Accepted**
- Date: 2026-05-20

## Context

The original Pain_paper_v2 codebase used a hardcoded
`PROJECT_ROOT <- "/Users/nielspacheco/Desktop/Research/Rolston lab/..."`
in `pain_helpers.R`. This is the single most reliable "code only runs on
the author's machine" signal in scientific computing. It also makes the
repo unusable in Docker, Codespaces, CI, on any collaborator's machine,
and prevents the synthetic-data fixture (ADR-0001) from working without
manual path edits.

## Decision

Replace `PROJECT_ROOT` with two layers:

1. `here::i_am("R/helpers/pain_helpers.R")` at the top of the helpers
   module. The `here` package walks up from the current source file
   until it finds a `.Rproj`, `.here`, `.git`, or `DESCRIPTION` marker
   and uses that as the project root. This makes the helpers
   self-locating from any working directory.
2. `config.yml` (gitignored) and `config.example.yml` (committed) at
   the repo root, with the structure:
   ```yaml
   default:
     data:
       use_synth: true|false
       ppmi_data_root: "/local/path"
       matched_long_csv: "..."
       full_xlsx: "..."
     paths:
       figures: "outputs/figures"
       tables:  "outputs/tables"
       objects: "outputs/objects"
   ```
   Read once at helper load time; values populated into `OUT_FIG`,
   `OUT_TAB`, `OUT_OBJ`, `path_full_xlsx`, etc.

A null-coalescing operator `%||%` is defined at the top of the helpers
to fall back gracefully when config keys are missing.

## Consequences

**Positive**
- Code runs unchanged in Codespaces, Docker, CI, any teammate's machine.
- Synthetic-mode and real-data-mode toggle is one config edit.
- `outputs/` paths are configurable, easing migration to e.g. a shared
  network drive.

**Negative**
- One additional dependency (`here`, `yaml`).
- Tests that source `pain_helpers.R` need to know about
  `config.example.yml` (mitigated by shipping the example file).
- `here::i_am()` will throw if the source file is moved without
  updating the relative path.

## Alternatives considered

- **Environment variables only** (e.g., `PPMI_DATA_ROOT=...`). Less
  discoverable than a config file. Used as override on top of the
  config (via `Sys.getenv`).
- **R `options()` set in `.Rprofile`.** Per-user; not committable; bad
  for collaboration.
- **`rprojroot` directly** instead of `here`. `here` is just a
  user-friendly facade over `rprojroot`. Equivalent.
