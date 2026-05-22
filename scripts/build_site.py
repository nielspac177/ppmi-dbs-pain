"""
build_site.py — regenerate the public gh-pages website.

Design language (minimal academic):
  - Inter typography, navy (#1e3a5f) + grey palette
  - Generous whitespace, no infographic flourishes
  - JAMA/Nature-website-style: hero → abstract → findings → methods/data/manuscript
  - WCAG 2.2 AA: semantic landmarks, ARIA labels, focus rings, 4.5:1 contrast,
    keyboard navigation, skip-link
  - Tailwind via CDN, Plotly via CDN — no build step required

The script:
  1. Builds the site HTML into a temporary directory.
  2. Pushes the directory to the `gh-pages` branch via git worktree.
  3. Leaves `main` untouched.

Usage:
  python scripts/build_site.py            # build + push gh-pages
  python scripts/build_site.py --dry-run  # build only, write to site-build/
"""
from __future__ import annotations
import argparse
import shutil
import subprocess
import sys
from pathlib import Path

import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots

ROOT = Path(__file__).resolve().parents[1]
TAB = ROOT / "outputs" / "tables"
FIG = ROOT / "outputs" / "figures"

OK = {
    "k": "#000000", "o": "#E69F00", "s": "#56B4E9", "g": "#009E73",
    "y": "#F0E442", "b": "#0072B2", "v": "#D55E00", "p": "#CC79A7",
}

PLOTLY_LAYOUT = dict(
    font=dict(family="Inter, system-ui, -apple-system, sans-serif",
              size=12, color="#1f2937"),
    paper_bgcolor="rgba(0,0,0,0)",
    plot_bgcolor="#fafbfc",
    margin=dict(l=70, r=20, t=50, b=50),
    height=380,
    title_font=dict(size=14, family="Inter", color="#0f172a"),
    legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="right", x=1),
)


def rd(name: str) -> pd.DataFrame | None:
    p = TAB / name
    return pd.read_csv(p) if p.exists() else None


