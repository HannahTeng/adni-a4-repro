# A4 Trial Primary Results: Reproduction Report

Target: Sperling et al., "Trial of Solanezumab in Preclinical Alzheimer's Disease", *NEJM* 2023;389:1096–107 (doi:10.1056/NEJMoa2305032).
Tool: ATRI's official `A4LEARN` R package and its "A4 Primary Results" vignette.
Date run: 2026-10-28. Data were read only from the locally installed package; this report contains aggregate numbers only.

**Bottom line:** the primary endpoint reproduces exactly: −1.43 vs −1.13, difference −0.30 (95% CI −0.82 to 0.22), P = 0.26. So do the randomized and mITT Ns and the baseline table. The CFI and ADL point estimates also match. CDR-SB is close but not exact. Amyloid PET matches only qualitatively, because I used an observed-data summary rather than the paper's model. ARIA-E cannot be reproduced from this package.

## 1. Environment

| Item | Value |
|---|---|
| OS | macOS 27.0 (aarch64-apple-darwin27.0.0) |
| R | 4.6.1 (2026-06-24), Homebrew build at `/opt/homebrew/bin/R` |
| A4LEARN | 1.1.20250808 (`data_download_date` = 2025-08-08) |
| Tarball | `A4LEARN_1.1.20250808.tar.gz`, SHA-256 `c5d17261…adf414ef1224` |
| nlme / emmeans / clubSandwich | 3.1-169 / 2.0.4 / 0.7.0 |
| arsenal / kableExtra / Hmisc | 3.7.4 / 1.4.1 / 5.3.0 |
| tidyverse / dplyr | 2.0.0 / 1.2.1 |
| rmarkdown / knitr / pandoc | 2.32 / 1.52 / 3.12.1 |

The full `sessionInfo()` is in `output/sessionInfo.txt`.

Three package versions were available locally (1.0.20241030, 1.1.20250808, 1.2.20260114); only 1.1.20250808 was used here.

## 2. What was run

All paths below are relative to `a4/`.

1. **Install** (log: `output/install.log`):
   ```r
   install.packages(c("arsenal","kableExtra","clubSandwich","Hmisc"))   # CRAN; others already present
   install.packages("A4LEARN_1.1.20250808.tar.gz", repos = NULL, type = "source")
   ```
   Dependencies were taken from the tarball's DESCRIPTION file, which imports `rmarkdown` and suggests knitr, tidyverse, arsenal, kableExtra, nlme, emmeans, splines, clubSandwich, Hmisc and dplyr, and cross-checked against every `library()` call and `pkg::` reference in the vignettes. Neither `mmrm` nor `gtsummary` is used.
2. **Verify load:** `library(A4LEARN)` loaded cleanly. The package has 54 datasets; their names and dimensions are in `output/datasets.txt` (for example ADQS 247,289×81, SUBJINFO 6,945×64).
3. **Vignettes:** `vignettes/A4-Primary-Results.Rmd` loads a child file through the relative path `../man/rmd/A4-Primary-Results-child.Rmd`. Both `vignettes/` and `man/rmd/` were therefore extracted from the tarball into `a4/` to keep that path valid. Both vignettes were then rendered with `render.R`:
   ```r
   rmarkdown::render("vignettes/A4-Primary-Results.Rmd", output_dir = "output")                  # ~29 s
   rmarkdown::render("vignettes/A4-LEARN-Baseline-Characteristics.Rmd", output_dir = "output")   # <1 s
   ```
   Outputs: `output/A4-Primary-Results.html` and `output/A4-LEARN-Baseline-Characteristics.html`.
4. **Supplementary checks:** `supplementary.R` (output: `output/supplementary.txt`) does three things the vignette doesn't:
   - prints the PACC results to more decimal places, with per-arm CIs;
   - fits the vignette's spline GLS model to CFI, ADL-partner and CDR-SB;
   - computes the observed change in amyloid PET centiloids.

## 3. Analysis specification used by the vignette

