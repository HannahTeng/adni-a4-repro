# A4/LEARN: amyloid, tau and p-tau217 prediction of decline. Reproduction report

All numbers below are aggregates. No participant-level data appear in this report or in `output/`.

## Papers

- **A (main).** Sperling RA, Donohue MC, Rissman RA, et al. *Amyloid and Tau Prediction of Cognitive and Functional Decline in Unimpaired Older Individuals: Longitudinal Data from the A4 and LEARN Studies.* J Prev Alzheimers Dis 2024;11(4):802–813. doi:10.14283/jpad.2024.122. https://pmc.ncbi.nlm.nih.gov/articles/PMC11266444/
- **B (add-on).** Rissman RA, et al. *Longitudinal Phospho-tau217 Predicts Amyloid Positron Emission Tomography in Asymptomatic Alzheimer's Disease.* J Prev Alzheimers Dis 2024;11(4):823–830. doi:10.14283/jpad.2024.134. https://pmc.ncbi.nlm.nih.gov/articles/PMC11266279/
  - The task brief cites pages 831–837. PMC lists 823–830.

Scripts (each runs in under 10 s): `reproduce_main.R` and `reproduce_rissman.R`. Run either with `cd <this folder> && Rscript <file>`. Aggregate CSVs go to `output/`, which is git-ignored via `.gitignore`.

## Data used

- **Package:** `A4LEARN` 1.1.20250808, data download 2025-08-08. Both papers were published in July 2024, so they used an earlier data cut. Small N differences are expected.
- **Datasets:**
  - `SUBJINFO`: arm `TX`, `MITTFL`, demographics, `APOEGN`/`AAPOEGNPRSNFLG`, `SUVRCER`, `AMYLCENT` (= 183.07·SUVR − 177.26), `TAUPETFL`.
  - `ADQS`: PACC, LMIIa, MMSE, CFITOTAL, ADLPQSP, CDRSB (A4) / CDSOB (LEARN); `ADURW`, `EPOCH`, `VISITCD`, `QSVERSION`.
  - `cdr`: `CDGLOBAL` and visit days.
  - `biomarker_pTau217`: Lilly ECL assay, U/mL. `ORRES` is censored at LLOQ/ULOQ; `ORRESRAW` holds the raw reading.
  - `imaging_SUVR_amyloid`: `Composite_Summary`, whole-cerebellum reference (`suvr_cer`).
  - `imaging_SUVR_tau`: FreeSurfer `*_VOI` regions. `suvr_cer` is empty for tau, so `suvr_crus` (cerebellar crus) is the cerebellar reference; `suvr_persi` is a white-matter reference.
  - `famhxpar` and `famhxsib`: family history.
- **Not available in A4LEARN:**
  - CSF Aβ42/40 (Rissman). `biomarker_AB_Test` is Araclon plasma and `biomarker_Plasma_Roche_Results` is Roche plasma; neither is CSF.
  - The supplements (`mmc1.docx` for both papers: tau-substudy demographics for A; supplementary figure for B). WebFetch did not return them, so nothing that depends on them was compared.
- **Figure-only results.** Most of paper A's per-predictor results (unique and common R², trajectories) appear only in Figures 1–4. The text gives only the total R² values and qualitative rankings, so those are what the comparison tables use. Figure-level quantities were reproduced but have no text numbers to compare against.

---

## Paper B: Rissman et al. (p-tau217 → amyloid PET)

### Population derivation

| Step | Placebo | Solanezumab | LEARN | Total |
|---|---|---|---|---|
| A4 mITT (`MITTFL==1`) + all LEARN enrolled | 583 | 564 | 538 | 1685 |
| ≥1 numeric p-tau217 (`ORRESRAW`); first available sample used | **562** | **540** | **524** | **1626** |
| Paper Table 1 | 562 | 540 | 524 | 1626 |

The paper's Table 1 is labelled "baseline P-tau217". The N match is exact only with the first available sample per person, using the raw value including <LLOQ/>ULOQ readings. For 32 A4 participants that first sample is week 12 (or later); for 44 LEARN participants it is month 18 or later.

### Baseline characteristics (Table 1)

