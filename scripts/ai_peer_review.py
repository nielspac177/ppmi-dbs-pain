"""
ai_peer_review.py — local AI peer-review harness for any manuscript.

Usage:
    export ANTHROPIC_API_KEY=...
    python scripts/ai_peer_review.py docs/MANUSCRIPT_DRAFT.md
    # writes docs/MANUSCRIPT_DRAFT.review.json

Uses Claude Opus by default; switch to Sonnet for cheaper passes.
Manuscript is sent with prompt caching (cache_control: ephemeral) so
re-runs against different rubrics are inexpensive after the first call.

If `--ss-citation-gap` is passed, also performs a Semantic Scholar
citation-gap check on the title and returns "papers you may have missed"
in the same JSON output.
"""
from __future__ import annotations
import argparse
import json
import os
import sys
import pathlib

DEFAULT_RUBRIC = """\
You are a senior reviewer for JAMA Neurology / Lancet Neurology.
Review the attached manuscript against the following rubric:

1. Novelty — does this advance the field beyond what is published?
2. Methodological rigour — TTE framing, causal-inference assumptions,
   missing-data handling, multiplicity.
3. Statistical validity — TOST margin, IPCW/IPTW, model specification,
   Bayesian-vs-frequentist consistency.
4. Internal validity — channeling, immortal time, residual confounding.
5. External validity — cohort representativeness; EARLYSTIM-era subset.
6. Clarity — abstract precision, claim calibration, figure interpretation.
7. Reproducibility — code availability, synthetic-data fixture, ADRs,
   CI status.
8. Reporting — STROBE / TRIPOD / ROBINS-I compliance.
9. Figures — Okabe-Ito palette, 300+ DPI, sans-serif, vector formats.

Return STRICT JSON with this exact structure (no prose outside JSON):
{
  "scores": {
    "novelty": int (1-10),
    "rigor": int (1-10),
    "stats": int (1-10),
    "clarity": int (1-10),
    "reproducibility": int (1-10),
    "reporting": int (1-10),
    "figures": int (1-10),
    "overall": int (1-10)
  },
  "decision": "accept" | "minor_revisions" | "major_revisions" | "reject",
  "headline_summary": "<2-3 sentences>",
  "major_comments": ["...", "..."],
  "minor_comments": ["...", "..."],
  "stat_concerns": ["...", "..."],
  "missing_citations": ["...", "..."],
  "five_priority_revisions": ["...", "..."]
}
"""

def review(manuscript_path: pathlib.Path,
           rubric: str = DEFAULT_RUBRIC,
           model: str = "claude-opus-4-7") -> dict:
    try:
        import anthropic
    except ImportError:
        sys.exit("Install: pip install anthropic")

    if not os.environ.get("ANTHROPIC_API_KEY"):
        sys.exit("Set ANTHROPIC_API_KEY environment variable.")

    text = manuscript_path.read_text(encoding="utf-8")
    client = anthropic.Anthropic()

    msg = client.messages.create(
        model=model,
        max_tokens=8000,
        system=[
            {"type": "text",
             "text": "You are a rigorous, constructive, JAMA-Neurology-style "
                     "peer reviewer. Return STRICT JSON only — no prose, no "
                     "markdown fences, no preamble. Reject manuscripts where "
                     "claims exceed evidence."},
            {"type": "text", "text": rubric,
             "cache_control": {"type": "ephemeral"}},
            {"type": "text", "text": text,
             "cache_control": {"type": "ephemeral"}},
        ],
        messages=[{"role": "user",
                   "content": "Review the manuscript above. JSON only."}],
    )
    raw = msg.content[0].text
    # Strip any accidental markdown fences
    if raw.startswith("```"):
        raw = raw.split("```", 2)[1]
        if raw.startswith("json"):
            raw = raw[4:]
    return json.loads(raw.strip())


def semantic_scholar_gaps(title: str, top_k: int = 20) -> list[dict]:
    """Find candidate missed-citation papers via Semantic Scholar.

    Returns paper metadata (title, authors, year, citations) — caller is
    responsible for cross-checking against the manuscript reference list.
    """
    try:
        import requests
    except ImportError:
        sys.exit("Install: pip install requests")
    url = "https://api.semanticscholar.org/graph/v1/paper/search"
    params = {
        "query": title,
        "limit": top_k,
        "fields": "title,authors,year,citationCount,abstract,externalIds",
    }
    r = requests.get(url, params=params, timeout=30)
    r.raise_for_status()
    return r.json().get("data", [])


def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("manuscript", type=pathlib.Path)
    p.add_argument("--model", default="claude-opus-4-7",
                   help="Anthropic model ID (opus by default; sonnet is cheaper).")
    p.add_argument("--rubric", type=pathlib.Path,
                   help="Path to a custom rubric .md (defaults to built-in).")
    p.add_argument("--ss-citation-gap", action="store_true",
                   help="Also run a Semantic Scholar citation-gap check on the title.")
    args = p.parse_args(argv)

    rubric = args.rubric.read_text() if args.rubric else DEFAULT_RUBRIC
    result = review(args.manuscript, rubric=rubric, model=args.model)

    if args.ss_citation_gap:
        first_line = next(
            (l.lstrip("# ").strip() for l in args.manuscript.read_text().splitlines()
             if l.startswith("#")),
            args.manuscript.stem,
        )
        result["semantic_scholar_candidates"] = semantic_scholar_gaps(first_line)

    out = args.manuscript.with_suffix(".review.json")
    out.write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(f"[OK] {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