# -----------------------------------------------------------------------------
# Site components
# -----------------------------------------------------------------------------
def html_head(title: str, description: str) -> str:
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{title}</title>
  <meta name="description" content="{description}">
  <script src="https://cdn.tailwindcss.com"></script>
  <script src="https://cdn.plot.ly/plotly-2.27.0.min.js" charset="utf-8"></script>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Source+Serif+4:wght@400;500;600&display=swap" rel="stylesheet">
  <style>
    body {{ font-family: 'Inter', system-ui, -apple-system, sans-serif;
           color: #1f2937; background: #ffffff; }}
    h1, h2, h3 {{ font-family: 'Source Serif 4', Georgia, serif;
                 color: #0f172a; letter-spacing: -0.01em; }}
    .prose-narrow {{ max-width: 64ch; }}
    :focus-visible {{ outline: 3px solid #1e3a5f; outline-offset: 3px;
                      border-radius: 3px; }}
    .skip-link {{ position: absolute; top: -48px; left: 0;
                 background: #1e3a5f; color: #ffffff; padding: 10px 18px;
                 z-index: 100; font-weight: 500; }}
    .skip-link:focus {{ top: 0; }}
    /* Subtle scholarly link underline */
    a.scholar {{ color: #1e3a5f; text-decoration: underline;
                text-underline-offset: 3px; text-decoration-thickness: 1px;
                text-decoration-color: #94a3b8; }}
    a.scholar:hover {{ text-decoration-color: #1e3a5f; }}
  </style>
</head>
<body>
  <a href="#main" class="skip-link">Skip to main content</a>
"""


def header_html(active: str = "home") -> str:
    def link(name: str, label: str, href: str) -> str:
        active_cls = ("text-slate-900 border-slate-900"
                      if active == name else
                      "text-slate-600 hover:text-slate-900 border-transparent hover:border-slate-300")
        return (f'<a href="{href}" class="px-1 py-3 border-b-2 '
                f'{active_cls} transition-colors">{label}</a>')

    return f"""
  <header class="border-b border-slate-200 bg-white" role="banner">
    <div class="max-w-6xl mx-auto px-6 py-5 flex flex-wrap items-baseline gap-x-8 gap-y-2">
      <a href="index.html" class="text-lg font-semibold tracking-tight text-slate-900 hover:text-slate-700">
        Pacheco-Barrios &amp; Rolston · PPMI DBS-Pain
      </a>
      <span class="text-xs uppercase tracking-widest text-slate-500">
        in preparation · 2026
      </span>
    </div>
    <nav class="border-t border-slate-100 bg-white" role="navigation" aria-label="Primary">
      <div class="max-w-6xl mx-auto px-6 flex flex-wrap gap-x-8 text-sm font-medium">
        {link("home", "Overview", "index.html")}
        {link("results", "Results", "results.html")}
        {link("methods", "Methods", "methods.html")}
        {link("data", "Data &amp; Code", "data.html")}
        {link("manuscript", "Manuscript", "manuscript.html")}
      </div>
    </nav>
  </header>
"""


def footer_html() -> str:
    return """
  <footer class="border-t border-slate-200 mt-24 py-10 text-sm text-slate-600"
          role="contentinfo">
    <div class="max-w-6xl mx-auto px-6 grid sm:grid-cols-3 gap-6">
      <div>
        <div class="font-medium text-slate-900 mb-1">ppmi-dbs-pain</div>
        Pacheco-Barrios &amp; Rolston, 2026. Manuscript in preparation.
      </div>
      <div>
        <div class="font-medium text-slate-900 mb-1">Source</div>
        Code: <a class="scholar" href="https://github.com/nielspac177/ppmi-dbs-pain">GitHub</a>
        · DOI: <em>pending Zenodo</em>
      </div>
      <div>
        <div class="font-medium text-slate-900 mb-1">License</div>
        Code MIT · Figures CC-BY-4.0 · PPMI raw data not redistributed.
      </div>
    </div>
  </footer>
</body>
</html>
"""


# -----------------------------------------------------------------------------
# Page: index.html (overview / findings)
# -----------------------------------------------------------------------------
def page_index() -> str:
    return html_head(
        "Deep brain stimulation and pain trajectory in Parkinson disease",
        "Pacheco-Barrios &amp; Rolston, 2026 — target-trial-emulation matched longitudinal cohort in PPMI."
    ) + header_html("home") + """
  <main id="main" class="max-w-4xl mx-auto px-6 py-16" role="main">

    <article class="prose-narrow">
      <p class="text-xs uppercase tracking-widest text-slate-500 mb-3">Research summary</p>
      <h1 class="text-4xl sm:text-5xl font-semibold leading-tight mb-6">
        Deep brain stimulation, pain trajectory, and the symptom architecture of Parkinson disease.
      </h1>
      <p class="text-lg text-slate-700 leading-relaxed mb-3">
        A target-trial-emulation matched longitudinal analysis of the
        Parkinson&rsquo;s Progression Markers Initiative cohort
        (n&nbsp;=&nbsp;1,484; 105 DBS, 1,379 Never-DBS).
      </p>
      <p class="text-sm text-slate-500">
        Pacheco-Barrios&nbsp;N, &hellip;, Rolston&nbsp;JD. <em>In preparation, 2026.</em>
        Target journal: <em>JAMA Neurology</em> / <em>Lancet Neurology</em>.
      </p>
    </article>

    <section class="mt-16" aria-labelledby="abstract-heading">
      <h2 id="abstract-heading" class="text-2xl font-semibold mb-5">Abstract</h2>
      <div class="prose-narrow text-slate-700 leading-relaxed text-[15px] space-y-4">
        <p><strong>Importance.</strong> Deep brain stimulation (DBS) is widely used for advanced Parkinson disease, but its long-term effects on non-motor symptoms&mdash;particularly pain&mdash;have not been formally evaluated in matched longitudinal cohorts.</p>
        <p><strong>Objective.</strong> To test non-inferiority of DBS on the 4-year trajectory of self-reported pain, and to explore three secondary questions about symptom architecture, pain&ndash;motor coupling, and genetic/biomarker modification.</p>
        <p><strong>Design.</strong> Target-trial-emulation matched longitudinal analysis of the PPMI Curated Data Cut (November 2024). Primary estimator: inverse-probability-of-censoring-weighted (IPCW) Welch contrast. Sensitivity: propensity-score-matched cohort. Causal contrast evaluated by two one-sided tests (TOST) across a margin grid.</p>
        <p><strong>Results.</strong> IPCW-weighted &Delta; = &minus;0.053 MDS-UPDRS-I points (95% CI &minus;0.293, +0.187). Non-inferiority concluded at every pre-specified margin: TOST&nbsp;P&nbsp;&lt;&nbsp;.001 at &plusmn;1, P&nbsp;&lt;&nbsp;10&#8315;&#8312; at &plusmn;0.75, P&nbsp;&lt;&nbsp;10&#8315;&#8308; at &plusmn;0.5, and P&nbsp;=&nbsp;.009 at &plusmn;0.3. Sequential-trial-emulation sensitivity (duration-matched) reinforced the result. Hypothesis-generating secondary signals were directionally consistent with pain-symptom-architecture reshaping under stimulation (pre-specified late-post Network Comparison Test uncorrected P&nbsp;=&nbsp;.050; Holm P&nbsp;=&nbsp;.150 as sensitivity), with directionally attenuated within-patient pain&ndash;motor coupling and a uniformly null multi-mediator analysis arguing against pharmacological, disease-progression, affective, autonomic, sleep, or motor mediation.</p>
        <p><strong>Conclusions.</strong> DBS was non-inferior on the 4-year pain trajectory in PD across margins down to &plusmn;0.3 MDS-UPDRS-I points. Directional, hypothesis-generating signals support a cautious reframing of DBS toward a symptom-architecture-modulating therapy, pending prospective replication.</p>
      </div>
    </section>

    <section class="mt-16" aria-labelledby="key-numbers-heading">
      <h2 id="key-numbers-heading" class="text-2xl font-semibold mb-6">Key numbers</h2>
      <dl class="grid sm:grid-cols-2 gap-x-10 gap-y-6 text-[15px]">
        <div class="border-l-2 border-slate-300 pl-5">
          <dt class="text-slate-500 text-sm mb-1">IPCW-weighted &Delta; Pain</dt>
          <dd class="text-2xl font-semibold text-slate-900 tabular-nums">&minus;0.053</dd>
          <dd class="text-slate-600 text-sm">95% CI &minus;0.293, +0.187 (DBS &minus; Never-DBS, MDS-UPDRS-I points)</dd>
        </div>
        <div class="border-l-2 border-slate-300 pl-5">
          <dt class="text-slate-500 text-sm mb-1">Tightest TOST non-inferiority</dt>
          <dd class="text-2xl font-semibold text-slate-900 tabular-nums">&plusmn;0.3 pt</dd>
          <dd class="text-slate-600 text-sm">P&nbsp;=&nbsp;.009 (concluded at every margin from &plusmn;1 down to &plusmn;0.3)</dd>
        </div>
        <div class="border-l-2 border-slate-300 pl-5">
          <dt class="text-slate-500 text-sm mb-1">Pre-specified late-post NCT</dt>
          <dd class="text-2xl font-semibold text-slate-900 tabular-nums">P&nbsp;=&nbsp;.050</dd>
          <dd class="text-slate-600 text-sm">Uncorrected; Holm P&nbsp;=&nbsp;.150 across 3 windows (hypothesis-generating)</dd>
        </div>
        <div class="border-l-2 border-slate-300 pl-5">
          <dt class="text-slate-500 text-sm mb-1">Pain&ndash;motor &Delta;&rho; (matched)</dt>
          <dd class="text-2xl font-semibold text-slate-900 tabular-nums">&minus;0.16</dd>
          <dd class="text-slate-600 text-sm">95% CI &minus;0.60, +0.29; bootstrap power for &Delta;&rho;&nbsp;=&nbsp;&minus;0.25 &asymp; 22%</dd>
        </div>
        <div class="border-l-2 border-slate-300 pl-5">
          <dt class="text-slate-500 text-sm mb-1">Mediators tested (all null)</dt>
          <dd class="text-2xl font-semibold text-slate-900 tabular-nums">6</dd>
          <dd class="text-slate-600 text-sm">LEDD, NHY, GDS, SCOPA, ESS, UPDRS-III &mdash; all ACME P&nbsp;&ge;&nbsp;.15</dd>
        </div>
        <div class="border-l-2 border-slate-300 pl-5">
          <dt class="text-slate-500 text-sm mb-1">Propensity-model c-statistic</dt>
          <dd class="text-2xl font-semibold text-slate-900 tabular-nums">0.885</dd>
          <dd class="text-slate-600 text-sm">Excellent discrimination on 7 covariates</dd>
        </div>
      </dl>
    </section>

    <section class="mt-16" aria-labelledby="contribution-heading">
      <h2 id="contribution-heading" class="text-2xl font-semibold mb-4">Contribution</h2>
      <div class="prose-narrow text-slate-700 leading-relaxed text-[15px] space-y-3">
        <p>To our knowledge this is the first matched longitudinal observational analysis to test deep brain stimulation non-inferiority on a non-motor Parkinson endpoint across a margin grid, with explicit immortal-time correction via sequential-trial emulation and inverse-probability-of-censoring weighting. The robustness layer comprises sixteen pre-specified and post-hoc analyses; all conclusions are concordant across them.</p>
        <p>Beyond the safety conclusion, three directional, hypothesis-generating mechanistic signals &mdash; a borderline late-post Network Comparison Test, a directionally lower within-patient pain&ndash;motor coupling, and a uniformly null multi-mediator analysis &mdash; are jointly compatible with a cautious reframing of DBS toward a symptom-architecture-modulating therapy. None is individually conclusive in this cohort.</p>
      </div>
    </section>

    <section class="mt-16 border-t border-slate-200 pt-10" aria-label="Next reading">
      <ul class="grid sm:grid-cols-3 gap-6 text-[15px]">
        <li>
          <a href="results.html" class="scholar font-medium">Interactive results &rarr;</a>
          <p class="text-slate-600 text-sm mt-1">Sixteen robustness analyses, each with effect estimate, 95% CI, and short interpretation.</p>
        </li>
        <li>
          <a href="methods.html" class="scholar font-medium">Methods &rarr;</a>
          <p class="text-slate-600 text-sm mt-1">Target trial emulation, IPCW, sequential-trial emulation, GLASSO, multi-mediator analysis.</p>
        </li>
        <li>
          <a href="data.html" class="scholar font-medium">Data &amp; code &rarr;</a>
          <p class="text-slate-600 text-sm mt-1">PPMI access, synthetic-data fixture, Docker, Codespaces, reproduction instructions.</p>
        </li>
      </ul>
    </section>

  </main>
""" + footer_html()


# -----------------------------------------------------------------------------
# Page: results.html (the dashboard panels in clean academic style)
# -----------------------------------------------------------------------------
def build_results_panels() -> list[tuple[str, str, str, go.Figure]]:
    panels: list[tuple[str, str, str, go.Figure]] = []

    s12 = rd("12_tost_margin_grid.csv")
    if s12 is not None:
        f = go.Figure()
        f.add_trace(go.Scatter(
            x=s12["margin"], y=s12["tost_p_max"],
            mode="lines+markers", line=dict(color=OK["b"], width=2.5),
            marker=dict(size=10, color=OK["b"], line=dict(color="#0f172a", width=1)),
            hovertemplate="margin ±%{x}<br>TOST P = %{y:.3g}<extra></extra>",
        ))
        f.add_hline(y=0.05, line_dash="dot", line_color="#94a3b8")
        f.update_layout(
            title="Non-inferiority survives every tested margin",
            xaxis_title="Non-inferiority margin (MDS-UPDRS-I points)",
            yaxis_title="TOST P_max (log scale)",
            yaxis_type="log",
            **PLOTLY_LAYOUT,
        )
        panels.append((
            "tost-margin",
            "Pain non-inferiority across margins",
            "Non-inferiority concluded at every margin tested, including the tightest meaningful margin of ±0.3 MDS-UPDRS-I points (TOST P = .009).",
            f,
        ))

    s10 = rd("10_ipcw_results.csv")
    if s10 is not None:
        f = go.Figure()
        f.add_trace(go.Bar(
            x=s10["estimator"], y=s10["diff"],
            marker_color=[OK["s"], OK["b"]],
            marker_line=dict(color="#0f172a", width=1),
            error_y=dict(type="data",
                         array=s10["ci_hi"] - s10["diff"],
                         arrayminus=s10["diff"] - s10["ci_lo"]),
            text=[f"Δ = {v:+.3f}" for v in s10["diff"]],
            textposition="outside", showlegend=False,
        ))
        f.add_hline(y=0, line_dash="dot", line_color="#94a3b8")
        f.update_layout(
            title="Effect estimate robust to informative-dropout correction",
            yaxis_title="Δ Pain (DBS − Never-DBS)",
            **PLOTLY_LAYOUT,
        )
        panels.append((
            "ipcw",
            "IPCW vs unweighted primary estimate",
            "Inverse-probability-of-censoring weights handle the asymmetric dropout (62 % Never-DBS, 35 % DBS) and move the point estimate marginally without altering the non-inferiority conclusion.",
            f,
        ))

    s15 = rd("15_multi_mediator.csv")
    if s15 is not None:
        ordered = s15.sort_values("ACME").reset_index(drop=True)
        f = go.Figure()
        f.add_trace(go.Scatter(
            x=ordered["ACME"], y=ordered["mediator"],
            mode="markers",
            marker=dict(size=12, color=OK["o"], line=dict(color="#0f172a", width=1)),
            error_x=dict(type="data",
                         array=ordered["ACME_hi"] - ordered["ACME"],
                         arrayminus=ordered["ACME"] - ordered["ACME_lo"]),
            hovertemplate="<b>%{y}</b><br>ACME = %{x:.3f}<br>P = %{customdata[0]:.3f}<extra></extra>",
            customdata=ordered[["ACME_p"]].values,
        ))
        f.add_vline(x=0, line_dash="dot", line_color="#94a3b8")
        f.update_layout(
            title="No single candidate mediator transmits the effect",
            xaxis_title="Average causal mediation effect (pain points)",
            **PLOTLY_LAYOUT,
        )
        panels.append((
            "mediators",
            "Multi-mediator analysis",
            "Six candidate single mediators (LEDD, Hoehn & Yahr, GDS, SCOPA, ESS, UPDRS-III) are individually null — collectively arguing against pharmacological, disease-progression, affective, autonomic, sleep, or motor mediation.",
            f,
        ))

    s4 = rd("04_nct_global.csv")
    if s4 is not None:
        f = go.Figure()
        f.add_trace(go.Bar(name="DBS", x=s4["window"], y=s4["global_strength_dbs"],
                           marker_color=OK["v"], marker_line=dict(color="#0f172a", width=1)))
        f.add_trace(go.Bar(name="Never-DBS", x=s4["window"], y=s4["global_strength_neverdbs"],
                           marker_color=OK["b"], marker_line=dict(color="#0f172a", width=1)))
        for _, row in s4.iterrows():
            f.add_annotation(
                x=row["window"],
                y=max(row["global_strength_dbs"], row["global_strength_neverdbs"]) + 0.5,
                text=f"max-edge P = {row['network_invariance_pval']:.3f}",
                showarrow=False, font=dict(size=11, color="#1f2937"))
        f.update_layout(
            title="Network Comparison Test — directional but inconclusive",
            yaxis_title="Global GLASSO network strength",
            barmode="group", **PLOTLY_LAYOUT,
        )
        panels.append((
            "nct",
            "Symptom-network reshaping (hypothesis-generating)",
            "At the pre-specified late-post window the maximum-edge-strength permutation test reaches uncorrected P = 0.050. Holm-adjusted across the three windows P = 0.150. Framed as hypothesis-generating; replication in target-aware cohorts warranted.",
            f,
        ))

    s13 = rd("13_cce_primary.csv")
    if s13 is not None:
        f = go.Figure()
        f.add_trace(go.Bar(
            x=s13["estimator"], y=s13["diff"],
            marker_color=OK["g"], marker_line=dict(color="#0f172a", width=1),
            error_y=dict(type="data",
                         array=s13["ci_hi"] - s13["diff"],
                         arrayminus=s13["diff"] - s13["ci_lo"]),
            text=[f"Δ = {v:+.3f}" for v in s13["diff"]],
            textposition="outside", showlegend=False,
        ))
        f.add_hline(y=0, line_dash="dot", line_color="#94a3b8")
        f.update_layout(
            title="Sequential-trial emulation reinforces the primary",
            yaxis_title="Δ Pain (DBS − Never-DBS), duration-matched",
            **PLOTLY_LAYOUT,
        )
        panels.append((
            "cce",
            "Immortal-time correction (sequential-trial emulation)",
            "DBS recipients match Never-DBS controls within ±1 year of disease duration at anchor. Non-inferiority concluded under TOST ±0.5 (P = .004).",
            f,
        ))

    return panels


def page_results() -> str:
    panels = build_results_panels()
    body_parts = [html_head(
        "Results — ppmi-dbs-pain",
        "Interactive results dashboard: 16 robustness analyses for the PPMI DBS-pain study."
    ) + header_html("results") + """
  <main id="main" class="max-w-5xl mx-auto px-6 py-12" role="main">
    <header class="mb-12">
      <p class="text-xs uppercase tracking-widest text-slate-500 mb-3">Results</p>
      <h1 class="text-3xl font-semibold mb-3">Robustness analyses, interactively.</h1>
      <p class="prose-narrow text-slate-700 leading-relaxed">
        Sixteen pre-specified and post-hoc analyses; the five most consequential are summarised here.
        For the complete set including underlying CSVs and figure files, see
        <a class="scholar" href="https://github.com/nielspac177/ppmi-dbs-pain/tree/main/outputs">
          outputs/ on GitHub</a>.
      </p>
    </header>
"""]
    for tag, title, caption, fig in panels:
        body_parts.append(f"""
    <section id="{tag}" class="border-t border-slate-200 pt-10 mt-12"
             aria-labelledby="{tag}-h">
      <h2 id="{tag}-h" class="text-xl font-semibold mb-2">{title}</h2>
      <p class="prose-narrow text-slate-600 text-[15px] leading-relaxed mb-6">{caption}</p>
      <div role="img" aria-label="{title} chart">
        {fig.to_html(include_plotlyjs=False, full_html=False)}
      </div>
    </section>
""")
    body_parts.append("""
  </main>
""" + footer_html())
    return "".join(body_parts)


# -----------------------------------------------------------------------------
# Page: methods.html
# -----------------------------------------------------------------------------
def page_methods() -> str:
    return html_head(
        "Methods — ppmi-dbs-pain",
        "Methods overview: target trial emulation, IPCW, sequential-trial emulation, GLASSO, multi-mediator."
    ) + header_html("methods") + """
  <main id="main" class="max-w-3xl mx-auto px-6 py-12" role="main">
    <p class="text-xs uppercase tracking-widest text-slate-500 mb-3">Methods</p>
    <h1 class="text-3xl font-semibold mb-8">How the analyses were performed.</h1>

    <article class="prose-narrow text-slate-700 leading-relaxed text-[15px] space-y-6">

      <h2 class="text-xl font-semibold text-slate-900 mt-10">Cohort and exposure</h2>
      <p>PPMI Curated Data Cut, November 2024 (clinicaltrials.gov NCT01141023). Eligibility required idiopathic Parkinson disease, absence of a known monogenic cause, and at least one MDS-UPDRS Part I item 9 (NP1PAIN) observation. The analytic cohort comprised 1,484 patients (105 DBS recipients, 1,379 Never-DBS). PPMI does not record the stimulation target; the cohort is treated as DBS-agnostic and is expected to include both subthalamic and pallidal recipients.</p>

      <h2 class="text-xl font-semibold text-slate-900 mt-10">Target trial emulation</h2>
      <p>The analysis emulates a hypothetical trial in which eligible idiopathic-PD patients are randomised to receive DBS within a follow-up window or to continue medical therapy, with per-protocol average treatment effect as the causal contrast. Three Never-DBS anchor schemes are compared; a duration-matched sequential-trial emulation provides an explicit immortal-time correction.</p>

      <h2 class="text-xl font-semibold text-slate-900 mt-10">Outcomes</h2>
      <p>The primary outcome is the change in NP1PAIN at the +6 to +18 month landmark window relative to the &minus;24 to 0 month baseline. Three negative-control outcomes (NP1HALL hallucinations; NP1URN urinary; NP1COG cognition) calibrate the pipeline; MDS-UPDRS Part III change is the pre-specified positive control.</p>

      <h2 class="text-xl font-semibold text-slate-900 mt-10">Statistical analysis</h2>
      <p>The primary estimator is inverse-probability-of-censoring-weighted (IPCW) Welch contrast, with the censoring model accommodating asymmetric dropout (61.9 % Never-DBS vs 34.9 % DBS at the post-window). Non-inferiority is evaluated by two one-sided tests across a margin grid of ±1.0, ±0.75, ±0.5, and ±0.3 MDS-UPDRS-I points. A 1:2 propensity-matched cohort (caliper 0.02, c-statistic 0.885) provides the secondary sensitivity. Secondary analyses include random-intercept linear mixed-effects models, generalised estimating equations under exchangeable and AR(1) working correlations, Fine-Gray competing-risk subdistribution hazards for the time to NP1PAIN ≥ 2 (with dropout as competing event), graphical-LASSO partial-correlation networks over 15 non-motor variables tested by Network Comparison Test (Holm-adjusted across three windows), and per-mediator analyses for six candidate single mediators.</p>

      <h2 class="text-xl font-semibold text-slate-900 mt-10">Robustness</h2>
      <p>Sixteen pre-specified and post-hoc analyses interrogate the conclusions: negative controls, anchor sensitivity, E-values, missing-not-at-random tipping-point, network comparison with bootstrap stability, profile-likelihood and Firth-penalized confidence intervals, cluster-robust standard errors, Fine-Gray competing-risk modelling, bootstrap distribution for genetic interactions under flat priors, IPCW, TOST margin grid, sequential-trial emulation, independent-complement Δρ replication, multi-mediator analysis, and demographics audit. See <a class="scholar" href="https://github.com/nielspac177/ppmi-dbs-pain/blob/main/MANIFEST.md">MANIFEST.md</a> for the labelled provenance of every script.</p>

      <h2 class="text-xl font-semibold text-slate-900 mt-10">Causal assumptions</h2>
      <p>The directed acyclic graph specifies a minimal adjustment set of age, sex, disease duration, MDS-UPDRS Part III, Hoehn &amp; Yahr stage, levodopa-equivalent daily dose, body-mass index, baseline NP1PAIN, and depression/anxiety composite. The dagitty source is at <a class="scholar" href="https://github.com/nielspac177/ppmi-dbs-pain/blob/main/outputs/aggregated/causal_dag.txt">outputs/aggregated/causal_dag.txt</a>.</p>

      <h2 class="text-xl font-semibold text-slate-900 mt-10">Reproducibility</h2>
      <p>The complete analysis code, a synthetic PPMI-shaped data fixture, a Docker container, a GitHub Codespaces configuration, a <code class="bg-slate-100 px-1.5 py-0.5 rounded text-xs">Makefile</code>-driven workflow, eight Architecture Decision Records, and unit tests are available at <a class="scholar" href="https://github.com/nielspac177/ppmi-dbs-pain">github.com/nielspac177/ppmi-dbs-pain</a>. Raw PPMI data are not redistributed; access instructions are at <a class="scholar" href="https://www.ppmi-info.org/access-data-specimens/download-data">ppmi-info.org</a>.</p>

    </article>
  </main>
""" + footer_html()


# -----------------------------------------------------------------------------
# Page: data.html — data access + reproducibility
# -----------------------------------------------------------------------------
def page_data() -> str:
    return html_head(
        "Data &amp; Code — ppmi-dbs-pain",
        "Access PPMI data, reproduce the analyses end-to-end via Docker or Codespaces."
    ) + header_html("data") + """
  <main id="main" class="max-w-3xl mx-auto px-6 py-12" role="main">
    <p class="text-xs uppercase tracking-widest text-slate-500 mb-3">Data &amp; code</p>
    <h1 class="text-3xl font-semibold mb-8">Reproducing the analyses.</h1>

    <article class="prose-narrow text-slate-700 leading-relaxed text-[15px] space-y-6">

      <h2 class="text-xl font-semibold text-slate-900 mt-10">Raw PPMI data</h2>
      <p>Raw participant-level PPMI data are not redistributed in this repository under the PPMI Data Use Agreement. To reproduce the manuscript numbers exactly, apply for PPMI access at <a class="scholar" href="https://www.ppmi-info.org/access-data-specimens/download-data">ppmi-info.org/access-data-specimens/download-data</a>, download the November 2024 Curated Data Cut, and configure your local <code class="bg-slate-100 px-1.5 py-0.5 rounded text-xs">config.yml</code>.</p>

      <h2 class="text-xl font-semibold text-slate-900 mt-10">Synthetic data fixture</h2>
      <p>A deterministic, seeded synthetic PPMI-shaped fixture is bundled with the repository so reviewers can exercise the pipeline end-to-end without applying to PPMI. The fixture preserves variable names, arm proportions, and approximate marginal distributions; it does <em>not</em> preserve joint distributions or any treatment effect, and is clearly labelled FAKE DATA. See <a class="scholar" href="https://github.com/nielspac177/ppmi-dbs-pain/tree/main/data-synth">data-synth/</a>.</p>

      <h2 class="text-xl font-semibold text-slate-900 mt-10">One-click reproduction</h2>
      <p>The fastest path is GitHub Codespaces. From the <a class="scholar" href="https://github.com/nielspac177/ppmi-dbs-pain">repository page</a>, click <em>Code &rarr; Codespaces &rarr; Create</em>. The devcontainer pre-installs R 4.5.1, all CRAN packages, Python 3.13, and Quarto. After launch:</p>
      <pre class="bg-slate-50 border border-slate-200 rounded p-4 text-xs leading-snug overflow-x-auto"><code>make env          # restore renv + Python dependencies
make synth-data   # regenerate the synthetic fixture
make all          # primary analyses + 16 robustness + figures</code></pre>

      <h2 class="text-xl font-semibold text-slate-900 mt-10">Local reproduction</h2>
      <p>For local reproduction without GitHub Codespaces, a Docker image and a <code class="bg-slate-100 px-1.5 py-0.5 rounded text-xs">.devcontainer</code> configuration are provided. See <a class="scholar" href="https://github.com/nielspac177/ppmi-dbs-pain/blob/main/REPRODUCE.md">REPRODUCE.md</a> for step-by-step instructions, expected runtimes, and troubleshooting notes.</p>

      <h2 class="text-xl font-semibold text-slate-900 mt-10">Provenance and reporting</h2>
      <p>Every script is labelled in <a class="scholar" href="https://github.com/nielspac177/ppmi-dbs-pain/blob/main/MANIFEST.md">MANIFEST.md</a> as primary, secondary, exploratory, robustness, infrastructure, or deprecated. Pre-specified versus post-hoc analyses are documented in <a class="scholar" href="https://github.com/nielspac177/ppmi-dbs-pain/blob/main/PRE_REGISTRATION.md">PRE_REGISTRATION.md</a>. Irreversible technical and scientific decisions are documented as Architecture Decision Records in <a class="scholar" href="https://github.com/nielspac177/ppmi-dbs-pain/tree/main/adr">adr/</a>.</p>

    </article>
  </main>
""" + footer_html()


# -----------------------------------------------------------------------------
# Page: manuscript.html — link to the markdown manuscript on GitHub
# -----------------------------------------------------------------------------
def page_manuscript() -> str:
    return html_head(
        "Manuscript — ppmi-dbs-pain",
        "Read the manuscript draft, internal peer review, and response to reviewers."
    ) + header_html("manuscript") + """
  <main id="main" class="max-w-3xl mx-auto px-6 py-12" role="main">
    <p class="text-xs uppercase tracking-widest text-slate-500 mb-3">Manuscript</p>
    <h1 class="text-3xl font-semibold mb-8">Draft and review trail.</h1>

    <article class="prose-narrow text-slate-700 leading-relaxed text-[15px] space-y-6">

      <p>The manuscript is under preparation. The current draft and the surrounding review trail are tracked openly on the repository.</p>

      <ul class="space-y-3 mt-6">
        <li>
          <a class="scholar font-medium" href="https://github.com/nielspac177/ppmi-dbs-pain/blob/main/manuscript/MANUSCRIPT_DRAFT.md">Manuscript draft</a>
          <span class="text-slate-500 text-sm">— current journal-ready prose (~3,200 words main text).</span>
        </li>
        <li>
          <a class="scholar font-medium" href="https://github.com/nielspac177/ppmi-dbs-pain/blob/main/manuscript/PEER_REVIEW.md">Internal peer review</a>
          <span class="text-slate-500 text-sm">— JAMA-Neurology-style structured review (10 major + 13 minor comments).</span>
        </li>
        <li>
          <a class="scholar font-medium" href="https://github.com/nielspac177/ppmi-dbs-pain/blob/main/manuscript/RESPONSE_TO_REVIEWERS.md">Response to reviewers</a>
          <span class="text-slate-500 text-sm">— tracker for each major comment with status and remedy.</span>
        </li>
        <li>
          <a class="scholar font-medium" href="https://github.com/nielspac177/ppmi-dbs-pain/blob/main/manuscript/FUTURE_PAPERS.md">Future papers</a>
          <span class="text-slate-500 text-sm">— hypothesis bank for the four planned non-motor follow-ups (sleep, autonomic, cognition, pain phenotype).</span>
        </li>
      </ul>

      <p class="mt-10 text-slate-600">The manuscript will be deposited as a preprint upon submission and the Zenodo DOI will appear here.</p>

    </article>
  </main>
""" + footer_html()


# -----------------------------------------------------------------------------
# Build + push
# -----------------------------------------------------------------------------
def build(out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "index.html").write_text(page_index(), encoding="utf-8")
    (out_dir / "results.html").write_text(page_results(), encoding="utf-8")
    (out_dir / "methods.html").write_text(page_methods(), encoding="utf-8")
    (out_dir / "data.html").write_text(page_data(), encoding="utf-8")
    (out_dir / "manuscript.html").write_text(page_manuscript(), encoding="utf-8")
    (out_dir / ".nojekyll").write_text("", encoding="utf-8")
    # Carry over the causal DAG + callgraph + Sankey PNGs/PDFs for download links
    assets = out_dir / "assets"
    assets.mkdir(exist_ok=True)
    for fname in ["Figure_causal_DAG.png", "Figure_causal_DAG.pdf",
                  "Figure_callgraph.png", "Figure_callgraph.pdf",
                  "Figure_sankey.png", "Figure_sankey.pdf"]:
        src = FIG / fname
        if src.exists():
            shutil.copy(src, assets / fname)


def push_gh_pages(build_dir: Path) -> None:
    """Push build_dir contents to gh-pages branch via git worktree."""
    git = lambda *a: subprocess.run(["git", *a], cwd=ROOT, check=True)
    git("fetch", "origin")
    # Check if gh-pages exists remotely
    res = subprocess.run(
        ["git", "ls-remote", "--heads", "origin", "gh-pages"],
        cwd=ROOT, capture_output=True, text=True
    )
    remote_exists = bool(res.stdout.strip())

    worktree = ROOT / ".gh-pages-worktree"
    if worktree.exists():
        subprocess.run(["git", "worktree", "remove", "--force", str(worktree)],
                       cwd=ROOT, check=False)

    if remote_exists:
        git("worktree", "add", str(worktree), "gh-pages")
    else:
        # Create orphan gh-pages locally
        subprocess.run(["git", "worktree", "add", "--orphan",
                        "-b", "gh-pages", str(worktree)], cwd=ROOT, check=True)

    # Clear worktree, copy build_dir contents in
    for entry in worktree.iterdir():
        if entry.name == ".git":
            continue
        if entry.is_dir():
            shutil.rmtree(entry)
        else:
            entry.unlink()
    for entry in build_dir.iterdir():
        target = worktree / entry.name
        if entry.is_dir():
            shutil.copytree(entry, target)
        else:
            shutil.copy(entry, target)

    subprocess.run(["git", "add", "-A"], cwd=worktree, check=True)
    subprocess.run(["git", "commit", "-m", "site: rebuild"],
                   cwd=worktree, check=False)
    subprocess.run(["git", "push", "origin", "gh-pages"],
                   cwd=worktree, check=True)
    subprocess.run(["git", "worktree", "remove", "--force", str(worktree)],
                   cwd=ROOT, check=False)


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--dry-run", action="store_true",
                   help="Build into site-build/ but do not push gh-pages.")
    args = p.parse_args()

    if args.dry_run:
        out = ROOT / "site-build"
        if out.exists():
            shutil.rmtree(out)
        build(out)
        print(f"[OK] site built at {out}/ (dry-run; not pushed)")
        return 0

    tmp = ROOT / ".site-tmp"
    if tmp.exists():
        shutil.rmtree(tmp)
    build(tmp)
    push_gh_pages(tmp)
    shutil.rmtree(tmp)
    print("[OK] site pushed to gh-pages")
    return 0


if __name__ == "__main__":
    sys.exit(main())