| Quantity | Paper | Reproduced | Match |
|---|---|---|---|
| Age, Pbo / Sola / LEARN | 71.9 (5.0) / 72.0 (4.6) / 70.5 (4.3) | 71.9 (5.0) / 72.0 (4.6) / 70.5 (4.3) | exact |
| Female n (%) | 343 (61.0) / 313 (58.0) / 322 (61.5) | 343 (61.0) / 313 (58.0) / 322 (61.5) | exact |
| Education | 16.5 / 16.6 / 16.7 | 16.5 / 16.6 / 16.7 | exact |
| White | 529 / 511 / 490 | 529 / 511 / 490 | exact |
| Black / Asian / Hispanic (total) | 36 / 33 / 51 | 36 / 33 / 51 | exact |
| APOE E3/E4 | 264 / 264 / 104 | 264 / 264 / 104 | exact |
| APOE E4/E4 | 45 / 44 / 2 | 45 / 44 / 2 | exact |
| APOE E3/E3 | 201 / 191 / 337 | 201 / 191 / 337 | exact |
| FBP Centiloid | 65.6 (32.1) / 66.7 (33.5) / 4.3 (12.5); total 46.2 (40.2) | identical | exact |
| P-tau217 U/mL | 0.27 (0.15) / 0.29 (0.17) / 0.15 (0.05); total 0.23 (0.15) | identical | exact |
| PACC | −0.0 (2.6) / 0.0 (2.8) / 0.8 (2.3) | identical | exact |
| LM delayed / MMSE | 12.7/12.6/13.5; 28.8/28.8/29.0 | identical | exact |
| CSF Aβ42/40 | 0.071 (0.026), n≈263 | not in package | n/a |

### Key results

| Quantity | Paper | Reproduced | Match |
|---|---|---|---|
| AUROC, CL ≥ 20 (N=1626, 1127 positive) | 0.87 (0.85–0.88) | **0.866 (0.848–0.884)**, DeLong | yes |
| AUROC, CL ≥ 33 (992 positive) | 0.89 (0.87–0.90) | **0.887 (0.870–0.903)** | yes |
| Spearman p-tau217 vs CL | 0.73 (0.71–0.75) | 0.732 (0.709–0.754), Fisher z | exact |
| Repeatability (placebo wk0–wk12 ≤143 d; LEARN 1.4–1.75 y), pooled | 0.91 (0.90–0.92) | 0.913 (0.901–0.924), 830 pairs (523 Pbo + 307 LEARN) | exact |
| Spearman p-tau217 vs CSF Aβ42/40 | −0.54 (−0.62 to −0.45) | not reproducible (no CSF data) | n/a |
| Sola − Pbo p-tau217 at wk 240 (spline, 2 df; age, APOE4) | −0.018 (−0.055 to 0.019), p=0.352 | −0.020 (−0.047 to 0.006), p=0.125 | yes (same conclusion) |
| Sola − Pbo amyloid at wk 240 | −7.6 CL (−10.3 to −4.94), p<0.001 | −8.1 CL (−10.8 to −5.5), p<0.001 (linear time) | approx. |
| Correlation of annualised change, p-tau217 vs CL | "about 0.15" | 0.14 (0.08–0.20), Spearman of BLUP slopes | yes |
| Youden cut-point, sens/spec (≥33 CL) | not reported | 0.177 U/mL, 0.81 / 0.83 | n/a |

**Verdict B: reproduced.** Table 1 matches to the last digit, and so do the AUROC point estimates, the CL correlation and repeatability. The AUROC CIs are about 0.003 wider than the published ones, consistent with a different CI method (likely bootstrap vs our DeLong). The longitudinal treatment effects agree in direction and significance.

### Deviations and assumptions (B)

- "Baseline" means the first available numeric `ORRESRAW` sample. This is the only definition that reproduces N = 1626.
- The CI method was not stated. We used DeLong for AUROC and Fisher z for Spearman.
- **Longitudinal p-tau217 model:**
  - lme with a random intercept and linear random slope (in years), natural spline (2 df) in weeks since randomisation.
  - Spline × solanezumab interaction with no baseline difference allowed; adjusted for age and APOE4.
  - Samples restricted to VISCODE 6, 9, 66 and 999 (baseline, week 12, week 240 and early-termination endpoint). Adding the open-label sample (997) gives −0.027 (−0.053 to −0.001), p=0.04, which crosses nominal significance.
  - The published model may have been a GLS with heterogeneous Toeplitz covariance, as in the A4 primary analysis.
