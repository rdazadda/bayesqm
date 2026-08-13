# bayesqm 0.2.0 — implementation plan

The package tracks the paper: 0.2.0 replaces the Student-t score-scale model
with the exact partition (rank-order) likelihood and rebuilds every summary,
check, and plot to the paper's specification. Planned by a four-specialist /
three-judge panel (2026-07-12); reference implementations live in
`../smr-migration/rank-revision/Simulation Folder/` (audited, verified) and
are ported, not rewritten. Zero reverse dependencies on CRAN; 0.2.0 is a
declared breaking release.

## Settled decisions (unanimous or 2-1 across judges)

1. **Entry point stays `fit_bayesian()`.** "Partition" is paper jargon;
   fit_bayesian is what users type. Removed Stan-era arguments (robust, nu,
   chains, adapt_delta, stan_dir, prior_*) are caught in `...` with a
   migration error naming the replacement. The print header states "Exact
   partition (rank-order) likelihood, PX-Gibbs" so the model change is
   unmissable. Flat arguments, no control object: `fit_bayesian(data, K,
   iterations = 12000, burn = 2000, thin = 5, max_iterations = 48000,
   seed, keep_raw = TRUE, quiet = FALSE)` — paper-frozen defaults, all
   overridable.
2. **Engine is pure R, final.** The audited sampler IS the paper artifact;
   an Rcpp port could not be draw-for-draw identical and would need its own
   verification campaign. Worst plausible panels run minutes. Rcpp is a
   0.3.0 option gated on real complaints. The sanctioned within-R U-update
   vectorization gets measured before submission.
3. **Stan stack deleted entirely.** inst/stan, backend plumbing
   (detect_backend/sample_cmdstanr/sample_rstan), helper-stan.R,
   Additional_repositories all go. Deps: DROP rstantools, cmdstanr, rstan,
   parallel, GPArotation (stats::varimax is used), lpSolve (greedy signed
   match; LSAP only in the footrule cross-check). ADD posterior to Imports
   (the gate is core), clue to Suggests (footrule check degrades
   gracefully). loo stays Suggests for the directional-corroboration
   bridge; GHK log-likelihoods are computed in R.
4. **Gate = the paper's rule.** posterior::rhat + ess_bulk + ess_tail on
   the invariant s_i, min-over-persons >= 400, rhat < 1.01; warm-started
   doubling ladder to the cap. Gate failure warns and sets
   `$gate$converged = FALSE`, never errors. `extend(fit, iterations =)` is
   the user-facing continuation verb; `update()` keeps the stats
   convention. **RNG subtlety the briefs missed:** the fit snapshots
   `.Random.seed` into `$state` at return and restores it on continuation,
   so extend() preserves the one-long-run bitwise identity even after
   arbitrary user code. That identity is a frozen test from M1 on.
5. **Deprecation split by semantics.** Defunct stubs (informative errors in
   R/deprecated.R, deleted at 0.3.0) for everything whose numbers changed:
   classify_membership, compute_dominant_prob/sign, compute_threshold_prob,
   compute_divergence, critical_delta, run_bayes, select_k_peak,
   select_k_sivula. No soft shims — a shim returning new quantities under
   an old name is worse than an error. Soft aliases only where the concept
   is preserved: plot_membership → plot_flags, plot_dist_cons →
   plot_contrasts, plot_hyper → plot_sigma, suggest_delta → delta_grid()
   (documenting the population-sd definition change, ~1% at J=42).
6. **Names kept with changed semantics get a NEWS "Breaking" table**
   (old vs new definition side by side): fit_bayesian (model),
   compute_loadings (lambda → bounded rho with CrIs), compute_factor_array
   (posterior column-probability sort, quota-exact by construction),
   compute_zscores (aligned draws). matchalign() becomes
   `matchalign(fit, pivot = NULL)` — fit-level, matching the audited code,
   sigma carried through.
