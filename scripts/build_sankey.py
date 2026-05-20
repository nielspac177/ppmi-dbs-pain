"""
build_sankey.py
------------------------------------------------------------
Sankey flowchart describing the cohort flow + analysis tiers.

Two Sankey panels:
  Panel A — Cohort flow (PPMI Curated -> idiopathic PD -> matched cohort -> analytic outcomes)
  Panel B — Analysis flow (tier -> script -> conclusion)

Saves PNG + PDF + an interactive HTML using plotly.
"""
from pathlib import Path
import matplotlib.pyplot as plt
import numpy as np

try:
    import plotly.graph_objects as go
except ImportError:
    go = None

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "outputs" / "figures"
OUT.mkdir(parents=True, exist_ok=True)

# --------------------------------------------------------------
# Panel A — Cohort flow Sankey
# --------------------------------------------------------------
# Labels
labels_A = [
    "PPMI Curated\nNov 2024",          # 0
    "Idiopathic PD",                   # 1
    "Monogenic variants (excluded)",   # 2
    "≥1 NP1PAIN obs",                  # 3
    "Missing NP1PAIN (excluded)",      # 4
    "DBS arm",                         # 5
    "Never-DBS arm",                   # 6
    "Matched cohort\n1:2 PSM",         # 7
    "Full cohort\n(IPW)",              # 8
    "Primary TOST",                    # 9
    "GLASSO network",                  # 10
    "Pain-motor coupling",             # 11
    "Genetics/biomarker",              # 12
    "Sprints 1-9\n(robustness)",       # 13
]
source_A = [0, 0, 1, 1, 3, 3,
            5, 5, 6, 6,
            7, 7, 7, 7,
            8, 8, 8, 8,
            7, 8]
target_A = [1, 2, 3, 4, 5, 6,
            7, 8, 7, 8,
            9, 10, 11, 12,
            9, 10, 11, 12,
            13, 13]
value_A  = [1924, 440, 1484, 0,
            105, 1379,
            64, 105, 106, 1379,
            64, 64, 64, 64,
            105, 105, 105, 105,
            170, 1484]

# --------------------------------------------------------------
# Panel B — Analysis flow Sankey
# --------------------------------------------------------------
labels_B = [
    "PPMI Cohort\nn = 1,484",              # 0
    "Primary",                              # 1
    "Secondary",                            # 2
    "Sensitivity (PSM)",                    # 3
    "Exploratory",                          # 4
    "TOST landmark",                        # 5
    "LMM Pre/Post",                         # 6
    "GEE Table 3",                          # 7
    "Sprint01 neg controls",                # 8
    "Sprint02 anchor sweep",                # 9
    "Sprint03 E-value + MNAR",              # 10
    "Sprint04 NCT + bootnet",               # 11
    "Sprint05 boot Δρ + Brant + Firth",     # 12
    "Sprint06 CR2 + AR(1)",                 # 13
    "Sprint07 PSM diagnostics",             # 14
    "Sprint08 Fine-Gray",                   # 15
    "Sprint09 ΔLEDD mediation",             # 16
    "Conclusion: non-inferiority",          # 17
    "Conclusion: network reorganization",   # 18
    "Conclusion: pain-motor decoupling",    # 19
    "Conclusion: no genetic moderation",    # 20
]
source_B = [0, 0, 0, 0,
            1, 1, 1,
            2, 4,
            3, 3, 3, 3, 3, 3, 3, 3, 3,
            5, 6, 7,                                      # primary -> conclusions
            8, 9, 10, 13, 14, 16,                         # robustness -> NI
            11, 11,                                       # NCT -> two conclusions
            12, 16, 15]
target_B = [1, 2, 3, 4,
            5, 6, 7,
            11, 12,
            8, 9, 10, 11, 12, 13, 14, 15, 16,
            17, 17, 17,
            17, 17, 17, 17, 17, 17,
            18, 19,
            19, 19, 18]
value_B  = [3, 3, 9, 2,
            1, 1, 1,
            1, 1,
            1, 1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1,
            1, 1, 1, 1, 1, 1,
            1, 1,
            1, 1, 1]

# --------------------------------------------------------------
# Plotly interactive HTML
# --------------------------------------------------------------
if go is not None:
    fig = go.Figure()
    fig.add_trace(go.Sankey(
        node=dict(label=labels_A, pad=20, thickness=18,
                  line=dict(color="black", width=0.5),
                  color=["#56B4E9"] * len(labels_A)),
        link=dict(source=source_A, target=target_A, value=value_A,
                  color="rgba(86,180,233,0.4)"),
        domain=dict(x=[0, 0.48], y=[0, 1]),
    ))
    fig.add_trace(go.Sankey(
        node=dict(label=labels_B, pad=20, thickness=18,
                  line=dict(color="black", width=0.5),
                  color=["#D55E00"] * len(labels_B)),
        link=dict(source=source_B, target=target_B, value=value_B,
                  color="rgba(213,94,0,0.35)"),
        domain=dict(x=[0.52, 1], y=[0, 1]),
    ))
    fig.update_layout(
        title_text=("Pain paper — cohort flow (left) and analysis flow (right)"),
        font=dict(size=10, family="Arial"),
        width=1500, height=750,
    )
    html_path = ROOT / "outputs" / "figures" / "Figure_sankey.html"
    fig.write_html(html_path, include_plotlyjs="cdn")
    print(f"[OK] interactive Sankey: {html_path}")
else:
    print("[skip] plotly not available — install plotly to render the interactive Sankey.")

# --------------------------------------------------------------
# Static PNG/PDF via matplotlib (fallback)
# --------------------------------------------------------------
# Matplotlib doesn't have a great Sankey; use a simple node-link diagram
# as a static substitute. The HTML is the primary deliverable.
fig, axes = plt.subplots(1, 2, figsize=(20, 9))
for ax, labels, src, tgt, val, title, colour in [
    (axes[0], labels_A, source_A, target_A, value_A,
     "Panel A — Cohort flow", "#56B4E9"),
    (axes[1], labels_B, source_B, target_B, value_B,
     "Panel B — Analysis flow", "#D55E00"),
]:
    # Simple text + arrow representation
    ax.set_xlim(0, 10)
    ax.set_ylim(0, len(labels) + 1)
    for i, lbl in enumerate(labels):
        y = len(labels) - i
        ax.text(0.2, y, lbl, fontsize=8.5,
                bbox=dict(facecolor=colour, alpha=0.35,
                          edgecolor="black", boxstyle="round,pad=0.3"),
                verticalalignment="center")
    for s, t, v in zip(src, tgt, val):
        ys = len(labels) - s
        yt = len(labels) - t
        ax.annotate("", xy=(7, yt), xytext=(3.5, ys),
                    arrowprops=dict(arrowstyle="->", color=colour,
                                    alpha=0.6, lw=max(0.5, np.log1p(v) / 6)))
    ax.set_title(title, fontsize=12, fontweight="bold")
    ax.axis("off")

plt.suptitle("Sankey flowchart — cohort + analysis flow",
             fontsize=14, fontweight="bold")
plt.tight_layout()
png_path = OUT / "Figure_sankey.png"
pdf_path = OUT / "Figure_sankey.pdf"
plt.savefig(png_path, dpi=200, bbox_inches="tight", facecolor="white")
plt.savefig(pdf_path, bbox_inches="tight", facecolor="white")
print(f"[OK] static Sankey: {png_path}")
print(f"[OK] static Sankey: {pdf_path}")