- Amyloid PET has at most 2–3 scans per person and the knot falls at week 0, so a 2-df spline is not identifiable. We used linear time, which explains the 0.5 CL gap.
- Paper-internal inconsistencies:
  - The abstract says "≥22 CL"; the Results and figure say "≥20 CL".
  - The Results text quotes p-tau217 "×1000" values (266.6/286.9/147.3), consistent with Table 1 × 1000.
  - "CSF" Aβ42/40 has no CSF source in the public package.

---

## Paper A: Sperling et al. (amyloid, tau and p-tau217 → decline)

### What the paper did (extracted)

- **Population:**
  - A4 amyloid-positive arms analysed separately and combined: placebo 583, solanezumab 564 (these are exactly the mITT Ns).
  - LEARN amyloid-negative: 553. The text gives a total of 1,718, but the arm Ns sum to 1,700.
  - Table 1 is restricted to people with p-tau217: 535 / 521 / 469.
  - Tau-PET substudy: 350 A4 participants with all baseline variables (no LEARN).
- **Outcomes:** PACC (primary; every 6 months); CFI combined, ADL-PI partner, CDR-SB (annual); CDR-GS progression (two consecutive >0, or >0 at the last double-blind visit).
- **Predictors:**
  - Florbetapir Centiloid, with A4 tertiles at <46, 46.1–77.2 and >77 CL.
  - Plasma p-tau217 (Lilly ECL), with tertiles.
  - Flortaucipir early neocortical composite: inferior temporal, fusiform, middle temporal and inferior parietal (reference not stated).
  - Covariates: baseline PACC, CFI, age, APOE4, sex, education, URG, treatment.
- **Models:**
  - Natural cubic splines in time by tertile group, adjusted for age, education, APOE4 (and PACC version); mixed-effects or heterogeneous Toeplitz covariance.
  - Kaplan–Meier for CDR-GS progression.
  - Variance explained in two steps: (1) mixed model → participant-specific PACC change at week 240; (2) OLS commonality analysis with 10 baseline predictors.
  - Only R² is reported; no AIC/BIC. p-values are nominal.

### Population derivation (reproduced)

| Step | Placebo | Solanezumab | LEARN | Paper |
|---|---|---|---|---|
| A4 mITT + LEARN enrolled | 583 | 564 | 538 | 583 / 564 / 553 |
| PACC data in analysis window (A4 blinded epoch + wk0; LEARN "≤ wk 240" epoch) | 583 | 564 | 538 | |
| Baseline p-tau217 at protocol baseline visit (A4 wk 0 / LEARN visit 1, raw) | 543 | 522 | 480 | 535 / 521 / 469 (Table 1) |
| + all 9 other baseline predictors (OLS sample) | 541 | 522 | 476 | |
| Tau substudy: + first-scan neocortical tau (A4 only) | 178 | 173 | 0 | **351 vs 350** |

LEARN is 538 in this data release versus 553 in the paper. Applying `LEARNFL` to screen-fails adds 29 more people, which overshoots, so the gap is most likely a data-cut difference.

### Baseline characteristics (p-tau217 subset)

| Quantity | Paper Pbo / Sola / LEARN | Reproduced Pbo / Sola / LEARN | Match |
|---|---|---|---|
| N | 535 / 521 / 469 | 543 / 522 / 480 | close (+8 / +1 / +11) |
| Age | 71.9 (5.0) / 72.0 (4.6) / 70.5 (4.3) | 71.9 (5.0) / 72.0 (4.6) / 70.4 (4.3) | yes |
| Female % | 59.8 / 57.0 / 61.6 | 60.0 / 57.1 / 62.1 | yes |
| Education | 16.5 / 16.6 / 16.7 | 16.5 / 16.6 / 16.7 | exact |
| White % | 94.2 / 94.4 / 93.8 | 94.1 / 94.4 / 93.3 | yes |
| Family history % | 76.8 / 73.1 / 65.7 | 76.6 / 73.2 / 66.7 | yes |
| APOE ε3/ε4 % | 47.1 / 49.3 / 20.0 | 47.1 / 48.9 / 19.9 | yes |
| APOE ε4/ε4 % | 8.2 / 8.3 / 0.4 | 8.1 / 8.2 / 0.4 | yes |
| P-tau217 | 0.3 (0.1) / 0.3 (0.2) / 0.2 (0.1) | 0.27 (0.15) / 0.29 (0.17) / 0.15 (0.05) | yes |
| FBP SUVr | 1.3 (0.2) / 1.3 (0.2) / 1.0 (0.1) | 1.33 (0.18) / 1.33 (0.18) / 0.99 (0.07) | yes |
| FBP Centiloid (All A4 / LEARN) | 66.2 (32.7) / 4.7 (12.4) | 66.1 (32.7) / 4.2 (12.6) | yes |
| PACC | 0.0 (2.7) / 0.0 (2.7) / 0.9 (2.3) | 0.0 (2.7) / 0.0 (2.8) / 0.8 (2.4) | yes |
| LM delayed / MMSE | 12.7, 12.7, 13.7 / 28.8, 28.8, 29.0 | 12.7, 12.6, 13.6 / 28.8, 28.8, 29.0 | yes |
| **CFI combined** | 2.3 (2.1) / 2.4 (2.2) / 1.8 (1.9) | **3.6 (3.3) / 4.0 (3.6) / 3.0 (3.0)** | **no** |
| ADL partner | 43.5 / 43.4 / 43.9 | 43.5 / 43.4 / 44.0 | yes |
| CDR-SB | 0.0 (0.1) / 0.1 (0.2) / 0.0 (0.1) | 0.0 (0.1) / 0.1 (0.2) / 0.0 (0.2) | yes |