- **Population:** modified intention-to-treat (`MITTFL == 1`): randomized participants who received at least one dose and were assessed for the primary endpoint. That is 1,147 people (placebo 583, solanezumab 564).
- **Data:** PACC records (`QSTESTCD == "PACC"`) from `EPOCH == "BLINDED TREATMENT"`, plus the baseline visit (`AVISIT == "006"`), with complete cases on the covariates. That gives 10,822 observations.
- **Model:** a natural cubic spline model (Donohue et al., *Pharm Stat* 2023), fitted with `nlme::gls`. It is **not** an MMRM.
  - Time is `ADURW`, weeks since randomization, expanded with `ns(df = 2)` and boundary knots at 0 and the maximum week.
  - There are spline × treatment interaction terms but no treatment main effect, so the groups are constrained to have equal means at baseline.
- **Covariates:** PACC test version (`QSVERSION`), age, education, APOE ε4 carrier status (`AAPOEGNPRSNFLG`), and baseline florbetapir SUVR (`SUVRCER`).
- **Covariance:** heterogeneous Toeplitz: `corARMA(p = 10)` within participant plus `varIdent` by visit sequence. The vignette says heterogeneous unstructured, the first choice in the paper's prespecified sequence, did not converge.
- **Inference:** cluster-robust CR2 sandwich variance (`clubSandwich::vcovCR`), with `emmeans` and `mode = "satterthwaite"`. The contrast is solanezumab vs placebo at week 240.

## 4. Comparison with the published paper

Published values were checked against the paper's full text (PMC10559996).

**Match key:** *exact* means equal at the paper's printed precision. *Rounding* means within the last printed digit. *Close* means the same direction and nearly the same size, but not equal. *Not reproducible* means the package doesn't contain the needed data or analysis.

### 4a. Populations

| Quantity | Published | Reproduced | Match |
|---|---|---|---|
| Randomized, total | 1,169 | 1,169 (`SUBJINFO$TX`) | exact |
| Randomized, solanezumab / placebo | 578 / 591 | 578 / 591 | exact |
| mITT, solanezumab / placebo | 564 / 583 | 564 / 583 | exact |
| Underwent screening amyloid PET | 4,485 | 4,486 (Baseline vignette) | mismatch by 1 |
| Elevated amyloid at screening | 1,322 | 1,323 (Baseline vignette) | mismatch by 1 |
| PACC "No. evaluated" at final visit, solanezumab / placebo | 401 / 423 | 407 / 427 (with a visit-11 PACC) | mismatch (definition) |

### 4b. Baseline characteristics (mITT; paper Table 1 vs the vignette's `tableby`)

| Quantity (solanezumab / placebo) | Published | Reproduced | Match |
|---|---|---|---|
| Age, mean (y) | 72 overall | 72.0 / 71.9 | exact |
| Female | ~60% | 58.3% / 60.4% (59.4% overall) | exact |
| Hispanic or Latino, n (%) | 16 (2.8) / 18 (3.1) | 16 (2.8) / 18 (3.1) | exact |
| APOE ε4 carrier, n (%) | 333 (59.0) / 342 (58.7) | 333 (59.0) / 342 (58.7) | exact |
| APOE ε3/ε4, n | 273 / 273 | 273 / 273 | exact |
| Florbetapir SUVR | 1.3±0.2 / 1.3±0.2 | 1.3 (0.2) / 1.3 (0.2) | exact |
| Centiloids | 66.2±33.5 / 65.9±32.1 | 66.2 (33.5) / 65.9 (32.1) | exact |
| PACC | 0.0±2.8 / 0.0±2.6 | 0.0 (2.7) / −0.0 (2.6); unrounded SD 2.75 / 2.62 | rounding |
| LM Delayed Recall | 12.6±3.8 / 12.7±3.5 | 12.6 (3.8) / 12.7 (3.5) | exact |
| MMSE | 28.8±1.3 / 28.8±1.2 | 28.8 (1.3) / 28.8 (1.2) | exact |
| CFI combined | 4.0±3.6 / 3.6±3.3 | 4.0 (3.6) / 3.6 (3.3) | exact |
| ADL partner | 43.4±2.7 / 43.5±2.6 | 43.4 (2.7) / 43.5 (2.6) | exact |
| CDR-SB | 0.1±0.2 / 0.0±0.2 | 0.1 (0.2) / 0.0 (0.2) | exact |

