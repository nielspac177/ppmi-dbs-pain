"""
Methods / study-design schematic for Pain_paper_v2.

Rows:
  Title    (extra spacing below)
  Row 1:   PPMI Curated Data Cut
  Row 2:   Analytic cohort (exclusions + arm counts)
  Row 3:   Anchor alignment (DBS vs Never-DBS)
  Row 4:   Time windows + mini-timeline strip
  Row 5:   Analysis tiers (Primary / Secondary / Sensitivity / Exploratory)
  Footer:  Acronym legend
"""
from matplotlib import patches
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch
import matplotlib.pyplot as plt

plt.rcParams.update({
    "font.family": "DejaVu Sans",
    "font.size":   10,
})

# ---- Palette (matches existing figures) --------------------------------
C_DBS      = "#CC6677"
C_CTRL     = "#332288"
C_NEUTRAL  = "#4E4E4E"
C_FILL     = "#F4F6F9"
C_STROKE   = "#333333"
C_PRIMARY  = "#1B998B"
C_SECOND   = "#3D5A80"
C_SENSIT   = "#8C6A3F"
C_EXPLOR   = "#9B5DE5"

fig = plt.figure(figsize=(11, 12.5))
ax = fig.add_axes([0, 0, 1, 1])
ax.set_xlim(0, 100)
ax.set_ylim(0, 100)
ax.axis("off")

def box(xc, yc, w, h, text, fill=C_FILL, stroke=C_STROKE,
        text_colour="#111111", fontsize=10, weight="normal"):
    p = FancyBboxPatch(
        (xc - w / 2, yc - h / 2), w, h,
        boxstyle="round,pad=0.4,rounding_size=0.8",
        linewidth=1.2, edgecolor=stroke, facecolor=fill,
    )
    ax.add_patch(p)
    ax.text(xc, yc, text, ha="center", va="center",
            fontsize=fontsize, color=text_colour, fontweight=weight,
            linespacing=1.35)

def arrow(x1, y1, x2, y2, colour=C_NEUTRAL):
    ax.add_patch(FancyArrowPatch(
        (x1, y1), (x2, y2),
        arrowstyle="-|>", mutation_scale=14,
        linewidth=1.1, color=colour,
    ))

# Title is rendered in the docx caption, not embedded in the image.

# ---------- Row 1: Data source ------------------------------------------
box(50, 91, 48, 5.2,
    "PPMI Curated Data Cut (November 2024)\n"
    "Idiopathic PD with \u22651 NP1PAIN observation",
    fill="#E7EDF5", fontsize=10.5, weight="bold")

arrow(50, 88, 50, 85.5)

# ---------- Row 2: Analytic cohort --------------------------------------
box(50, 81, 60, 7.5,
    "Analytic cohort  n = 1,484\n"
    "excluded: 440 monogenic variants; missing Pain score\n"
    "DBS arm  n = 105     |     Never-DBS arm  n = 1,379",
    fill=C_FILL, fontsize=10.5, weight="bold")

arrow(50, 77, 50, 74.5)

# ---------- Row 3: Anchor alignment (two branches) ----------------------
ax.text(50, 73, "Anchor alignment",
        ha="center", va="center", fontsize=10.8, fontweight="bold",
        color=C_NEUTRAL)

box(27, 66, 38, 9.5,
    "DBS  (n = 105)\n"
    "anchor = first DBS surgery date\n"
    "pre-anchor = Pre-DBS | post-anchor = Post-DBS",
    fill="#FBE9EB", stroke=C_DBS, fontsize=9.8)

box(73, 66, 38, 9.5,
    "Never-DBS  (n = 1,379)\n"
    "anchor = midpoint of own follow-up\n"
    "(symmetric pre / post; not a clinical event)",
    fill="#E8E6F2", stroke=C_CTRL, fontsize=9.8)

arrow(27, 61, 50, 57)
arrow(73, 61, 50, 57)

