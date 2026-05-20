"""
build_callgraph.py
------------------------------------------------------------
Static analysis of the Pain_paper_v2 analytic pipeline.

For every R / Python / ipynb file in the project directory, parse:
  - source("...") in R                            -> R script deps
  - readRDS(...) / readr::read_csv(...) / readxl  -> input files
  - saveRDS / save_object / save_fig / save_table -> outputs
  - ggsave / write_csv                            -> outputs

Emit two artefacts:
  - callgraph.mmd : Mermaid markdown (GitHub renders interactively)
  - outputs/figures/Figure_callgraph.{png,pdf} : static figure

Categories (colour-coded):
  - helper / data loader
  - main analytical script (R)
  - figure / docx builder (Python)
  - notebook (ipynb)
  - output file (figure / table / rds)
"""
from __future__ import annotations
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SRC_FILES = sorted(
    [p for p in ROOT.glob("*.R")]
    + [p for p in ROOT.glob("*.py")]
    + [p for p in (ROOT / "helpers").glob("*.R")]
    + [p for p in ROOT.glob("*.ipynb")]
)

# ---- regex patterns ----
RX_SOURCE        = re.compile(r'source\("([^"]+\.R)"\)')
RX_READ_RDS      = re.compile(r'readRDS\("([^"]+\.rds)"\)')
RX_READ_CSV_R    = re.compile(r'(?:readr::)?read_csv\("([^"]+\.csv)"')
RX_READ_XLSX     = re.compile(r'read_excel\("([^"]+\.xlsx)"')
RX_SAVE_OBJECT_R = re.compile(r'save_object\([^,]+,\s*"([^"]+)"\)')
RX_SAVE_TABLE_R  = re.compile(r'save_table\([^,]+,\s*"([^"]+)"\)')
RX_SAVE_FIG_R    = re.compile(r'save_fig(?:_pub)?\([^,]+,\s*"([^"]+)"')
RX_GGSAVE        = re.compile(r'ggsave\(.*?["\']([^"\']+\.(?:png|pdf|tiff))["\']', re.DOTALL)
RX_WRITE_CSV_R   = re.compile(r'write_csv\([^,]+,[^"]*"([^"]+\.csv)"')
RX_PY_OUT_FIG    = re.compile(r'(?:fig\.savefig|plt\.savefig)\(["\']([^"\']+\.(?:png|pdf))["\']')
RX_PY_LOAD       = re.compile(r'Document\(["\']([^"\']+\.docx)["\']\)')

def parse_file(path: Path) -> dict:
    try:
        text = path.read_text(errors="ignore")
    except Exception:
        return {}
    # ipynb: pull source cells only
    if path.suffix == ".ipynb":
        try:
            nb = json.loads(text)
            text = "\n".join(
                "".join(c.get("source", []))
                for c in nb.get("cells", [])
                if c.get("cell_type") == "code"
            )
        except Exception:
            pass

    out = {
        "sources":    RX_SOURCE.findall(text),
        "reads_rds":  RX_READ_RDS.findall(text),
        "reads_csv":  RX_READ_CSV_R.findall(text),
        "reads_xlsx": RX_READ_XLSX.findall(text),
        "save_obj":   RX_SAVE_OBJECT_R.findall(text),
        "save_tab":   RX_SAVE_TABLE_R.findall(text),
        "save_fig":   RX_SAVE_FIG_R.findall(text),
        "ggsave":     RX_GGSAVE.findall(text),
        "write_csv":  RX_WRITE_CSV_R.findall(text),
        "py_savefig": RX_PY_OUT_FIG.findall(text),
        "docx_input": RX_PY_LOAD.findall(text),
    }
    return out

# ---- collect ----
info: dict[str, dict] = {}
for p in SRC_FILES:
    rel = p.relative_to(ROOT).as_posix()
    info[rel] = parse_file(p)

# ---- classify nodes ----
def category(name: str) -> str:
    if name.startswith("helpers/"):
        return "helper"
    if name.endswith(".ipynb"):
        return "notebook"
    if name.startswith("_build_docx") or name == "_build_methods_figure.py":
        return "docx_builder"
    if name.startswith("build_") or name == "build_causal_dag.R":
        return "build_script"
    if name.startswith("sprint"):
        return "sprint_script"
    if re.match(r"^\d+[a-z]?_", name):
        return "numbered_script"
    return "other"

CAT_COLORS = {
    "helper":         "#F0E442",  # yellow
    "build_script":   "#56B4E9",  # sky blue
    "sprint_script":  "#0072B2",  # blue
    "numbered_script":"#009E73",  # green
    "notebook":       "#CC79A7",  # pink
    "docx_builder":   "#D55E00",  # vermillion
    "output":         "#999999",  # grey
}

# Build Mermaid lines
lines = ["```mermaid", "flowchart LR", "  classDef helper       fill:#F0E442,stroke:#333,color:#000",
         "  classDef build       fill:#56B4E9,stroke:#333,color:#000",
         "  classDef sprint      fill:#0072B2,stroke:#333,color:#fff",
         "  classDef numbered    fill:#009E73,stroke:#333,color:#fff",
         "  classDef notebook    fill:#CC79A7,stroke:#333,color:#000",
         "  classDef docx        fill:#D55E00,stroke:#333,color:#fff",
         "  classDef output      fill:#bbbbbb,stroke:#666,color:#000"
        ]

def safe_id(s: str) -> str:
    return re.sub(r"[^A-Za-z0-9_]", "_", s)

# Nodes
script_class = {}
for name, d in info.items():
    cat = category(name)
    cls = {
        "helper": "helper", "build_script": "build", "sprint_script": "sprint",
        "numbered_script": "numbered", "notebook": "notebook",
        "docx_builder": "docx", "other": "build"
    }[cat]
    script_class[name] = cls
    short = name.split("/")[-1]
    lines.append(f"  {safe_id(name)}[\"{short}\"]:::{cls}")