The CFI mismatch is systematic: about 0.6× in every group. The paper's "CFI combined" was evidently scored differently from `ADQS` `CFITOTAL` at visit 1 (e.g., a different handling of "maybe" items, or a different visit). Because CFI enters the R² models only as one covariate, this does not change the conclusions.

### Key results

| Quantity | Paper | Reproduced | Match |
|---|---|---|---|
| Amyloid tertile cut-points (A4) | <46; 46.1–77.2; >77 CL | 46.1, 77.2 CL | exact |
| p-tau217 tertile cut-points | not reported | 0.195, 0.283 U/mL | n/a |
| **Total R², PACC change at wk 240** | | | |
| LEARN | 0.163 | 0.104 (N=476) | **no** |
| LEARN + all A4 | 0.341 | 0.329 (N=1539) | yes (±0.012) |
| A4 placebo | 0.324 | 0.325 (N=541) | yes |
| A4 solanezumab | 0.340 | 0.324 (N=522) | yes (±0.016) |
| A4 combined | 0.329 | 0.318 (N=1063) | yes |
| Tau substudy, placebo | 0.515 | 0.501 (N=178) | yes |
| Tau substudy, solanezumab | 0.356 | 0.358 (N=173) | yes |
| Tau substudy, combined | 0.401 | 0.395 (N=351) | yes |
| Range of R² across models | 30–52% | 32–50% (excluding LEARN) | yes |
| **Largest unique R², full sample / A4 arms** | "P-tau217 consistently largest unique" | p-tau217 largest in LEARN+A4 (U=0.094), solanezumab (0.121), A4 combined (0.102). In placebo, baseline PACC U=0.093 vs p-tau217 0.073 | mostly |
| Amyloid PET unique R² | "very little" | 0.000–0.003 in every model (common R² ≈ 0.10) | yes |
| **Tau substudy: neocortical tau** | "largest R², P-tau217 remained significant" | Tau has the largest unique R² in combined (0.070, p=1e-9) and solanezumab (0.081). Tau has the largest unique+common in combined (0.225 vs p-tau217 0.201). In placebo, PACC is marginally larger (0.279 vs 0.266). p-tau217 still significant in all three (p ≤ 0.004) | yes |
| CDR-GS progression, highest p-tau217 tertile | ">50%" (Results) / "nearly 50%" (Discussion) | KM 52.4% (46.5–57.7) at wk 240 | yes |
| CDR-GS progression, highest amyloid tertile | same wording | KM 45.8% (39.9–51.1) at wk 240 | approx. ("nearly 50%") |
| CDR-GS progression, LEARN | figure only | 14.5% at wk 240 | n/a |

### Figure-only quantities (reproduced, no text value to compare)

Model-estimated change at week 240, from the spline mixed model with LEARN as the reference group:

| Group | PACC | CFI | ADL | CDR-SB |
|---|---|---|---|---|
| LEARN | +0.30 | +0.50 | −0.61 | +0.18 |
| Amyloid T1 / T2 / T3 | −0.10 / −1.09 / −2.71 | +0.68 / +1.93 / +2.77 | −0.69 / −1.82 / −3.47 | +0.32 / +0.64 / +1.11 |
| p-tau217 T1 / T2 / T3 | +0.24 / −0.55 / −3.49 | +0.22 / +1.50 / +3.63 | −0.29 / −1.43 / −4.23 | +0.24 / +0.53 / +1.30 |

The gradients are qualitatively consistent with Figures 1–2. The top p-tau217 tertile separates from the others more than the top amyloid tertile does. Full CIs are in `output/main_tertile_trajectories.csv`.

**Verdict A: largely reproduced.**
- Five of eight total-R² values are within 0.012, and all A4 and tau-substudy values are within 0.016.
- The qualitative rankings reproduce:
  - p-tau217 dominates the unique R² in the overall and A4 samples.
  - Amyloid PET has almost no unique R².
  - Neocortical tau is the strongest predictor in the tau substudy.
  - The top p-tau217 tertile has about 50% CDR-GS progression.
- The tau-substudy N (351 vs 350) and the amyloid tertile cut-points match.
- Main discrepancies:
  - LEARN-only R² (0.104 vs 0.163): LEARN N differs (538 vs 553 enrolled; 476 analysed), and the step-1 model specification is unknown.
  - Baseline CFI scale: see the note under the Table 1 comparison.
  - In placebo, baseline PACC rather than p-tau217 carries the largest unique R².

### Deviations and assumptions (A)

1. **Analysis windows.**
   - A4: mITT, `EPOCH == "BLINDED TREATMENT"` plus visit 006 (as in the package vignette).
   - LEARN: `EPOCH == "Analysis visit <= 66"`.
   - Time is `ADURW` (weeks), floored at 0. For functional outcomes the screening visit (001) is the baseline.
2. **Step 1.** A separate lme per cohort (LEARN, placebo, solanezumab):
   - Fixed effects: ns(week, 2 df) + age + education + APOE4 + PACC version.
   - Random effects: intercept + linear slope (years).
   - Individual change at wk 240 = fixed spline change + BLUP slope × 240/52.
   - The paper's exact random-effects structure, and whether tertile groups entered step 1, are not stated. A heterogeneous-Toeplitz GLS (Fig. 1 legend) gives no participant-level change, so step 1 must be a random-effects model.
3. **Step 2.**
   - OLS on CL, raw p-tau217, baseline PACC (visit 6), baseline CFI (visit 1), age, APOE4, female, education, URG (non-White or Hispanic), and treatment.
   - Treatment is a 3-level factor (LEARN/Pbo/Sola) in the pooled analysis and dropped within a single arm.
   - Unique R² = R²(full) − R²(full minus predictor). Common R² = R²(predictor alone) − unique. p-values come from nested F-tests.
   - Only predictors that vary are included, so within-arm models have 9 predictors.
4. **p-tau217:** raw (`ORRESRAW`) value at the protocol baseline visit, untransformed.
5. **Tau:**
   - Unweighted mean of the 8 FreeSurfer VOIs (L/R inferior temporal, fusiform, middle temporal, inferior parietal) from the first tau scan.
   - Cerebellar crus reference, because `suvr_cer` is empty for tau in this release.
   - The paper's reference region is not stated (A4 tau work typically uses cerebellar grey).
6. **Tertiles:** computed within A4 mITT, with both arms pooled for the trajectory and KM figures. LEARN is its own group.
7. **KM:** the event time is the first of two consecutive CDR-GS > 0 visits, or a CDR-GS > 0 at the last double-blind visit. Estimates are reported at weeks 204 and 240; the paper's time point is unspecified.
8. **Convergence:** nlme with `opt = "optim"`. Some trajectory fits emit "singular precision matrix" warnings, but the fits converge. The default nlminb optimiser fails to converge.

---

## Candidate injected-error types

