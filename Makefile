.PHONY: help env synth-data primary analyses figures site tests clean all

R := Rscript
PY := python3

help:
	@echo "Targets:"
	@echo "  make env         — restore R + Python environments (renv + uv)"
	@echo "  make synth-data  — regenerate synthetic PPMI fixture (deterministic)"
	@echo "  make primary     — run primary/secondary/exploratory analyses"
	@echo "  make analyses    — run 16 robustness analyses"
	@echo "  make figures     — rebuild all figures (PNG + PDF)"
	@echo "  make site        — rebuild the gh-pages public website"
	@echo "  make tests       — run R + Python unit tests"
	@echo "  make all         — synth-data + primary + analyses + figures"
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

primary:
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

analyses:
	@for f in analyses/*.R; do echo "=== $$f ==="; $(R) $$f; done

figures:
	$(R) R/build_causal_dag.R
	$(PY) scripts/build_callgraph.py
	$(PY) scripts/build_sankey.py

site:
	$(PY) scripts/build_site.py

tests:
	$(R) -e 'testthat::test_dir("tests/testthat")'

all: synth-data primary analyses figures
	@echo "[OK] full pipeline rebuilt under outputs/."

clean:
	rm -rf outputs/figures/*.png outputs/figures/*.pdf outputs/figures/*.tiff
	rm -rf outputs/tables/*.csv outputs/tables/*.html
	rm -rf outputs/objects/*.rds
	@echo "[OK] outputs cleaned."