# ---------- Row 4: Time windows + mini-timeline -------------------------
box(50, 53, 82, 5.5,
    "Time windows (months relative to anchor)\n"
    "Pre-anchor baseline [\u221224, 0]   \u2022   Primary post window [+6, +18]   \u2022   Landmarks 6 / 12 / 18 / 24 / 36 / 48 \u00B1 6",
    fill=C_FILL, fontsize=10)

tl_y = 45
tl_x0, tl_x1 = 12, 88
ax.plot([tl_x0, tl_x1], [tl_y, tl_y], color=C_NEUTRAL,
        linewidth=1.0, zorder=2)

months = [-24, -12, 0, 6, 12, 18, 24, 36, 48]
def m2x(m):
    return tl_x0 + (m + 24) / 72 * (tl_x1 - tl_x0)
for m in months:
    x = m2x(m)
    ax.plot([x, x], [tl_y - 0.5, tl_y + 0.5],
            color=C_NEUTRAL, linewidth=1.0, zorder=2)
    ax.text(x, tl_y + 0.9, f"{m:+d}" if m else "0",
            ha="center", va="bottom", fontsize=8.5, color=C_NEUTRAL)

ax.plot([50, 50], [tl_y - 0.5, tl_y + 2.6],
        color="black", linewidth=1.8, zorder=3)
ax.text(50, tl_y + 3.0, "anchor (t = 0)",
        ha="center", va="bottom",
        fontsize=9, fontweight="bold")

# Pre + post window shadings below axis
ax.add_patch(patches.Rectangle(
    (m2x(-24), tl_y - 2.0), m2x(0) - m2x(-24), 1.3,
    facecolor="#B8D0E7", edgecolor="none", alpha=0.9, zorder=1))
ax.text((m2x(-24) + m2x(0)) / 2, tl_y - 3.0,
        "baseline", ha="center", va="top", fontsize=8.5,
        color="#204976", fontweight="bold")

ax.add_patch(patches.Rectangle(
    (m2x(6), tl_y - 2.0), m2x(18) - m2x(6), 1.3,
    facecolor="#F4C1C8", edgecolor="none", alpha=0.9, zorder=1))
ax.text((m2x(6) + m2x(18)) / 2, tl_y - 3.0,
        "primary post", ha="center", va="top", fontsize=8.5,
        color="#7A2A33", fontweight="bold")

for Lm in [6, 12, 18, 24, 36, 48]:
    x = m2x(Lm)
    ax.plot([x - 0.4, x + 0.4], [tl_y - 5.0, tl_y - 5.0],
            color="#7A2A33", linewidth=2.5)
ax.text(m2x(28), tl_y - 6.2,
        "landmarks (each \u00B1 6 mo)", ha="center", va="top",
        fontsize=8.5, color="#7A2A33")

arrow(50, 36, 50, 33.2)

# ---------- Row 5: Analyses tiers ---------------------------------------
# Figure is 11 in wide (100 data units). 1 unit ~ 0.28 cm.
# tier_w = 20 data units ~ 5.6 cm wide (previously 4.2 cm, +1.4 cm).
# tier_gap = 5.7 data units ~ 1.6 cm between rectangles.
tier_y    = 22
tier_w    = 20
tier_h    = 14
tier_gap  = 5.7
tier_x0   = 2.2 + tier_w / 2   # shifted 0.5 cm (1.8 units) to the left

tiers = [
    ("Primary",
     "Landmark \u0394 Pain\nTOST non-inferiority\n(\u00B11-point margin; 6\u201348 mo)",
     C_PRIMARY, "#E6F5F2"),
    ("Secondary",
     "LMM (\u00B11 yr, 0\u201348 mo)\nGEE (IPW; adjusted)\nKM time-to-pain\nGLASSO network\n(15 non-motor nodes)",
     C_SECOND, "#E6EDF5"),
    ("Sensitivity",
     "PSM 1:2 matched cohort\nn = 170 (64 DBS / 106 Never-DBS)\ncaliper 0.2 on 7 covariates*\n(age, sex, duration,\nUPDRS-III, NHY, LEDD, BMI)",
     C_SENSIT, "#F4EDE1"),
    ("Exploratory",
     "Genetic/biomarker \u00D7 DBS\nPD-PRS / APOE / SAA / GBA\nPain\u2013motor coupling\n(ordinal logit + \u0394-\u0394 Spearman)",
     C_EXPLOR, "#EEE4F7"),
]