| # | Plausible analyst mistake | Expected symptom |
|---|---|---|
| 1 | Use `ORRES` (censored: <LLOQ/>ULOQ → NA) instead of `ORRESRAW` for p-tau217 | Drops about 40% of LEARN; biases AUROC and R² down. **Run (E1, M1).** |
| 2 | Drop the amyloid-negative LEARN cohort from the ROC (spectrum change) | AUROC at 33 CL falls. **Run (E2).** |
| 3 | Wrong Centiloid transform (ADNI whole-cerebellum FBP equation 196.9·SUVR − 196.03 applied to A4 SUVR) | Shifts the 20/33 CL classifications. **Run (E3).** |
| 4 | Leakage or optimism: covariate-augmented ROC model evaluated in-sample, or Youden cut-off chosen and evaluated in the same data | Inflated AUROC or accuracy. **Run (E4)**: negligible here. |
| 5 | Wrong tau region or reference (entorhinal only; white-matter reference) | Changes tau unique R². **Run (M2a/M2b).** |
| 6 | Wrong time window: include open-label (A4) and post-week-240 (LEARN) PACC in step 1 | Inflates R². **Run (M3).** |
| 7 | Use observed wk-240 change in completers instead of model-based change | Loses about 30% of N and lowers R². **Run (M4).** |
| 8 | Ignore treatment arm: pool arms in step 1 and drop the treatment term | **Run (M5).** |
| 9 | Use A4 randomised rather than mITT, or count rescreened BIDs twice | Ns off by tens. Not run. |
| 10 | Time zero = screening (visit 001) PACC instead of week-0 visit 006 | Biases baseline-PACC effects (practice effect). Not run. |

### Measured impact

**Paper B (AUROC):**

| Variant | N | AUROC ≥20 CL | AUROC ≥33 CL |
|---|---|---|---|
| Correct | 1626 | 0.866 | 0.887 |
| E1: censored `ORRES` | 1466 (LEARN 394) | 0.845 (−0.021) | 0.865 (−0.022; CI excludes the published 0.89) |
| E2: A4 only, no LEARN | 1102 | 0.874 (only 40 negatives; CI 0.83–0.92) | **0.854 (−0.033)** |
| E3: ADNI CL equation | 1626 | 0.876 (1087 vs 1127 positives) | 0.884 (926 vs 992 positives) |
| E4: logistic p-tau217 + age + APOE4, in-sample vs 10-fold CV | 1624 | 0.879 vs 0.878 | 0.897 vs 0.896 (no meaningful optimism with 3 predictors) |
| E5: strict protocol-baseline visit (no fallback) | 1545 | 0.867 | 0.886 (N no longer matches Table 1; AUROC robust) |

**Paper A:** total R² for the A4 combined sample (paper 0.329), and unique R² of p-tau217 / tau in the tau substudy combined (correct: 0.395 total; U_ptau 0.046; U_tau 0.070).

| Variant | A4 combined R² | LEARN R² | Tau-combined R² | U p-tau217 (A4 comb.) | U tau (tau comb.) |
|---|---|---|---|---|---|
| Correct | 0.318 | 0.104 | 0.395 | 0.102 | 0.070 |
| M1: censored `ORRES` | 0.296 (N 981) | 0.092 (N 285) | 0.394 | 0.083 | 0.073 |
| M2a: entorhinal-only tau | n/a | n/a | 0.414 | n/a | 0.089 |
| M2b: neocortical, WM reference | n/a | n/a | 0.425 | n/a | 0.100 (U_ptau falls to 0.030) |
| M3: + open-label PACC | 0.336 | 0.094 | 0.423 | 0.112 | 0.066 |
| M4: observed wk-240 change (completers) | **0.235** (N 774) | 0.171 (N 285) | **0.270** | 0.096 | 0.070 |
| M5: arms pooled, no treatment term | 0.320 | 0.104 | 0.401 | 0.102 | 0.072 |

What the injected errors show:
- **M4 has the largest effect.** It drops total R² by about 0.08–0.12 and N by about 30%, while the ranking (p-tau217 > amyloid) survives.
- **E1/M1 are the most "silent" errors.** They look like a normal analysis but remove low-end LEARN values, cutting AUROC by about 0.02 and LEARN N by 40%.
- **E2 shows spectrum dependence.** Dropping LEARN lowers AUROC at 33 CL by 0.03.
- **M2 changes the tau story.** A white-matter reference or an entorhinal ROI makes tau look stronger (U_tau up 0.02–0.03) and p-tau217 weaker in the tau substudy.
- **M5 is nearly harmless here,** because solanezumab had no effect.

## Files

- `reproduce_main.R`, `reproduce_rissman.R`: analysis scripts.
- `output/main_*.csv`: population, Table 1, tertile trajectories, KM, commonality, total R², injected errors.
- `output/rissman_*.csv`: Table 1, ROC, correlations, longitudinal, injected errors.