### 4c. Primary endpoint: change in PACC from baseline to week 240 (vignette output)

| Quantity | Published | Reproduced | Match |
|---|---|---|---|
| Solanezumab, adjusted mean change (95% CI) | −1.43 (−1.83 to −1.03) | −1.43 (−1.83 to −1.02); SE 0.205 | exact (upper limit within rounding) |
| Placebo, adjusted mean change (95% CI) | −1.13 (−1.45 to −0.81) | −1.13 (−1.45 to −0.81); SE 0.164 | exact |
| Difference vs placebo | −0.30 | −0.30 (unrounded −0.298); SE 0.264 | exact |
| 95% CI of difference | −0.82 to 0.22 | −0.82 to 0.22 (−0.816 to 0.220) | exact |
| P value | 0.26 | 0.26 | exact |

### 4d. Key secondary endpoints

These come from `supplementary.R`, **not** from the vignette. They use the same spline GLS, CR2 standard errors and Satterthwaite df as the primary analysis, with no test-version term. Baseline is screening visit 001 plus the blinded-phase visits. Heterogeneous Toeplitz converged for all three.

| Quantity (week 240) | Published (Table 2) | Reproduced | Match |
|---|---|---|---|
| CFI: change, solanezumab / placebo | 2.09 / 1.51 | 2.09 / 1.51 | exact |
| CFI: difference (95% CI) | 0.58 (−0.18 to 1.34)\* | 0.58 (0.02 to 1.14), nominal P = 0.041 | estimate exact; CI not comparable\* |
| ADL partner: change, solanezumab / placebo | −2.24 / −1.63 | −2.24 / −1.63 | exact |
| ADL partner: difference (95% CI) | −0.61 (−1.44 to 0.23)\* | −0.61 (−1.27 to 0.06), nominal P = 0.074 | estimate exact; CI not comparable\* |
| CDR-SB: change, solanezumab / placebo | 0.71 / 0.60 | 0.70 / 0.55 | **close** (mismatch) |
| CDR-SB: difference (95% CI) | 0.12 (−0.06 to 0.29)\* | 0.15 (−0.01 to 0.31), nominal P = 0.060 | **close** (mismatch) |
| "No significant differences" | none claimed (graphical testing stopped at the primary) | n/a | consistent; see the flag in §5 |

\* The paper's secondary-endpoint CIs are adjusted for multiplicity under its graphical testing scheme (Table 2 footnote), so they are wider than my unadjusted 95% CIs. The point estimates are the right thing to compare.

### 4e. Amyloid PET and ARIA

| Quantity | Published | Reproduced | Match |
|---|---|---|---|
| Amyloid increased in both groups | yes: +11.6 CL solanezumab, +19.3 CL placebo | yes: +12.6 CL (n=397) solanezumab, +21.2 CL (n=420) placebo | qualitative; numbers differ (method) |
| Placebo − solanezumab difference in change | 7.7 CL (95% CI 5.1 to 10.4) | 8.6 CL (95% CI 5.6 to 11.5), Welch t-test | close (method) |
| ARIA-E, solanezumab / placebo | 1 (0.2%) / 2 (0.3%), safety population 572 / 591 | not reproducible | not available in A4LEARN 1.1 |
| ARIA-H, solanezumab / placebo | 167 (29.2%) / 194 (32.8%) | not attempted | — |

## 5. Mismatches, warnings and flags