for i, (label, body, stroke, fill) in enumerate(tiers):
    xc = tier_x0 + i * (tier_w + tier_gap)
    ax.add_patch(FancyBboxPatch(
        (xc - tier_w / 2, tier_y + tier_h / 2 - 2.4),
        tier_w, 2.4,
        boxstyle="round,pad=0.05,rounding_size=0.8",
        linewidth=0, edgecolor="none", facecolor=stroke,
    ))
    ax.text(xc, tier_y + tier_h / 2 - 1.2, label,
            ha="center", va="center",
            fontsize=10.5, color="white", fontweight="bold")
    box(xc, tier_y - 1.8, tier_w, tier_h - 2.4,
        body, fill=fill, stroke=stroke,
        fontsize=9)

# Footnote under ALL tiers explaining the matching timepoint.
# Offset 0.8 cm (~2.85 units) below the tier rectangles' lower edge.
footnote_y = tier_y - tier_h / 2 - 2.85
ax.text(50, footnote_y,
        "* baseline = visit closest to anchor within [\u221224, 0] mo",
        ha="center", va="top",
        fontsize=8.2, color=C_SENSIT, fontstyle="italic")

# ---------- Footer: Acronym legend (3-column, tight layout) -------------
legend_cx = 50
legend_w  = 96
legend_h  = 10.0
legend_yc = 5.4
legend_x_left  = legend_cx - legend_w / 2

ax.add_patch(FancyBboxPatch(
    (legend_x_left, legend_yc - legend_h / 2),
    legend_w, legend_h,
    boxstyle="round,pad=0.4,rounding_size=0.6",
    linewidth=0.8, edgecolor="#B9BEC6", facecolor="#FAFBFC",
))

legend_top_y = legend_yc + legend_h / 2 - 1.0
ax.text(legend_x_left + 2.5, legend_top_y,
        "Abbreviations",
        ha="left", va="top",
        fontsize=9, fontweight="bold", color="#333333")

col_entries = [
    [  # column 1
        "APOE = apolipoprotein E",
        "BMI = body-mass index",
        "DBS = deep brain stimulation",
        "GBA = glucocerebrosidase",
        "GDS = Geriatric Depression Scale",
        "GEE = generalised estimating equations",
        "GLASSO = graphical LASSO",
    ],
    [  # column 2
        "IPW = inverse-probability weights",
        "KM = Kaplan\u2013Meier",
        "LEDD = levodopa-equivalent daily dose",
        "LMM = linear mixed model",
        "NHY = Hoehn & Yahr stage",
        "NP1PAIN = MDS-UPDRS Part I item 9 (pain)",
        "PD = Parkinson disease",
    ],
    [  # column 3
        "PD-PRS = PD polygenic risk score",
        "PPMI = Parkinson's Progression Markers Initiative",
        "PSM = propensity-score matching",
        "SAA = \u03B1-synuclein seeding amplification assay",
        "STAI = State-Trait Anxiety Inventory",
        "TOST = two one-sided tests",
        "UPDRS = MDS-UPDRS",
    ],
]

col_xs = [
    legend_x_left + 2.5,
    legend_x_left + 2.5 + legend_w / 3,
    legend_x_left + 2.5 + 2 * legend_w / 3,
]
col_top_y = legend_top_y - 1.4
line_step = 0.95
for col_x, entries in zip(col_xs, col_entries):
    for i, txt in enumerate(entries):
        ax.text(col_x, col_top_y - i * line_step, txt,
                ha="left", va="top", fontsize=7.6, color="#333333")

# ---------- Save --------------------------------------------------------
out_png = "outputs/figures/Figure_methods_schematic.png"
out_pdf = "outputs/figures/Figure_methods_schematic.pdf"
fig.savefig(out_png, dpi=300, bbox_inches="tight", facecolor="white")
fig.savefig(out_pdf, bbox_inches="tight", facecolor="white")
print(f"saved {out_png}")
print(f"saved {out_pdf}")
