# ADR-0007 · Empirical bootstrap as Bayesian posterior approximation

- Status: **Provisional** (peer reviewer has objected — see Analysis 14 follow-up)
- Date: 2026-05-19

## Context

Analysis 11 attempts a Bayesian re-analysis of the null genetic / biomarker
× DBS interactions (PD-PRS / APOE / SAA / GBA) on Δ Pain. The
frequentist nulls are uninterpretable at n_DBS ≈ 50 per stratum:
minimum detectable interaction at 80 % power is ≈ ±0.5 pain points.
A Bayesian framing produces an *informative* null: "P(|β| > 0.25) =
0.15" is much more useful than "LRT P = 0.30".

The canonical implementation is `brms` (Stan back-end). However, `brms`
installs require a Stan compile tool-chain (rtools / Xcode / etc.),
which adds 10–15 minutes to first run and a substantial container
size. For a CI pipeline that runs on every push, this is heavy.

## Decision

Implement Analysis 11 as an **empirical bootstrap posterior
approximation**:

1. Bootstrap `B = 10,000` resamples of the data.
2. For each resample, refit the interaction model and store the
   interaction coefficient.
3. Treat the empirical bootstrap distribution as the posterior under
   a flat / uninformative prior.
4. Report posterior mean, 95 % credible interval (= percentile
   bootstrap CI), `P(|β| > 0.25)`, and `P(|β| > 0.50)`.

When `brms` is available, additionally fit a proper Bayesian model
with weakly-informative Normal(0, 0.5) priors for comparison.

## Consequences

**Positive**
- No Stan compilation; runs in pure R on every CI push.
- Identifies hypothesis-generating signals (e.g., GBA × DBS posterior
  mean +0.47) that a frequentist null hides.
- Computationally cheap (a few minutes for 4 stratifiers × 10,000
  bootstraps).

**Negative**
- A bootstrap distribution is **not** a posterior in the strict
  Bayesian sense. It is a sampling distribution of the estimator
  under the data-generating process. Under flat priors and a linear-
  Gaussian model the two coincide asymptotically, but with sparse
  cells the asymptotics break.
- A peer reviewer (`PEER_REVIEW_2026-05-21.md`, comment 8) flagged
  this as a misnomer.

## Alternatives considered

- **Install `brms`/`rstanarm` in the container.** Will be done in
  Analysis 14. Requires updating `Dockerfile` and `renv.lock`.
- **Conjugate Normal–Normal closed-form posterior** (a one-liner with
  known prior). Possible for the linear interaction but doesn't
  generalise to ordinal / robust outcomes.
- **Frequentist confidence-interval-as-credible-interval**. Same
  conflation, less explicit framing. Rejected as worse than the
  bootstrap.

## Revision direction

Rename "Bayesian-flavoured" to "bootstrap distribution"; either drop
the posterior framing or genuinely fit `brms`. Tracked as Analysis 14
in `RESPONSE_TO_REVIEWERS.md`.