7. **Validation placement:** import stays lenient (read_* and qsort_data
   warn); `fit_bayesian()` hard-errors on quota violations, naming the
   offending persons and stating the scope plainly ("the exact rank-order
   likelihood requires forced sorts matching the design grid"). The import
   vignette warns up front that free-distribution studies are out of scope.
8. **Publication rule is one user concept.** `publish(fit, q = .05)` →
   `bayesqm_claims` (four families: flags, distinguishing, consensus,
   pairwise stars; expected_false per table). Every table function's
   `published` column is computed by the SAME fdr_publish code path,
   asserted by a test, so compute_flags(fit, q) and publish(fit, q) can
   never disagree.
9. **Choice of K:** `fit_ladder(data, K_max = min(6, floor(N/3)), ...)`
   (capped at 3 for N <= 12) → `bayesqm_ladder`; `select_k(ladder)`
   implements Algorithm 2 (two signals, tension and null-declaration
   branches, verbose about WHY a K failed) and re-runs at different q
   without refitting. Upfront runtime estimate printed before the ladder
   starts (~77 s per rung at N=33/J=42/K=3, more if gates extend).
   loo_ladder() prints "directional corroboration only" with the Sivula
   N < 100 caveat.
10. **Plain vocabulary in user-facing surfaces.** Tidy-frame columns are
    `loading` and `flag_prob`, not rho/phi (Greek lives in the docs
    formulas). check_fit() prints "agreement check / extra-factor check /
    paired-comparison check / person screening" with T1a/T1b/T2/T3 as
    parenthetical cross-references. Additive framing audited in every
    caption, message, and help page.
11. **Dropped:** eigenvalues/explained variance from f_char (no counterpart
    in a generative model; T1b answers the retained-structure question).
    The summary help and vignette say explicitly what to report instead
    (defining-sort counts with CrIs, T1b adequacy percentile) — reviewers
    will ask.
12. **Storage:** fit stores aligned draws (F, Lambda, sigma, s_i), raw
    draws when keep_raw = TRUE (enables later realignment/pivot
    sensitivity without refitting), gate report, alignment info (pivot,
    per-draw congruence), state. rho and array draws are deterministic
    transforms computed on demand — not persisted.
13. **Deferred to 0.3.0:** pivot_sensitivity(), threshold_sensitivity(),
    Rcpp. crib_sheet() ships in 0.2.0 (cheap: kappa/top/bottom
    probabilities already fall out of the summary pass).
14. **demo_fit() re-runs a tiny fixed-seed fit** (~N=8, J=13, K=2, ~200
    kept draws, about a second, gate off) — no serialized fit objects in
    inst/ (they rot across versions). demo_fit + the rebuilt fake-fit
    helper are the substrate for every example, test, and snapshot; no
    example, test, or vignette chunk ever runs a real paper-scale fit on
    CRAN.

## API surface (new/changed exports)

Fitting: fit_bayesian, extend, matchalign, delta_grid.
Summaries: compute_loadings, compute_flags, compute_zscores,
compute_factor_array, compute_qdc (three-state verdicts: distinguishing /
consensus / indeterminate, delta_kl posterior SED + delta_grid ROPE),
crib_sheet, publish.
Checks: check_fit (T1a/T1b/T2), check_persons (T3 verdicts + partner
naming), fit_ladder, select_k, loo_ladder (+ loglik_person for GHK).
Rotation: rotate_factors (judgmental target, inverse transpose for
oblique), flip_factor, rename_factors (updated slots).
Plots: plot_loading_posterior (on rho), plot_flags, plot_factor_array
(the flagship — the figure every Q paper needs), plot_contrasts (delta
intervals vs delta_kl and delta_grid landmarks, verdict colors),
plot_choice_k, plot_person_check (m/w bands, verdict colors, partner
arrows), plot_convergence (gate report), plot_sigma, plot_ppc
(re-pointed), plot.bayesqm_fit; autoplot parity in 0.2.0 for the flagship
four (loadings, flags, contrasts, array), rest in 0.2.x. Okabe-Ito
qualitative slot added to every colors.R scheme; nothing color-alone.
Unchanged: the entire import layer, qsort_data, colors/save_plot/caption
scaffolding, accessors reworked minimally (residuals becomes defunct — no
residual scale in a rank likelihood; fitted returns posterior-mean
F Lambda' on the utility scale).

## Milestones (one person, ~7-9 focused weeks)

M1 (1.5 wk) Engine core + Stan teardown. Port quota_sort/midranks/
    delta_grid, PX-Gibbs, conv_stats/check_conv, warm-started ladder into
    R/gibbs.R; .Random.seed snapshot in $state; delete Stan stack;
    DESCRIPTION rewrite. Tests: engine pins (delta_grid constants at full
    precision), bitwise floor+extension identity (expect_identical,
    including across an interrupted-session continuation), gate
    determinism. Nothing else starts until M1 is green.
M2 (0.5-1 wk) Alignment. Conventions pass, matchalign(fit, pivot),
    polarity canon, rotate_sigma in R/align.R. Tests: conventions exact to
    1e-12, canon sign at pivot, idempotence, sigma carriage.
M3 (1 wk) Fit object + entry point. bayesqm_fit constructor, fit_bayesian
    with migration errors and strict fit-time quota check, extend(),
    summarize pass, print/summary; rebuild make_fake_fit and demo_fit
    immediately (substrate for everything downstream); R/deprecated.R.
M4 (1.5 wk) Summaries + publication. compute_loadings/flags/zscores/
    factor_array/qdc, crib_sheet, delta_grid export, publish() with the
    shared fdr_publish path + coherence test.
M5 (1.5 wk) Checks + choice of K + GHK. check_fit, check_persons,
    fit_ladder/select_k, ghk loglik_person + loo bridge; GHK
    total-probability and SBC smoke behind skip_on_cran() +
    BAYESQM_RUN_SLOW.
M6 (1-1.5 wk) Plots. Base-R plot_* for every view first, autoplot for the
    flagship four, palette slot, caption rewrite, deprecated plot aliases;
    vdiffr snapshots regenerated per plot as each lands (never one sweep).
M7 (1 wk) Rotation, docs, release. rotate_factors/flip_factor, accessors,
    NEWS.md Breaking table, vignettes (Getting Started with a "coming from
    PQMethod/qmethod" mapping; the unchanged import vignette; full
    workflow as precomputed/eval=FALSE or a post-release pkgdown article),
    pkgdown regroup, additive-framing audit, R CMD check --as-cran from a
    non-OneDrive copy, win-builder + mac-builder, cran-comments.md stating
    the model replacement per the forthcoming BRM paper (zero revdeps),
    submit.

## Risks the judges flagged

- Warm-start bitwise identity is load-bearing; the M1 expect_identical
  test is frozen — any later RNG reordering in the U-update must fail it.
- One leaked paper-scale fit in an example/test/vignette fails CRAN's
  check; everything runs on demo objects (enforced by a test).
- The strict quota error will hit free-distribution users (Ken-Q, HTMLQ,
  KADE allow them); the error text and vignette carry the rationale.
- Kept names with changed numbers: an unedited 0.1.0 script runs and
  returns different quantities — NEWS Breaking table + print header +
  per-function help notes are the mitigation.
- Runtime on large panels (N=60-80, J=60+, K ladder): measure the U-update
  vectorization before submission; progress reporting throughout.
- Pin structure and invariants in tests, not third-decimal posterior
  values (tiny-fit quantile pins are seed-fragile across platforms).