# Edges (helper -> dependent script; script -> output)
seen_outputs = set()

def add_output(out_path: str):
    if out_path in seen_outputs: return
    seen_outputs.add(out_path)
    short = out_path.split("/")[-1]
    lines.append(f"  {safe_id(out_path)}[(\"{short}\")]:::output")

for name, d in info.items():
    nid = safe_id(name)
    for src in d.get("sources", []):
        # source("helpers/pain_helpers.R")
        sid = safe_id(src)
        lines.append(f"  {sid} --> {nid}")
    for out in d.get("save_obj", []):
        out_path = f"outputs/objects/{out}.rds"
        add_output(out_path)
        lines.append(f"  {nid} --> {safe_id(out_path)}")
    for out in d.get("save_tab", []):
        out_path = f"outputs/tables/{out}.csv"
        add_output(out_path)
        lines.append(f"  {nid} --> {safe_id(out_path)}")
    for out in d.get("save_fig", []):
        out_path = f"outputs/figures/{out}.png"
        add_output(out_path)
        lines.append(f"  {nid} --> {safe_id(out_path)}")
    for out in d.get("py_savefig", []):
        add_output(out)
        lines.append(f"  {nid} --> {safe_id(out)}")
    for out in d.get("ggsave", []):
        # Trim path
        op = out
        add_output(op)
        lines.append(f"  {nid} --> {safe_id(op)}")
    for out in d.get("write_csv", []):
        add_output(out)
        lines.append(f"  {nid} --> {safe_id(out)}")

lines.append("```")

mmd_path = ROOT / "callgraph.mmd"
mmd_path.write_text("\n".join(lines))
print(f"[OK] Wrote {mmd_path}")

# ---- Render to PNG via matplotlib + networkx (no graphviz dependency) ----
try:
    import matplotlib.pyplot as plt
    import networkx as nx
except ImportError:
    print("[skip] matplotlib/networkx not available; PNG render skipped.")
else:
    G = nx.DiGraph()
    for name in info.keys():
        G.add_node(name, kind=category(name))
    for out in seen_outputs:
        G.add_node(out, kind="output")
    # edges
    for name, d in info.items():
        for src in d.get("sources", []):
            G.add_edge(src, name)
        for out in d.get("save_obj", []):
            G.add_edge(name, f"outputs/objects/{out}.rds")
        for out in d.get("save_tab", []):
            G.add_edge(name, f"outputs/tables/{out}.csv")
        for out in d.get("save_fig", []):
            G.add_edge(name, f"outputs/figures/{out}.png")
        for out in d.get("py_savefig", []):
            G.add_edge(name, out)
        for out in d.get("ggsave", []):
            G.add_edge(name, out)
        for out in d.get("write_csv", []):
            G.add_edge(name, out)

    print(f"  Graph: {G.number_of_nodes()} nodes, {G.number_of_edges()} edges")

    # Filter to a manageable subset for the figure: scripts only, + key outputs
    KEY_SCRIPTS = {n for n in G.nodes if not n.startswith("outputs/")
                   and not n.endswith(".ipynb")}
    KEY_OUTPUTS = {n for n in G.nodes if n.startswith("outputs/figures/")}
    keep = KEY_SCRIPTS | KEY_OUTPUTS
    H = G.subgraph(keep).copy()
    print(f"  Subgraph (scripts + figures): {H.number_of_nodes()} nodes, {H.number_of_edges()} edges")

    # Hierarchical layout
    layers = {}
    for n in H.nodes():
        c = category(n) if not n.startswith("outputs/") else "output"
        layer = {"helper": 0, "build_script": 1, "sprint_script": 1,
                 "numbered_script": 1, "docx_builder": 2, "output": 2}.get(c, 1)
        layers[n] = layer
        H.nodes[n]["layer"] = layer

    pos = nx.multipartite_layout(H, subset_key="layer", scale=4)

    fig, ax = plt.subplots(figsize=(20, 16))
    # Draw edges
    nx.draw_networkx_edges(H, pos, ax=ax, edge_color="grey",
                           arrows=True, arrowsize=8, width=0.4, alpha=0.55)
    # Draw nodes by category
    for c, color in CAT_COLORS.items():
        nlist = [n for n in H.nodes if (category(n) if not n.startswith("outputs/") else "output") == c]
        if not nlist: continue
        nx.draw_networkx_nodes(H, pos, nodelist=nlist, ax=ax,
                               node_color=color, node_size=550,
                               edgecolors="black", linewidths=0.4)
    # Labels (shortened)
    labels = {n: n.split("/")[-1] for n in H.nodes}
    nx.draw_networkx_labels(H, pos, labels=labels, ax=ax,
                             font_size=6.5)
    # Legend
    from matplotlib.patches import Patch
    legend_items = [Patch(facecolor=v, edgecolor="black", label=k) for k, v in CAT_COLORS.items()]
    ax.legend(handles=legend_items, loc="upper left", fontsize=9)
    ax.set_title("Pain_paper_v2 — analytic pipeline callgraph",
                 fontsize=14, fontweight="bold")
    ax.axis("off")
    plt.tight_layout()

    fig_path = ROOT / "outputs/figures/Figure_callgraph.png"
    pdf_path = ROOT / "outputs/figures/Figure_callgraph.pdf"
    fig.savefig(fig_path, dpi=200, bbox_inches="tight", facecolor="white")
    fig.savefig(pdf_path, bbox_inches="tight", facecolor="white")
    print(f"  [OK] saved {fig_path}")
    print(f"  [OK] saved {pdf_path}")
