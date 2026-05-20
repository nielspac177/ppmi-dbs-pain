.PHONY: help env synth-data analysis sprints figures dashboard book tests clean all

R := Rscript
PY := python3

help:
	@echo "Targets:"
	@echo "  make env         — restore R + Python environments (renv + uv)"
	@echo "  make synth-data  — regenerate synthetic PPMI fixture (deterministic)"
	@echo "  make analysis    — run primary/secondary/exploratory analyses"
	@echo "  make sprints     — run sprint01–09 robustness analyses"
	@echo "  make figures     — rebuild all figures (PNG + PDF)"
	@echo "  make dashboard   — rebuild the interactive HTML results dashboard"
	@echo "  make book        — render the Quarto book to docs/_site/"
	@echo "  make tests       — run R + Python unit tests"
	@echo "  make all         — synth-data + analysis + sprints + figures + dashboard"
	@echo "  make clean       — remove rebuildable outputs"

env:
	$(R) -e 'if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv"); renv::restore()'
	@which uv > /dev/null 2>&1 || pip install -q uv
	uv pip install -r requirements.txt 2>/dev/null || pip install -r requirements.txt

synth-data:
	$(R) R/helpers/make_synthetic_cohort.R

analysis:
	$(R) R/build_fig5_and_tables.R
	$(R) R/build_gee_table3.R
	$(R) R/build_replication_figs.R
	$(R) R/build_delta_24m_landmark.R
	$(R) R/build_delta_matched_6_12mo.R
	$(R) R/build_stratified_delta_by_window.R
	$(R) R/25_genetics_arm_pain.R
	$(R) R/26_pain_motor_coupling.R
	$(R) R/26b_pain_motor_coupling_matched.R
	$(R) R/26c_pain_as_outcome.R

sprints:
	@for f in sprints/sprint*.R; do echo "=== $$f ==="; $(R) $$f; done

figures:
	$(R) R/build_causal_dag.R
	$(PY) scripts/build_callgraph.py
	$(PY) scripts/build_sankey.py
	$(PY) scripts/build_dashboard.py

dashboard:
	$(PY) scripts/build_dashboard.py

book:
	cd docs && quarto render

tests:
	$(R) -e 'testthat::test_dir("tests/testthat")'

all: synth-data analysis sprints figures dashboard
	@echo "[OK] full pipeline rebuilt under outputs/."

clean:
	rm -rf outputs/figures/*.png outputs/figures/*.pdf outputs/figures/*.tiff
	rm -rf outputs/tables/*.csv outputs/tables/*.html
	rm -rf outputs/objects/*.rds
	rm -rf docs/_site docs/_freeze .quarto
	@echo "[OK] outputs cleaned."