1. **CDR-SB (0.70 / 0.55 vs 0.71 / 0.60; difference 0.15 vs 0.12).** This is the only modeled estimate that doesn't match. The vignette has no CDR-SB code, so I applied the PACC model specification myself. The likely cause is model specification: the paper's CDR-SB model may differ in visit windowing, baseline visit, covariance structure, or how visits delayed by COVID were handled, and the SAP isn't in the package. A different data cut is also possible. My numbers should be treated as an approximate re-analysis, not an official reproduction.
2. **Amyloid PET numbers.** Observed baseline (visit 2) to week-240 (visit 66) changes were computed in completers only. Centiloids were converted with the package's formula, 183.07 × SUVR − 177.26, from `Composite_Summary`. The paper reports model-based estimates (Fig. S3A) and warns that inference from them is limited. So a gap of about 1–2 CL is expected; the direction and overall size agree.
3. **ARIA-E cannot be reproduced.** A4LEARN 1.1 has no adverse-event dataset. `imaging_MRI_reads` contains only microhemorrhage (MCH) and superficial siderosis reads, which relate to ARIA-H. `PXEDEMA` in `phyneuro` is peripheral edema from the physical exam, not ARIA. Your claim, "low and similar between groups", matches the paper: 1 vs 2 cases.
4. **"No. evaluated" at the final visit: 407 / 427 vs 401 / 423.** The paper counts "participants who had a final visit". I counted participants with a PACC at visit sequence 11 (visit 066). The definitions probably differ, for example a final visit vs a visit-066 PACC, or the handling of visits delayed past week 240. A data-cut difference is also possible. This doesn't affect the model estimates.
5. **Screening counts off by one (4,486 / 1,323 vs 4,485 / 1,322).** This comes from the Baseline vignette, which reproduces Sperling et al. 2020 (*JAMA Neurol*), not the NEJM paper. The likely cause is how re-screened participants are de-duplicated, or the 2025 data cut.
6. **Baseline PACC SD (2.7 vs 2.8, solanezumab arm).** The unrounded SD is 2.75, so this is a rounding difference.
7. **Wording in the published abstract.** Three points to keep in mind when quoting the results:
   - The paper calls the instrument the "ADCS Activities of Daily Living **Prevention Questionnaire** (partner)", not "ADCS-ADL-PI".
   - The paper doesn't say the secondaries showed "no significant differences". It says the graphical testing scheme didn't allow significance claims because the primary endpoint failed. Unadjusted, the CFI difference has a nominal P of 0.04 (worse in the solanezumab group), so "not formally tested" is more accurate.
   - The amyloid increase was numerically **larger in the placebo group** (19.3 vs 11.6 CL). That detail is worth keeping alongside "increased in both groups".
8. **Satterthwaite df.** The vignette reports df = 10,791, which is close to the number of observations rather than the 1,147 clusters. With a CR2 robust vcov supplied, emmeans appears to fall back to residual-type df for `gls`. At these magnitudes the t and normal CIs are effectively identical, so the published values are unaffected. It is a methodological caveat if this code is reused for small-sample work.
9. **Render warnings.** The only warnings were pandoc 3.12's "Deprecated: --mathjax", which is cosmetic. The vignette chunks set `warning = FALSE`, so model-fitting warnings would be suppressed. All fits converged.

## 6. Install and run issues

- **Missing suggested packages:** arsenal, kableExtra, clubSandwich and Hmisc were installed from CRAN, along with their dependencies (sandwich, zoo, svglite, htmlTable, Formula and others). No system software was installed.
- **Child-document path:** the vignette's relative child path needs `man/rmd/` to sit next to `vignettes/`. Both were extracted from the tarball, so no change to the vignette was needed.
- **Supplementary script scoping:** the first version of `supplementary.R` failed with `object 'f' not found`, because emmeans and clubSandwich re-evaluate the `gls` call. Building the call with `do.call("gls", ...)` resolved it. The vignette itself was unaffected.

## 7. Data-use notes

- Data was read only from the locally installed package. Nothing was uploaded, and only aggregates were printed.
- The rendered `A4-Primary-Results.html` contains a **spaghetti plot of individual participants' PACC trajectories**. That is participant-level data, so keep the HTML local and don't share it under the DUA.
