#!/usr/bin/env Rscript
# sprint08_competing_risk.R
# ------------------------------------------------------------
# Competing-risk analysis for time-to-pain (NP1PAIN >= 2).
#
# Standard KM treats dropout/death as non-informative censoring.
# We replace that assumption with:
#   - Event of interest:  reaching NP1PAIN >= 2 post-anchor
#   - Competing event:    dropout (last observation pre-event,
#                         lost-to-follow-up) before event was observed
# Time origin: anchor (DBS surgery / patient's first visit).
# Time scale:  months from anchor.
#
# Output:
#   - Cumulative incidence functions per arm (cmprsk::cuminc)
#   - Fine-Gray subdistribution hazard model (cmprsk::crr)
#   - Comparison vs cause-specific Cox HR
# ------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(purrr); library(tibble)
  library(cmprsk); library(survival)
})
source("helpers/pain_helpers.R")
set.seed(20260519)

rel <- load_full_ppmi_rel_patient_anchor()
cat("Full cohort:", dplyr::n_distinct(rel$PATNO), "patients\n")

# Build event-time data: per patient, find FIRST post-anchor visit with
# NP1PAIN >= 2 (event). If none, censor at LAST observed visit.
# Define dropout as: last observed visit < cohort follow-up + no event.
# Competing event = "dropout" coded as 2.
build_event <- function(rel, thr = 2) {
  rel_p <- rel %>%
    dplyr::filter(months >= 0, !is.na(NP1PAIN)) %>%
    dplyr::arrange(PATNO, months)

  # First event time per patient (months >= 0, NP1PAIN >= thr)
  event_t <- rel_p %>%
    dplyr::filter(NP1PAIN >= thr) %>%
    dplyr::group_by(PATNO) %>%
    dplyr::summarise(event_time = min(months, na.rm = TRUE),
                     .groups = "drop")

  # Patient-level: last observation time (post-anchor)
  last_t <- rel_p %>%
    dplyr::group_by(PATNO, will_receive_dbs) %>%
    dplyr::summarise(last_obs = max(months, na.rm = TRUE),
                     .groups = "drop")

  baseline_pain <- rel_p %>%
    dplyr::filter(months <= 6) %>%
    dplyr::group_by(PATNO) %>%
    dplyr::summarise(baseline_pain = first(NP1PAIN), .groups = "drop")

  cohort_max_t <- max(last_t$last_obs, na.rm = TRUE)
  follow_up_cap <- min(60, cohort_max_t)  # cap at 5 years for stability

  last_t %>%
    dplyr::left_join(event_t, by = "PATNO") %>%
    dplyr::left_join(baseline_pain, by = "PATNO") %>%
    dplyr::filter(is.na(baseline_pain) | baseline_pain < thr) %>%  # left-truncate
    dplyr::mutate(
      time = dplyr::if_else(!is.na(event_time),
                            pmin(event_time, follow_up_cap),
                            pmin(last_obs, follow_up_cap)),
      # Code: 1 = pain event, 2 = competing event (dropout before
      # follow-up cap with no event), 0 = administrative censoring
      status = dplyr::case_when(
        !is.na(event_time) & event_time <= follow_up_cap ~ 1L,
        last_obs < follow_up_cap                          ~ 2L,
        TRUE                                              ~ 0L
      ),
      arm = factor(dplyr::if_else(will_receive_dbs, "DBS", "Never-DBS"),
                   levels = c("Never-DBS", "DBS"))
    ) %>%
    dplyr::filter(time > 0)
}

ev_full <- build_event(rel, thr = 2)
cat("\nEvent breakdown:\n")
print(table(ev_full$arm, ev_full$status,
            dnn = c("arm", "status (0=admin cens, 1=pain event, 2=dropout)")))
save_table(ev_full, "sprint08_event_data")

# ---- Cumulative incidence function ----
ci_full <- cmprsk::cuminc(ftime = ev_full$time, fstatus = ev_full$status,
                          group = ev_full$arm)
print(ci_full$Tests)
save_object(ci_full, "sprint08_cuminc")

# ---- Fine-Gray subdistribution hazard model ----
# Treat arm = factor(DBS=1) as the only covariate for headline contrast
cov <- model.matrix(~ arm - 1, data = ev_full)[, "armDBS", drop = FALSE]
fg <- cmprsk::crr(ftime = ev_full$time, fstatus = ev_full$status,
                  cov1 = cov)
cat("\nFine-Gray subdistribution hazard (DBS vs Never-DBS):\n")
print(summary(fg))
fg_tbl <- tibble::tibble(
  comparison = "DBS vs Never-DBS",
  HR_subdist = exp(fg$coef),
  ci_lo      = exp(fg$coef - 1.96 * sqrt(diag(fg$var))),
  ci_hi      = exp(fg$coef + 1.96 * sqrt(diag(fg$var))),
  pval       = 2 * (1 - stats::pnorm(abs(fg$coef / sqrt(diag(fg$var)))))
)
print(fg_tbl)
save_table(fg_tbl, "sprint08_finegray")

# ---- Cause-specific Cox HR (as comparison) ----
cs <- survival::coxph(
  survival::Surv(time, status == 1L) ~ arm, data = ev_full)
cox_tbl <- tibble::tibble(
  comparison = "DBS vs Never-DBS (cause-specific Cox)",
  HR         = exp(stats::coef(cs)),
  ci_lo      = exp(stats::confint(cs)[1]),
  ci_hi      = exp(stats::confint(cs)[2]),
  pval       = summary(cs)$coefficients[1, "Pr(>|z|)"]
)
print(cox_tbl)
save_table(cox_tbl, "sprint08_cs_cox")

# ---- Plot: cumulative incidence ----
times <- seq(0, max(ev_full$time, na.rm = TRUE), by = 1)
cif_arr <- timepoints(ci_full, times = times)
cif_df <- as.data.frame(t(cif_arr$est)) %>%
  tibble::as_tibble(rownames = "time")
cif_df$time <- as.numeric(cif_df$time)
cif_long <- cif_df %>%
  tidyr::pivot_longer(-time, names_to = "group_event",
                       values_to = "cif") %>%
  tidyr::separate(group_event, into = c("arm", "event"),
                   sep = " ", extra = "merge") %>%
  dplyr::mutate(event = dplyr::if_else(event == "1", "Pain ≥ 2",
                                       "Dropout (competing)"))

p_cif <- ggplot(cif_long %>% dplyr::filter(event == "Pain ≥ 2"),
                aes(x = time, y = cif, colour = arm)) +
  geom_step(linewidth = 1) +
  scale_colour_manual(values = ARM_COLORS_OK) +
  scale_y_continuous("Cumulative incidence of pain ≥ 2",
                     labels = scales::percent_format(accuracy = 1)) +
  scale_x_continuous("Months since anchor") +
  labs(title = "Competing-risk cumulative incidence of pain worsening",
       subtitle = sprintf(
         "Fine-Gray subdistribution HR (DBS vs Never-DBS) = %.2f (95%% CI %.2f, %.2f), P = %.3f",
         fg_tbl$HR_subdist, fg_tbl$ci_lo, fg_tbl$ci_hi, fg_tbl$pval),
       colour = NULL) +
  theme_pain_pub(base_size = 11)
save_fig_pub(p_cif, "sprint08_cif_pain_worsening",
             width = 9, height = 4.5)

cat("\n[OK] sprint08 outputs saved.\n")
