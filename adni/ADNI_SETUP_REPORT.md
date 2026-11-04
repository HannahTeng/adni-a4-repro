# ADNI Setup Report — ADNIMERGE2

Generated 2026-11-02. All numbers below are aggregates (counts, means, model estimates). No participant-level rows were printed, and no data left the machine.

## 1. Environment

| Item | Value |
|---|---|
| R | 4.6.1 (2026-06-24), Homebrew, `/opt/homebrew/bin/R` |
| Package | **ADNIMERGE2 0.1.4** (new CDISC-style package; built 2026-10-05 by ATRI Biostatistics) |
| Data cut | **2026-10-05** (`ADNIMERGE2::DATA_DOWNLOADED_DATE`) |
| Package library | project-local `adni/Rlib` (set via `adni/.Renviron`, `R_LIBS_USER`) |
| pandoc | `/opt/homebrew/bin/pandoc` |

**Input.** The LONI IDA download (`download.zip`, 145.8 MB) contains three files, extracted to `adni/raw/`:

| File | Size |
|---|---:|
| `ADNIMERGE2.tar.gz` | 131.4 MB |
| `ADNIMERGE2_R_Package_Methods_20260105.pdf` | 227 KB |
| `DATADIC_02Nov2026.csv` (LONI data dictionary, dated today) | 14.1 MB |

## 2. Install

```r
install.packages("raw/ADNIMERGE2.tar.gz", repos = NULL, type = "source")   # into adni/Rlib
```

- **Missing hard dependency:** `assertr` (CRAN).
- **Vignette dependencies installed:** gtsummary, labelled, see, consort, marginaleffects, performance, lme4.
- **Result:** `library(ADNIMERGE2)` loads. `packageVersion("ADNIMERGE2")` returns `0.1.4`.
- **Package contents:** 235 objects, of which 233 are data frames. The other two are `DATA_DOWNLOADED_DATE` and `METACORES`, an R6 metadata-spec object that needs the Suggests-only package `metacore`.

## 3. Dataset inventory (key analysis-ready datasets)

The full 235-row inventory (name, rows, cols, participants, description) is in the Appendix and in `output/dataset_inventory.csv`.

| Domain | Dataset(s) | Rows × cols | Participants | Key variables |
|---|---|---|---:|---|
| Subject-level (derived) | `ADSL` | 5,138 × 56 | 5,138 (3,041 enrolled) | ORIGPROT, ENRLFL, DX, AGE, SEX, EDUC, APOE, AMYSTAT, TRACER, baseline ADAS/CDR/MMSE/FAQ/MoCA, MPACCTRAILSB, MPACCDIGIT |
| Longitudinal questionnaires (derived) | `ADQS` | 327,599 × 36 | 4,859 | 23 PARAMCDs: ADASTT11/13, CDRSB, CDGLOBAL, MMSCORE, FAQTOTAL, MOCA, MPACC*; AVISITN, ADY, ADT, ABLFL, BASE, CHG |
| PACC composite (derived) | `PACC` | 19,852 × 28 | 4,774 | mPACCtrailsB, mPACCdigit, component z-scores, visit dates |
| Diagnosis | `DXSUM`, `ADRS` | 16,504 × 42; 16,714 × 34 | 3,774; 3,711 | DIAGNOSIS / DX |
| APOE | `APOERES` | 3,216 × 17 | 3,216 | GENOTYPE |
| Amyloid PET | `UCBERKELEY_AMY_6MM`; `ADSP_PHC_PET_Amyloid_Simple` | 4,728 × 345; 4,756 × 26 | 2,240; 2,209 | SUMMARY_SUVR, CENTILOIDS, AMYLOID_STATUS, TRACER |
| Tau PET | `UCBERKELEY_TAU_6MM`, `UCBERKELEY_TAUPVC_6MM`, `ADSP_PHC_PET_Tau_*` | ~2.3–2.5k rows | ~1.3–1.4k | META_TEMPORAL_SUVR, Braak ROIs |
| CSF | `UPENNBIOMK_ROCHE_ELECSYS`, `UPENNBIOMK_MASTER`, `ADSP_PHC_CSF` | 3,174; 5,876; 2,173 | 1,660; 1,249; 1,249 | ABETA42/40, TAU, PTAU |
| Plasma p-tau217 | `UPENN_PLASMA_FUJIREBIO_QUANTERIX` (Fujirebio Lumipulse `pT217_F`, `pT217_AB42_F`; Quanterix NfL/GFAP); `C2N_PRECIVITYAD2_PLASMA` (C2N `pT217_C2N`, `pT217_npT217_C2N`, APOE_C2N); `ADSP_PHC_PLASMA` (`pTau217_RAW`, `PHC_pTau217`) | 2,422; 1,069; 1,720 | 1,595; 926; 1,299 | — |
| Other plasma | `UGOTPTAU181`, `BLENNOWPLASMANFL(LONG)`, `FNIHBC_BLOOD_BIOMARKER_TRAJECTORIES` | — | — | p-tau181, NfL, FNIH biomarker panel |
| Cognition (raw) | `MMSE`, `CDR`, `NEUROBAT`, `MOCA`, `FAQ`, `ITEM` (ADAS items) | — | — | — |
| Visit dates | Carried in each table | — | — | ADT/ADY in ADQS; EXAMDATE/SCANDATE/VISDATE in raw tables |

**Enrolled participants in `ADSL`** (`ENRLFL = "Y"`, N = 3,041):

| Variable | Breakdown |
|---|---|
| ORIGPROT | ADNI1 819, ADNIGO 131, ADNI2 790, ADNI3 696, ADNI4 538, **TEAM 67** |
| Baseline DX | CN 1,206, MCI 1,299, DEM 467; 69 enrolled with no baseline DX |

**Whole `ADSL`** (N = 5,138, including screen failures):

| Variable | Breakdown |
|---|---|
| AMYSTAT | Elevated 832, Non-elevated 951, missing 3,355 |
| TRACER | FBP 1,241, FBB 542 |
| APOE | ε3/ε3 1,516, ε3/ε4 1,082, ε4/ε4 295, ε2/ε3 237, ε2/ε4 76, ε2/ε2 10, missing 1,922 |

## 4. Vignettes rendered

Rendered with `scripts/02_render_vignettes.R` into `adni/output/`. All three ran without errors.

| Vignette | Output | Runtime |
|---|---|---:|
| ADNI-Enrollment | `output/ADNI-Enrollment.html` | 3.3 s |
| ADNI-Longitudinal | `output/ADNI-Longitudinal.html` | 3.1 s |
| ADNIMERGE2-PACC | `output/ADNIMERGE2-PACC.html` | 7.4 s |

**Integrity check method.** `scripts/03_compare.py` diffs each re-rendered HTML against the prebuilt vignette shipped in the tarball (`inst/doc`, same 2026-10-05 data cut). It compares every gtsummary table cell, every printed `#>` model-output line, and the DT summary tables. The script was self-tested: reference vs reference gives 0 differences.

| Vignette | Values compared | Differences |
|---|---:|---:|
| ADNI-Enrollment | 1,118 table cells | **0** |
| ADNI-Longitudinal | 17 model-output lines (warning lines excluded) | **0** |
| ADNIMERGE2-PACC | 5 standardization-summary rows | **0** |

The **online articles** (https://atri-biostats.github.io/ADNIMERGE2/, "Last Updated: October 06, 2026") show the same numbers as the bundled vignettes.

### Enrollment check

The reproduced counts come from the re-rendered vignette and were also recomputed independently from `ADSL` in `scripts/04_reproduce_and_perturb.R`.

| Quantity | Reference (vignette = online article) | Reproduced | Match |
|---|---:|---:|:---:|
| Enrolled, total | 3,041 | 3,041 | ✅ |
| ADNI1 | 819 | 819 | ✅ |
| ADNIGO | 131 | 131 | ✅ |
| ADNI2 | 790 | 790 | ✅ |
| ADNI3 | 696 | 696 | ✅ |
| ADNI4 | 538 | 538 | ✅ |
| TEAM | 67 | 67 | ✅ |
| Baseline CN | 1,206 | 1,206 | ✅ |
| Baseline MCI | 1,299 | 1,299 | ✅ |
| Baseline DEM | 467 | 467 | ✅ |
| With baseline DX (Table 2 N) | 2,972 | 2,972 | ✅ |
| Age, overall mean (SD) | 72.2 (7.6) | 72.2 (7.6) | ✅ |
| Female, overall n (%) | 1,539 (50.7%) | 1,539 (50.7%) | ✅ |

**Note on TEAM.** The usual phase list (ADNI1/GO/2/3/4) leaves out the **TEAM** phase (67 enrolled; the package assigns RID 12000 to TEAM). ADNI1–4 alone sum to 2,974, not 3,041. There is no data-date discrepancy: the package, the bundled vignettes and the online articles are all the 2026-10-05 cut.

## 5. Reproduction-target candidates (each vignette = one candidate)

| # | Vignette | Question | Datasets | Model type | Key reported numbers | Runs here? | Runtime |
|---|---|---|---|---|---|---|---:|
| 1 | **ADNI-Enrollment** | Who was enrolled, by phase and by baseline DX? | ADSL | Descriptive (gtsummary Table 1 by phase, Table 2 by DX) | Ns by phase/DX; age, sex, education, race, APOE, CDR-SB, MMSE, ADAS13, FAQ, mPACC by group | ✅ reproduced | 3.3 s |
| 2 | **ADNI-Longitudinal** | How does ADAS-Cog13 change over time by baseline DX? | ADSL, ADQS | LMM: natural spline (df = 2) × DX + random intercept and slope (lme4); population predictions | REML 79049.76; 12,927 obs / 2,958 subjects; 9 fixed effects; RE SDs 5.643 / 2.126, corr 0.53, residual 3.370 | ✅ reproduced | 3.1 s |
| 3 | **ADNIMERGE2-PACC** | Compute modified PACC (mPACCtrailsB, mPACCdigit) from raw components | MMSE, NEUROBAT, ADAS, REGISTRY, DXSUM | Composite z-score (CN new-enrollee baseline standardization) | Standardization N/mean/SD for 5 components | ✅ reproduced | 7.4 s |
| 4 | ADNIMERGE2-Analysis-Data | Build ADaM datasets (ADSL, ADAE, ADQS, ADRS) from SDTM | DM, SC, NV, QS, RS, AE, … | Data derivation (admiral) | Dataset specs only (variable-list tables) | ❌ needs admiral, admiraldev, metacore, metatools, xportr | — |
| 5 | ADNIMERGE2-Derived-Data | Build SDTM-style derived datasets (DM, SC, NV, LB, VS, QS, RS) | Raw tables | Data derivation (sdtm.oak) | Variable/code lists only | ❌ needs sdtm.oak, measurements | — |
| 6 | ADNIMERGE2-Analysis-Meta-Specs | Build metadata specs for ADaM | — | Metadata | — | ❌ needs metacore; no numeric output | — |
| 7 | ADNIMERGE2-Package-Building | Rebuild the package from raw LONI CSVs | All raw CSVs | Build pipeline | — | ❌ needs the full raw CSV download; no numeric output | — |
| 8 | ADNIMERGE2 (overview) | Package usage, missing-value codes (-4, -1) | DATADIC | — | — | Not worth targeting (no analysis) | — |

**Recommendation.** Candidates 1–3 are the good targets: each runs in under 10 s with clear numeric outputs. Candidates 4–5 could become dataset-level targets (rebuild `ADSL`, then compare it to the packaged `ADSL`) after installing the pharmaverse packages, but they report no analysis numbers.

**Caveat.** The "Reference" numbers here are ATRI's own package vignettes, not peer-reviewed papers. For a journal-level target, a natural next candidate is the amyloid-elevated vs non-elevated CN PACC decline analysis (Donohue et al., *JAMA* 2017, cited in the PACC vignette), using `ADSL$AMYSTAT` and `PACC`. Its numbers will differ from the paper's because of the newer data cut, so it needs a tolerance-based comparison.

## 6. Reproduced: Reference vs Reproduced (independent script)

`scripts/04_reproduce_and_perturb.R` reruns each analysis outside the vignette (8.4 s total). Results are in `output/reproduction_results.csv`.

### A. Enrollment
Matches §4: 3,041 enrolled; 819 / 131 / 790 / 696 / 538 / 67 by phase; 1,206 / 1,299 / 467 by DX; age 72.2 (7.6).

### B. Longitudinal ADAS-Cog13 LMM

| Quantity | Reference | Reproduced | Match |
|---|---:|---:|:---:|
| N obs / N subjects | 12,927 / 2,958 | 12,927 / 2,958 | ✅ |
| REML criterion | 79049.76 | 79049.76 | ✅ |
| (Intercept) | 8.78 | 8.78 | ✅ |
| ns1(TIME) | 12.99 | 12.99 | ✅ |
| ns2(TIME) | 24.27 | 24.27 | ✅ |
| DXMCI | 7.20 | 7.20 | ✅ |
| DXDEM | 21.00 | 21.00 | ✅ |
| ns1:DXMCI | 29.33 | 29.33 | ✅ |
| ns1:DXDEM | 58.26 | 58.26 | ✅ |
| ns2:DXMCI | 31.36 | 31.36 | ✅ |
| ns2:DXDEM | 21.04 | 21.04 | ✅ |
| RE SD intercept / slope; corr; residual SD | 5.643 / 2.126; 0.53; 3.370 | identical (rendered-output diff) | ✅ |

**Derived quantity (for perturbation tests):** predicted 2-year ADAS13 change = CN +0.24, MCI +3.14, DEM +10.16.

### C. PACC standardization (CN new enrollees at baseline)

| Component | Reference N / mean / SD | Reproduced | Match |
|---|---|---|:---:|
| ADASQ4SCORE | 1201 / 2.8293 / 1.917465 | 1201 / 2.8293 / 1.917465 | ✅ |
| DIGITSCR | 229 / 45.7467 / 10.201331 | 229 / 45.7467 / 10.201331 | ✅ |
| LDELTOTL | 1205 / 12.7776 / 3.483754 | 1205 / 12.7776 / 3.483754 | ✅ |
| MMSE | 1206 / 29.0216 / 1.173511 | 1206 / 29.0216 / 1.173511 | ✅ |
| LOG_TRABSCOR | 1198 / 4.3142 / 0.407729 | 1198 / 4.3142 / 0.407729 | ✅ |

- **Check against the packaged data:** recomputed mPACCtrailsB matches the packaged `PACC` dataset on all 19,852 rows, with max abs diff 0.
- **Baseline mPACCtrailsB, mean (SD):** CN −0.01 (2.61), n = 1,206; MCI −5.35 (3.79), n = 1,299; Dementia −13.61 (3.41), n = 467.

## 7. Candidate "injected error" types (with measured impact where tested)

Each tested mistake was rerun on the real data. The impact columns show how far the headline numbers move.

| ID | Step | Mistake | Measured impact | Detectability |
|---|---|---|---|---|
| E1 | Population filter | Forget `ENRLFL == "Y"` in ADSL (screen failures kept) | N 3,041 → **5,138**; ADNI1 819 → 1,430; age 72.2 (7.6) → 72.0 (7.8) | Easy: N is wrong |
| E2 | Phase definition | Count only ADNI1/GO/2/3/4 (drop TEAM) | N 3,041 → 2,974 | Medium |
| L1 | Population filter | Forget `ENRLFL` in the ADQS longitudinal model | **No change**: non-enrolled have DX = NA and are dropped by the NA filter | **Negative control** (a benign mistake an agent should *not* flag as changing results) |
| L2 | Model / time trend | Linear TIME instead of natural spline | REML 79487.51; 2-yr change CN 0.24 → **1.06**, MCI 3.14 → 3.83, DEM 10.16 → 9.95 | Medium: CN decline ×4 |
| L3 | Random-effects structure | Random intercept only (drop random slope) | REML 84324.56; 2-yr change CN 0.44, MCI 3.15, DEM **9.20** | Medium |
| L4 | Visit-window / time definition | Actual days (ADY/365.25) instead of planned visit (AVISITN) | REML 79050.35; DEM 10.17. Negligible here | Low impact, near-negative control |
| P1 | Standardization population | Standardize on all baseline DX instead of CN only | Baseline mPACC CN −0.01 → **+2.64**, MCI −5.35 → −0.63, DEM −13.61 → −5.24 | Easy if CN mean ≠ 0 is checked |
| P2 | Baseline definition | Standardize on all CN visits, not baseline only | CN −0.08, MCI −5.06, DEM −12.71 | Subtle |
| P3 | Transformation | Skip the log of Trails B | CN −0.01 (SD 2.59), MCI −5.45, DEM −14.29 (SD 3.83) | Subtle |

### Plausible error points (untested)

- **ORIGPROT vs COLPROT.** These are the enrollment phase and the collection phase. Rollovers appear in several phases, so mixing them double-counts participants or picks the wrong baseline.
- **DX label mismatch.** `ADSL`/`ADQS` use `DEM` but `PACC` uses `Dementia`. Filtering `DX == "DEM"` on PACC silently returns n = 0. This happened during this run and was caught.
- **Screening vs baseline diagnosis.** `get_adni_blscreen_dxsum()` warns that screening-failure diagnoses can appear as "baseline" unless enrollment flags are applied.
- **Screening/baseline record adjustment** for PACC components (`adjust_scbl_record`), and visit-code harmonization (`get_common_viscode2`).
- **mPACCdigit exists only for ADNI1** (DSS: 229 CN at baseline). Using it across phases is wrong.
- **PACC direction and completeness.** ADAS Q4 and Trails B must be reverse-signed, and a minimum of 2 non-missing components is required.
- **Amyloid status** combines FBP/FBB tracers and 6 mm/8 mm resolutions (`create_amystatus_cols`). Mixing SUVR scales across tracers without Centiloids is a classic error.
- **Prediction window.** DEM predictions are truncated at 2 years by design, because follow-up ADAS for DEM is collected only up to 2 years.
- **Spline boundary knots** depend on the data's max TIME, so refitting on a subset changes the basis.
- **Missing-value codes.** `-4` (all phases) and `-1` (ADNI1) must be converted to NA (overview vignette).

## 8. Missing tables to download

None needed for the reproduced analyses. For the dropped p-tau217 vs amyloid PET question, the package already contains plasma p-tau217 (`UPENN_PLASMA_FUJIREBIO_QUANTERIX`, `C2N_PRECIVITYAD2_PLASMA`, `ADSP_PHC_PLASMA`) and amyloid PET (`UCBERKELEY_AMY_6MM`, `ADSP_PHC_PET_Amyloid_*`), so no extra LONI download is required. The overlap and discordance counts were not computed, per your instruction.

## 9. Install/run issues and fixes

| Issue | Fix |
|---|---|
| LONI download arrives as a generic `download.zip` | Extracted by `setup.sh` to `adni/raw/` |
| `install.packages(type = "binary")` unsupported (Homebrew R builds from source) | Installed from source |
| Avoid writing to the system R library | Project-local library `adni/Rlib` via `.Renviron` |
| `assertr` missing (hard dependency) | Installed from CRAN |
| Warnings `namespace 'metacore' is not available` | Harmless for these vignettes. They come from the `METACORES` R6 object; `metacore` is Suggests-only |
| pandoc `--mathjax` deprecation warning | Cosmetic, no effect |
| Comparison script initially missed `#>` lines (HTML splits them across `<span>`s) | Strip tags before matching; re-verified |
| `compute_pacc_score()` requires a *named* `componentVars` list | Used the vignette's `pacc_component_list` |
| PACC DX label is `Dementia`, not `DEM` | Fixed group labels |

## 10. Data-handling notes

- **Data location:** all data stays in `adni/raw` and `adni/Rlib`. Nothing was uploaded.
- **Web access:** the only network calls were CRAN package installs and two reads of the public ATRI documentation pages.
- **Git:** `.gitignore` excludes `raw/`, `rlib-src/`, `Rlib/`, `*.tar.gz`, `*.zip`, `*.csv`, `*.rda`, `*.rds`, `*.pdf` and similar. No git repo was initialized.
- **Methods PDF:** present in `raw/` but not used, since the cutoff-dependent feasibility step was dropped.

### Scripts

| Script | Purpose |
|---|---|
| `scripts/01_inventory.R` | Dataset inventory |
| `scripts/02_render_vignettes.R` | Render vignettes and time them |
| `scripts/03_compare.py` | Reference vs reproduced diff |
| `scripts/04_reproduce_and_perturb.R` | Independent reproduction and injected-error impact |
| `scripts/05_inventory_md.R` | Appendix table |
| `scripts/html2text.py`, `scripts/dt_widgets.py` | Extract reference numbers |
| `scripts/06_donohue2017.R` | Donohue et al. 2017 reproduction (§11) |

## 11. Journal-level reproduction: Donohue et al., JAMA 2017

**Paper.** "Association Between Elevated Brain Amyloid and Subsequent Cognitive Decline Among Cognitively Normal Persons." JAMA 2017;317(22):2305–16, [PMC5736301](https://pmc.ncbi.nlm.nih.gov/articles/PMC5736301/). The methods and numbers below come from the author manuscript.

**Script.** `scripts/06_donohue2017.R` runs 6 variants in 38 s. Results are in `output/donohue2017_results.csv`.

### What was done

| Step | Paper | This reproduction | Deviation? |
|---|---|---|---|
| Population | CN in ADNI (incl. subjective memory concern), MMSE 24–30, CDR 0, ≥1 amyloid measure, ≥1 follow-up | Enrolled, baseline DX = CN, ORIGPROT ∈ ADNI1/GO/2 (525), with ≥1 amyloid measure (448) and ≥1 PACC follow-up (440) | MMSE/CDR criteria assumed implied by ADNI CN status |
| Data window | Collected 2005-08-23 to 2016-06-07; no freeze date | Observations and amyloid measures restricted to ≤ 2016-06-07, from the 2026-10-05 cut | Later data corrections are baked into the new cut |
| Florbetapir | Composite SUVR / whole cerebellum > 1.1 (2016 Berkeley pipeline) | `UCBERKELEY_AMY_6MM` SUMMARY_SUVR > 1.11 (6 mm pipeline's own cutoff); 1.10 as sensitivity | Reprocessed pipeline |
| PiB | 0.15 + 0.67 × PiB SUVR > 1.1 | `PIBPETSUVR`: mean(ACG, FRC, LTC, PAR, PRC), same conversion | Region set assumed |
| CSF | AlzBio3 Aβ42 < 192 pg/mL | `UPENNBIOMK_MASTER`, BATCH = MEDIAN, ABETA < 192 | — |
| Combining measures | Elevated if any measure exceeds its cutoff | Same; per modality, the measure closest to enrollment | Paper interpolated SUVR back to baseline with an LMM |
| PACC | ADAS delayed recall, LM DR, MMSE, log Trails B; z-scores vs baseline | Package `compute_pacc_score()`, restandardized to this cohort's baseline (mPACCtrailsB) | — |
| Model | LMM, ML, continuous time (+t² if AIC), age + AIC-selected covariates, RE structure by AIC; LRT for group | lme4 ML; group × time (+t² if AIC); age + education + sex + APOE4 (the paper's Fig 1 reference profile); random intercept + slope; delta-method CI; LRT dropping all group terms | Covariates and RE fixed rather than AIC-selected |

### Results: Paper vs Reproduced

| Quantity | Paper | Reproduced (primary) | Assessment |
|---|---|---|---|
| N (normal / elevated) | 445 (243 / 202) | 440 (246 / 194) | Close (−1%) |
| Age, normal / elevated / overall | 73.4 / 74.7 / 74.0 | 73.1 / 75.0 / 74.0 | ✅ |
| Women % | 47 / 58 / 52 | 50 / 56 / 52 | ✅ |
| Education, years | 16.7 / 16.1 / 16.4 | 16.6 / 16.2 / 16.4 | ✅ |
| ≥1 APOE ε4, % | 16 / 42 / 28 | 16 / 43 / 28 | ✅ |
| Baseline PACC | 0.32 / −0.38 / 0.00 | 0.29 / −0.45 / −0.03 | ✅ |
| Baseline MMSE | 29.1 / 29.0 | 29.0 / 29.0 | ✅ |
| Baseline LM DR | 13.4 / 12.9 | 13.4 / 12.8 | ✅ |
| Baseline ADAS13 | 9.0 / 9.5 | 8.9 / 9.6 | ✅ |
| Follow-up, mean years | 4.2 / 3.7 / 3.9 | 4.2 / 3.9 / 4.1 | ✅ |
| Follow-up, median (IQR) | 3.1 (2.0–4.2) | 3.8 (2.0–4.3) | Differs (definition of follow-up likely differs) |
| **PACC, 4-yr difference** | **1.51 (0.94–2.08), p < .001** | **1.76 (1.02–2.50), p < .001** | ✅ Direction and significance; CIs overlap; +17% |
| **MMSE, 4-yr difference** | **0.56 (0.32–0.80), p < .001** | **0.58 (0.28–0.89), p < .001** | ✅ |
| **CDR-SB, 4-yr difference** | **0.23 (0.08–0.38), p = .002** | **0.32 (0.10–0.54), p = .004** | ✅ Direction and significance; CIs overlap |
| **LM DR, 4-yr difference** | **0.73 (−0.02 to 1.48), p = .056** | **1.35 (0.48–2.23), p = .003** | ❌ **Not reproduced.** Paper: not significant; here: significant |
| PACC LRT | χ²(2) = 46.4 | χ²(3) = 62.7; χ²(2) = 27.7 with linear time | Both p < .001 |
| CDR-SB LRT | χ²(3) = 32.0 | χ²(3) = 112.3 | Both p < .001 |
| LM DR LRT | χ²(2) = 9.8, p = .007 | χ²(3) = 13.3, p = .004 | ✅ Same conclusion |

### Robustness (4-yr difference, elevated worse)

| Variant | PACC | MMSE | CDR-SB | LM DR |
|---|---|---|---|---|
| Paper (reference) | 1.51 | 0.56 | 0.23 | 0.73 (n.s.) |
| Primary | 1.76 | 0.58 | 0.32 | 1.35 |
| Paper's time terms (linear PACC/MMSE/LM, quadratic CDR-SB) | 1.87 | 0.70 | 0.32 | 1.39 |
| FBP cutoff 1.10 (245 / 195) | 1.75 | 0.57 | 0.31 | 1.39 |
| Age-only covariate (paper's eFig 8–9 sensitivity) | 1.83 | 0.59 | 0.31 | 1.54 |
| Package mPACC (standardized on all-phase CN, not this cohort) | 1.70 | — | — | — |
| Full current data, no 2016 cutoff (247 / 195) | 1.63 | 0.45 | 0.28 | 1.34 |

**Verdict.** The headline claim reproduces under every variant: in CN participants, elevated amyloid predicts worse PACC, MMSE and CDR-SB at 4 years. The cohort size and Table 1 come within about 1% / 0.1 SD. Effect sizes are 0–40% larger than published, but every CI overlaps the paper's. The one secondary result that does **not** reproduce is Logical Memory DR. The paper reported it as borderline non-significant (p = .056); here it is clearly significant in every variant.

**Likely sources of residual difference** (each is also a candidate injected-error or ambiguity type):

1. **Baseline amyloid.** The paper interpolated baseline SUVR with an LMM; this reproduction uses the closest scan. This matters for ADNI1 participants, whose first florbetapir scan came years after baseline.
2. **SUVR pipeline.** 6 mm reprocessing vs the 2016 pipeline. The cutoff choice (1.10 vs 1.11) barely matters: it moves 1 participant.
3. **AIC-selected covariates and RE structure.** Unpublished per outcome; they are in the Supplement, which was not available at the time.
4. **Data corrections since 2016.** The 2026 cut includes later QC fixes, even when truncated at 2016-06-07.
5. **Follow-up definition.** The paper's median of 3.1 years suggests follow-up was counted differently, e.g. all visits vs PACC visits.

**Not reproduced (out of scope this round):** binary progression outcomes (GLMM + parametric bootstrap), 10-year projections, MNAR multiple-imputation sensitivity, and the supplementary eFigures.

## 12. Donohue 2017, second pass: following the Supplement's exact model specs

**Source.** The JAMA Supplementary Online Content (39 pp., NIHMS918364) was opened via PMC in Chrome and saved to `refs/donohue2017_supplement.pdf` (git-ignored). It answers most of the open questions from §11.

**Script.** `scripts/07_donohue2017_spec.R` runs 4 variants in 10 s. Results are in `output/donohue2017_spec_results.csv`.

### What the Supplement specifies, and what changed vs §11

| Item | Supplement | Implemented |
|---|---|---|
| Time terms | **Quadratic for all four outcomes** (eTables 8–11). My §11 inference from LRT df (linear PACC/MMSE/LM) was **wrong**. | group × (t + t²) for all four |
| PACC covariates | APOE4, age, female, education, ventricular volume, family history; RI + RS | Same |
| MMSE covariates | Age, female, education; RI + RS | Same |
| CDR-SB | **Age only**; **compound symmetry** with **heterogeneous variance per visit month** (no random effects) | `nlme::gls`, `corCompSymm` + `varIdent(~1 \| visit month)`, ML |
| LM DR covariates | APOE4, age, female, education, ventricular volume; RI + RS | Same |
| Baseline SUVR imputation | LMM: SUVR ~ years + age + APOE4 + PACC + RI (eTables 2–3) | Same, for participants with no scan within ±6 months of enrollment; prediction includes the BLUP |
| Baseline ventricles | LMM: years + age + APOE4 + PACC + RI/RS (eTable 4) | Classic ADNIMERGE definition: (ST30SV + ST37SV + ST89SV + ST96SV) / ST10CV × 100, from UCSFFSX + UCSFFSX51 (QC Pass/Partial); same imputation |
| Family history | Not defined | Mother/father with AD (`FHQ`) or any sibling with AD (`RECFHQ`): **40%** vs paper 39%. "Any dementia" would give 52%. |
| Follow-up requirement | eTable 5 minimum follow-up = 0.00, so participants with no follow-up were included | Not required |

### Results: Paper vs Reproduced (supplement spec)

| Quantity | Paper | §11 (first pass) | **§12 (supplement spec)** | Match |
|---|---|---|---|:---:|
| N (normal / elevated) | 445 (243 / 202) | 440 (246 / 194) | 448 (256 / 192) | ≈ |
| FBP baseline imputed (normal / elevated) | 55 / 36 | — | 59 / 39 | ✅ |
| PiB baseline imputed (normal / elevated) | 7 / 12 | — | 8 / 11 | ✅ |
| Family history % | 39 | — | 40 | ✅ |
| Ventricles %ICV, normal / elevated | 2.1 (1.1) / 2.3 (1.1) | — | 2.10 (1.06) / 2.35 (1.11) | ✅ |
| **PACC, 4 yr** | −1.51 (−2.08, −0.94) | −1.76 | **−1.60 (−2.35, −0.86)** | ✅ |
| PACC, 10 yr | −7.40 (−9.50, −5.30) | — | −7.52 (−9.58, −5.45) | ✅ |
| PACC RE: SD int / slope / corr / resid | 1.79 / 0.58 / 0.25 / 1.71 | — | 1.79 / 0.57 / 0.27 / 1.72 | ✅ |
| PACC covariates: age / female / educ / vent / FH | −0.10 / 1.17 / 0.27 / −0.19 / 0.33 | — | −0.10 / 1.06 / 0.27 / −0.24 / 0.36 | ✅ |
| **MMSE, 4 yr** | −0.56 (−0.80, −0.32) | −0.58 | **−0.54 (−0.85, −0.24)** | ✅ |
| MMSE, 10 yr | −3.27 (−4.44, −2.10) | — | −3.36 (−4.47, −2.25) | ✅ |
| MMSE RE: SD int / slope / corr / resid | 0.64 / 0.28 / −0.23 / 1.14 | — | 0.63 / 0.28 / −0.24 / 1.14 | ✅ |
| **CDR-SB, 4 yr** | 0.23 (0.08, 0.38) | 0.32 | **0.22 (0.08, 0.37)** | ✅ |
| CDR-SB, 10 yr | 2.16 (1.40, 2.91) | — | 2.16 (1.47, 2.84) | ✅ |
| CDR-SB compound-symmetry ρ | 0.49 | — | 0.48 | ✅ |
| **LM DR, 4 yr** | −0.73 (−1.48, 0.02), p = .056 | −1.35, p = .003 | **−1.17 (−2.05, −0.29), p = .009** | ❌ |
| LM DR, 10 yr | −3.93 (−6.39, −1.47) | — | −4.06 (−6.39, −1.73) | ✅ |
| LM DR RE: SD int / slope / corr / resid | 2.58 / 0.55 / 0.24 / 2.38 | — | 2.56 / 0.54 / 0.24 / 2.37 | ✅ |
| LM DR covariates: APOE4 / age / female / educ / vent | −0.58 / −0.04 / 1.16 / 0.38 / −0.25 | — | −0.58 / −0.04 / 1.06 / 0.37 / −0.30 | ✅ |

### 4-yr contrast (elevated − normal) across variants

| Variant | N (normal / elevated) | PACC | MMSE | CDR-SB | LM DR |
|---|---|---|---|---|---|
| Paper | 445 (243 / 202) | −1.51 | −0.56 | 0.23 | −0.73 (p = .056) |
| Supplement spec | 448 (256 / 192) | −1.60 | −0.54 | 0.22 | −1.17 (p = .009) |
| FBP cutoff 1.11 | 448 (257 / 191) | −1.65 | −0.56 | 0.23 | −1.24 |
| No imputation (closest scan) | 448 (250 / 198) | −1.68 | −0.58 | 0.24 | −1.26 |
| Require ≥1 follow-up | 440 (251 / 189) | −1.59 | −0.54 | 0.23 | −1.18 |

**Verdict.** With the Supplement's specs, the reproduction matches the published model closely:

- **PACC, MMSE, CDR-SB:** reproduced. Point estimates are within 0.1 at 4 years and 10 years, and the variance components and covariate coefficients are within about 0.1.
- **LM DR at 10 years:** reproduced (−4.06 vs −3.93).
- **LM DR at 4 years:** still does not reproduce. The paper's borderline non-significant result (p = .056) comes out clearly significant here (p ≈ .005–.009) under every variant. Its long-run trajectory and variance components match, so the gap is in the early years (2-yr contrast −0.54 vs −0.27).

**Remaining leads for LM DR and the 13-person group split** (256/192 vs 243/202):

1. **Observation counts.** The Supplement's within-subject DF (PACC 2306, MMSE 2341, LM 1879) imply about 15–20% more observations than here (PACC 2,378, LM 1,945 total). LM DR is 4.4 visits/person here. The paper may have counted screening and baseline administrations separately, or used a different visit table (classic ADNIMERGE).
2. **Amyloid group composition.** 13 fewer elevated participants. The likely cause is that the 6 mm FBP reprocessing and the 2026 CSF table carry later QC corrections. The paper's per-modality counts (CSF+ 155/178 and PET+ 138/177 in the elevated group) could be used to pin this down.
3. **Small residual differences** in the imputation models, since the SUVR scale differs between pipelines.

**Implication for the agent testbed.** This is a good target. The headline result reproduces from public-package data in about 10 s. Six concrete specification choices each move the answer by a measurable amount: time terms, covariate set, CDR-SB correlation structure, baseline imputation, family-history definition, and follow-up requirement. One secondary result stays genuinely unresolved, which is a realistic "partial reproduction" case.

## Appendix: full dataset inventory

| Dataset | Rows | Cols | Participants | Description |
|---|---:|---:|---:|---|
| ADAE | 4,726 | 62 | 1,170 | DERIVED Analysis Dataset of Adverse Events |
| ADAS | 13,255 | 125 | 2,973 | ADAS-Cognitive Behavior |
| ADDCOMM | 6,789 | 17 | 2,287 | Additional Comments |
| ADI | 2,250 | 19 | 1,114 | Area Deprivation Index Score |
| ADMCBARCELONAPURINE | 887 | 13 | 810 | AD Metabolomics Consortium Barcelona Purines |
| ADNI2_ECG | 14 | 23 | 14 | ECG |
| ADNI2_OTELGTAU | 148 | 22 | 129 | Tau AV-1451 PET Eligibility |
| ADNI2_VISITID | 24,147 | 6 | 1,689 | ADNI2 Visit Code Mapping List |
| ADQS | 327,599 | 36 | 4,859 | DERIVED Analysis Dataset of Questionnaires |
| ADRS | 16,714 | 34 | 3,711 | DERIVED Response Analysis Dataset |
| ADSL | 5,138 | 56 | 5,138 | DERIVED Subject-Level Analysis Dataset |
| ADSP_PHC_COGN | 16,434 | 23 | 4,118 | ADSP Phenotype Harmonization Consortium (PHC) - Composite Cognitive Scores |
| ADSP_PHC_CSF | 2,173 | 21 | 1,249 | ADSP Phenotype Harmonization Consortium (PHC) - Composite Biomarker CSF Scores |
| ADSP_PHC_DATADIC | 13,824 | 11 |  | ADSP_PHC_DATADIC |
| ADSP_PHC_DEMODX | 17,146 | 17 | 4,742 | ADSP Phenotype Harmonization Consortium (PHC) - Composite Demographic/Diagnosis Scores |
| ADSP_PHC_FLAIR | 7,230 | 27 | 2,358 | ADSP Phenotype Harmonization Consortium (PHC) - Composite FLAIR Scores |
| ADSP_PHC_PET_Amyloid_Detailed | 4,756 | 193 | 2,209 | ADSP Phenotype Harmonization Consortium (PHC) - Composite PET Amyloid Detailed Scores |
| ADSP_PHC_PET_Amyloid_Simple | 4,756 | 26 | 2,209 | ADSP Phenotype Harmonization Consortium (PHC) - Composite PET Amyloid Simple Scores |
| ADSP_PHC_PET_Tau_Detailed | 2,278 | 192 | 1,325 | ADSP Phenotype Harmonization Consortium (PHC) - Composite PET Tau Detailed Scores |
| ADSP_PHC_PET_Tau_Simple | 2,280 | 29 | 1,327 | ADSP Phenotype Harmonization Consortium (PHC) - Composite PET Tau Simple Scores |
| ADSP_PHC_PLASMA | 1,720 | 23 | 1,299 | ADSP Phenotype Harmonization Consortium (PHC) - Composite Biomarker Plasma Scores |
| ADSP_PHC_T1_FS | 10,526 | 412 | 2,964 | ADSP Phenotype Harmonization Consortium (PHC) - Composite T1 FreeSurfer Scores |
| ADSP_PHC_T1_MUSE | 11,501 | 535 | 3,099 | ADSP Phenotype Harmonization Consortium (PHC) - Composite T1 MUSE Scores |
| ADSXLIST | 4,884 | 40 | 916 | Diagnosis and Symptoms Checklist |
| ADVERSE | 4,728 | 90 | 1,170 | Adverse Events Log |
| AE | 4,726 | 44 | 1,170 | DERIVED Adverse Events |
| ALIQUOT_COUNT | 14,198 | 12 | 2,936 | ADNI Aliquot Count Table |
| AMAS | 1,076 | 59 | 1,069 | Abbreviated Multidimensional Acculturation Scale |
| AMNART | 1,089 | 68 | 1,071 | American National Adult Reading Test |
| AMYDISC | 809 | 34 | 796 | Amyloid Disclosure Visit |
| AMYMETA | 3,183 | 40 | 1,610 | Amyloid PET Scan Information |
| AMYQC | 2,985 | 28 | 1,533 | Amyloid PET QC |
| AMYREAD | 988 | 24 | 927 | Amyloid PET Read |
| ANTIAMYTX | 101 | 23 | 86 | Anti-Amyloid Treatment Information |
| APOERES | 3,216 | 17 | 3,216 | ApoE Genotyping - Results |
| ARM | 4,705 | 15 | 2,872 | ARM |
| AV45FOLLOW | 1,745 | 16 | 1,080 | AV-45 24-48 Hour Follow-Up |
| AV45META | 3,400 | 52 | 1,211 | AV-45 PET Scan Information |
| AV45QC | 2,707 | 39 | 1,100 | AV-45 PET QC Tracking |
| AV45VITALS | 1,802 | 28 | 1,098 | AV-45 Pre and Post Injection Vitals |
| BACKMEDS | 14,611 | 16 | 3,511 | Key Background Medications |
| BAIMRINMRC | 726 | 12 | 643 | BAI - MRI NMRC Summaries: 2016-09-12 |
| BAINMRC | 2,026 | 304 | 681 | BAI - NMRC Summaries |
| BAIPETNMRC | 5,598 | 345 | 1,421 | BAI - PET NMRC Summaries: 2018-04-12 |
| BAIPETNMRCAV45 | 2,815 | 13 | 1,294 | BAI - PET NMRC AV45 Summaries: 2020-10-23 |
| BAIPETNMRCFDG | 3,684 | 14 | 1,610 | BAI - PET NMRC FDG Summaries: 2020-12-11 |
| BAIPETNMRCFTP | 1,157 | 14 | 772 | BAI - PET NMRC Flortaucipir (F-AV1451) Summaries: 2022-08-17 |
| batemanlab_20190621 | 622 | 74 | 200 | BATEMANLAB_20190621 |
| batemanlab_20221118 | 742 | 36 | 359 | BATEMANLAB_20221118 |
| BHR | 1,104 | 14 | 1,104 | Brain Health Registry (BHR) |
| BHR_BASELINE_QUESTIONNAIRE | 95 | 73 | 95 | Brain Health Registry (BHR) BASELINE QUESTIONNAIRE |
| BHR_EVERYDAY_COGNITION | 346 | 47 | 99 | Brain Health Registry (BHR) EVERYDAY COGNITION |
| BHR_LONGITUDINAL_QUESTIONNAIRE | 249 | 75 | 79 | Brain Health Registry (BHR) LONGITUDINAL QUESTIONNAIRE |
| BHR_MEMTRAX | 1,422 | 32 | 135 | Brain Health Registry (BHR) MEMTRAX |
| BHR_SP_ADL | 4 | 16 |  | Brain Health Registry (BHR) SP ADL |
| BHR_SP_CAREGIVER_BURDEN | 37 | 133 |  | Brain Health Registry (BHR) SP CAREGIVER BURDEN |
| BHR_SP_EVERYDAY_COGNITION | 41 | 47 |  | Brain Health Registry (BHR) SP EVERYDAY COGNITION |
| BHR_SP_FAQ | 35 | 18 |  | Brain Health Registry (BHR) SP FAQ |
| BHR_SP_INITIAL | 46 | 38 |  | Brain Health Registry (BHR) SP INITIAL |
| BHR_SP_RELATIONSHIP | 50 | 12 |  | Brain Health Registry (BHR) SP RELATIONSHIP |
| BHR_SP_STUDY_CONFIRMATION | 40 | 9 |  | Brain Health Registry (BHR) SP STUDY CONFIRMATION |
| BIOMARK | 14,460 | 66 | 2,989 | Biomarker Samples |
| BLCHANGE | 16,433 | 30 | 3,720 | Diagnostic Summary - Baseline Changes |
| BLENNOWCSFNFL | 415 | 9 | 399 | Blennow Lab ADNI1 CSF NFL |
| BLENNOWCSFNG | 415 | 9 | 399 | Blennow Lab ADNI1 CSF Ng |
| BLENNOWPLASMANFL | 598 | 10 | 582 | Blennow Lab ADNI1 Plasma neurofilament light (NFL): 2018-10-03 |
| BLENNOWPLASMANFLLONG | 3,762 | 12 | 1,191 | Blennow Lab ADNI1-2 Plasma neurofilament light (NFL) longitudinal: 2018-10-03 |
| BLENNOWPLASMATAU | 581 | 9 | 581 | Blennow Lab ADNI1 Plasma Tau |
| BLSCHECK | 2,550 | 40 | 2,153 | Baseline Symptoms Checklist |
| BSI | 3,594 | 21 | 842 | Boundary Shift Integral Summaries (Nick Fox's lab) |
| C2N_PRECIVITYAD2_PLASMA | 1,069 | 19 | 926 | C2N Diagnostics - PrecivityAD2 Blood Test Results for Aβ42/40 and p-tau217/np-tau217 ratios 'AD |
| CBBCOMP | 2,857 | 14 | 1,134 | Cogstate Brief Battery |
| CBBRESULTS | 22,205 | 44 | 837 | Cogstate Battery Results |
| CCI | 1,228 | 34 | 1,228 | Cognitive Change Index |
| CDR | 15,072 | 26 | 4,377 | Clinical Dementia Rating |
| Changed_Study_ID_Listing | 5 | 4 |  | CHANGED_STUDY_ID_LISTING |
| CLIELG | 7,499 | 16 | 4,858 | Clinician Verification |
| CLINLABDISC | 19 | 18 | 19 | Clinical Labs Disclosure |
| CONSENTS | 2,065 | 25 | 1,410 | Consent Tracking |
| CROSSVAL | 822 | 6 | 822 | CROSSVAL |
| CSSRSAD | 441 | 19 | 432 | Columbia- Suicide Severity Rating Scale (C-SSRS) + AD Specific Suicide |
| DATA_DOWNLOADED_DATE | (not a data frame) |  |  | ADNI Study Data Downloaded Date |
| DATADIC | 95,411 | 16 |  | ADNI Study Data Dictionary |
| DERIVED_DATADIC | 476 | 5 |  | DERIVED Data dictionary for derived dataset |
| DM | 5,138 | 24 | 5,138 | DERIVED Demographic Characteristics |
| DTIROI_V1 | 976 | 243 | 282 | USC - DTI ROI Summary Measures v1 |
| DXSUM | 16,504 | 42 | 3,774 | Diagnostic Summary |
| EBISU | 1,394 | 17 | 1,394 | Ebisu (ADNI ONLINE) ID |
| ECOG12PT | 1,610 | 32 | 1,038 | Everyday Cognition 12 Item - Participant Self-Report |
| ECOG12SP | 1,609 | 29 | 1,036 | Everyday Cognition 12 Item - Study Partner Report |
| ECOGPT | 8,093 | 63 | 1,917 | Everyday Cognition - Participant Self-Report |
| ECOGSP | 8,107 | 60 | 1,913 | Everyday Cognition - Study Partner Report |
| EMBICDCB | 10,398 | 14 | 2,286 | Embic Corporation – Digital Cognitive Biomarkers |
| EMBICqCP | 10,868 | 32 | 2,366 | Embic Corporation Quantified Cognitive Processes |
| EXCLUSIO | 1,087 | 23 | 1,087 | Exclusion Criteria |
| FAMHXPAR | 2,317 | 25 | 1,968 | Family History - Parents |
| FAMHXSIB | 6,773 | 23 | 1,870 | Family History - Sibling Log |
| FAQ | 13,747 | 28 | 3,022 | Functional Assessment Questionnaire |
| FCI | 2,626 | 70 | 1,105 | Financial Capacity Instrument Short Form (FCI-SF) |
| FHQ | 2,952 | 19 | 2,677 | Family History Questionnaire |
| FNIHBC_BLOOD_BIOMARKER_TRAJECTORIES | 24,154 | 21 | 406 | Clinical Utility of Blood Biomarker Trajectories Study |
| FOXLABBSI | 16,208 | 29 | 3,199 | Fox Lab BSI measures |
| FUJIREBIOABETA | 442 | 20 | 423 | Fujirebio Beta-Amyloid Ratio |
| FUJIREBIOABETAPLASMA | 514 | 11 | 121 | Plasma Amyloid Beta (1-42/1-40) Ratio Biomarker Feasibility Study - Fujirebio Lumipulse |
| GDSCALE | 14,149 | 33 | 4,564 | Geriatric Depression Scale |
| GENETIC | 10,551 | 58 | 3,323 | ApoE Genotyping - Draw Data |
| GF | 3,216 | 14 | 3,216 | DERIVED Genomics Findings |
| GOTHENBURG_VISUAL_READS_AV1451 | 835 | 14 | 835 | Schöll Lab - Visual Reads 18Fflortaucipir tau-PET AV1451 |
| IES | 933 | 30 | 680 | Impact of Events Scale |
| INCLUSIO | 1,109 | 39 | 1,109 | Inclusion Criteria |
| INITHEALTH | 32,264 | 27 | 2,192 | Initial Health Assessment |
| ITEM | 5,341 | 767 | 755 | Item Level Data |
| LABDATA | 2,463 | 133 | 2,285 | Laboratory Data |
| LABTESTS | 5,848 | 22 | 4,171 | Clinical Laboratory Tests |
| LB | 331,740 | 27 | 4,137 | DERIVED Laboratory Test Results |
| LOCLAB | 8,714 | 23 | 2,702 | CSF - Local Lab Results |
| MAYOADIRL_MRI_FMRI | 892 | 34 | 226 | Jack Lab - Default Mode Network connectivity: 2017-11-07 |
| MAYOADIRL_MRI_FMRI_NFQ | 2,996 | 35 | 1,276 | Jack Lab - fMRI Network Failure Quotient (NFQ) |
| MAYOADIRL_MRI_MCH | 19,220 | 24 | 1,874 | Jack Lab - ADNI MRI MCH |
| MAYOADIRL_MRI_QUALITY_ADNI3 | 28,244 | 29 | 1,155 | MAYOADIRL_MRI_QUALITY_ADNI3 |
| MAYOADIRL_MRI_TBMSYN | 2,667 | 45 | 717 | Jack Lab - TBM-SyN Based Scores |
| MEDHIST | 3,083 | 40 | 2,491 | Medical History |
| METACORES | (not a data frame) |  |  | ADNI Metadata-Specs |
| MMSE | 14,960 | 59 | 4,668 | Mini Mental State Exam |
| MOCA | 9,345 | 59 | 2,446 | MoCA |
| MOCAB | 52 | 50 | 52 | MoCA-Blind |
| MODHACH | 3,462 | 22 | 3,462 | Modified Hachinski |
| MRI_INFARCTS | 8,593 | 16 | 2,301 | MRI Infarcts: 2021-01-29 |
| MRI3META | 9,655 | 43 | 2,814 | 3T MRI Scan Information |
| MRIB1CALIB | 4,480 | 18 | 856 | MRI B1 Calibration |
| MRIFind | 10,059 | 42 | 994 | MAYO ADIR LAB MRI Findings |
| MRIMETA | 4,740 | 36 | 877 | 1.5T MRI Scan Information |
| MRIMPPRO | 3,269 | 17 | 820 | MRI MPRAGE Process |
| MRIMPRANK | 9,412 | 18 | 859 | MRI MPRAGE Ranking |
| MRINCLUSIO | 9,805 | 39 | 1,879 | MRI Subject Inclusion |
| MRINFQ | 1,002 | 47 | 796 | MAYO ADIR LAB MRI Network Failure Quotient |
| MRIPROT | 11,918 | 21 | 840 | MRI Protocol |
| MRIQC | 93,736 | 26 |  | MAYO ADIR LAB MRI Quality |
| MRIQSM | 31,058 | 39 | 582 | MAYO ADIR LAB MRI Quantitative Susceptibility Mapping |
| MRIREAD | 4,106 | 16 | 862 | MRI Clinical Read |
| MRISERIAL | 3,204 | 23 | 775 | MRI Serial |
| MUSE_volume_ADNI123 | 10,329 | 273 | 2,445 | UCSF MedAI - MASS and MUSE volumetrics - ADNI 1-3 |
| MUSE_volume_ADNI123_DATADIC | 283 | 11 |  | MUSE_volume_ADNI123_DATADIC |
| NEUROBAT | 17,979 | 84 | 4,758 | Neuropsychological Battery |
| NEUROEXM | 6,049 | 29 | 4,238 | Neurological Exam |
| NEUROPATH | 121 | 165 | 121 | NACC Neuropathology Data Form (Version 11) |
| NPI | 8,666 | 169 | 2,451 | Neuropsychiatric Inventory |
| NPIQ | 7,716 | 42 | 2,271 | Neuropsychiatric Inventory Q |
| NPSTATUS | 12,366 | 23 | 2,950 | Neuropathology Status |
| NV | 43,243 | 23 | 2,619 | DERIVED Nervous System Finding |
| NYUFDGHIP | 612 | 17 | 343 | NYU FDG-PET Hippocampus (pons normalized) |
| PACC | 19,852 | 28 | 4,774 | DERIVED Modified Preclinical Alzheimer’s Cognitive Composite (PACC) Score |
| PEDQCV | 1,690 | 34 | 1,103 | Brief Perceived Ethnic Discrimination Questionnaire-Community Version |
| PETC3 | 434 | 25 | 420 | PETC3 |
| PETMETA_ADNI1 | 1,957 | 105 | 420 | PET Scan Information |
| PETMETA_ADNIGO2 | 3,376 | 52 | 1,212 | FDG PET Scan Information |
| PETMETA3 | 701 | 32 | 697 | FDG PET Scan Information |
| PETQC | 3,951 | 39 | 1,413 | PET QC Tracking |
| PHYSICAL | 6,047 | 29 | 4,237 | Physical Exam |
| PIBMETA | 257 | 76 | 108 | PIB Scan Information |
| PIBPETSUVR | 224 | 22 | 103 | U Pitt PIB PET Analysis |
| PIBQC | 294 | 34 | 103 | PIB QC Tracking |
| PICSLASHS | 4,126 | 68 | 1,907 | ASHS Volume Data: Hippocampal and Medial Temporal Lobe regional volumes from High-Resolution T2 |
| POSAMYDISC | 728 | 29 | 715 | Post-Amyloid PET Disclosure |
| PREAMYDISC | 930 | 25 | 864 | Pre-Amyloid PET Disclosure |
| PSS | 1,694 | 27 | 1,103 | Perceived Stress Scale 10 Item |
| PTDEMOG | 6,218 | 85 | 4,931 | Participant Demographic Information |
| PTFBQNR | 42 | 31 | 42 | Participant feedback questionnaire |
| PUBLICITY | 1,330 | 23 | 1,330 | Recruitment Tracking |
| QS | 327,599 | 20 | 4,859 | DERIVED Questionnaires |
| RECADV | 19,416 | 39 | 1,796 | Adverse Events/Hospitalizations - Log |
| RECBLLOG | 12,848 | 21 | 2,130 | Documentation of Baseline Symptoms Log |
| RECCMEDS | 80,007 | 39 | 4,281 | Concurrent Medications Log |
| RECFHQ | 7,407 | 16 | 2,531 | Family History Questionnaire Subtable |
| RECMHIST | 30,810 | 18 | 2,484 | Medical History |
| REGISTRY | 29,675 | 27 | 5,052 | Registry |
| REMOTE_DATADIC | 321 | 12 |  | Data Dictionary For Remotely Collected Data In ADNI4 Study Phase |
| RMT_APOERES | 1,108 | 4 |  | ApoE Genotyping - Results |
| RMT_ECOG12PT | 22,138 | 21 | 560 | 'DIG' Remotely administered Assessment of Everyday Cognition (Ecog) Questionnaire – Participant |
| RMT_ECOG12SP | 5,139 | 21 | 262 | 'DIG' Remotely administered Assessment of Everyday Cognition (Ecog) Questionnaire – Informant-R |
| RMT_PTDEMOG | 25,662 | 23 | 562 | 'DIG' Remotely administered participant demographics questionnaire |
| RMT_Screening | 12,232 | 26 | 170 | 'DIG' Remotely administered screening questionnaire |
| RMT_STORYTELLER | 15,878 | 72 | 540 | Novoic Storyteller Data |
| ROSTER | 7,427 | 10 | 5,138 | Roster |
| RS | 16,441 | 17 | 3,711 | DERIVED Clinical Classification |
| RURALITY | 2,260 | 20 | 1,126 | Rurality – RUCA & RUCC |
| RYFF | 1,231 | 29 | 879 | RYFF Psychological Well-Being Purpose in Life |
| SC | 136,881 | 17 | 4,923 | DERIVED Subject Characteristics |
| SCDQ | 73 | 18 | 65 | Subjective Cognitive Decline Questionnaire |
| SPAP_AVID_FLORBETAPIR | 604 | 21 | 604 | sPAP Avid ADNI Florbetapir summaries |
| SSAD | 9 | 19 | 9 | Suicide Severity (SS) + AD Specific Suicide |
| STAIAD | 454 | 22 | 445 | Mini-State Trait Anxiety Inventory (STAI) for Adults™ |
| STUDYSUM | 1,164 | 30 | 1,158 | Study Visits Summary |
| TAUMETA | 3,298 | 41 | 1,621 | Tau AV-1451 PET Scan Information |
| TAUQC | 2,772 | 29 | 1,503 | Tau AV-1451 PET QC |
| TBM | 9,354 | 18 | 1,921 | Paul Thompson's Lab, Imaging Genetics Center (IGC), University of Southern California - Cross-s |
| TCV | 810 | 11 | 810 | Total Cranial Vault Segmentation |
| TREATDIS | 1,889 | 18 | 1,486 | Early Discontinuation and Withdrawal |
| UASPMVBM | 4,091 | 128 | 829 | UA (Gene Alexander) MRI SPM voxel based morphometry (VBM) analysis |
| UCBERKELEY_AMY_6MM | 4,728 | 345 | 2,240 | UC Berkeley - Amyloid PET 6mm Res analysis |
| UCBERKELEY_TAU_6MM | 2,489 | 340 | 1,448 | UC Berkeley - Tau PET 6mm Res analysis |
| UCBERKELEY_TAUPVC_6MM | 2,398 | 336 | 1,415 | UC Berkeley - Tau PET PVC 6mm Res analysis |
| UCBERKELEYFDG_8mm | 7,524 | 11 | 1,687 | UC Berkeley - FDG analysis: 2023-02-17 |
| UCD_ADNI1_WMH | 3,469 | 11 | 842 | Univerity of California Davis White Matter Hyperintensity Volumes (ADNI1) |
| UCD_WMH | 7,744 | 28 | 2,421 | UCD - White Matter Hyperintensity Volumes |
| UCSDVOL | 3,128 | 25 | 811 | Anders Dale Lab (UCSD) - Derived Volumes |
| UCSFASLFS_V2 | 675 | 702 | 257 | ASL Perfusion CBF by FreeSurfer ROI: 2015-11-02 |
| UCSFASLFSCBF | 515 | 438 | 351 | ASL Perfusion CBF by FreeSurfer ROI |
| UCSFASLQC | 1,011 | 7 | 300 | ASL Perfusion Raw QC |
| UCSFATRPHY | 1,721 | 13 | 765 | UCSF (Colin Studholme) Regional Atrophy Rates |
| UCSFFSL | 3,570 | 376 | 761 | Longitudinal FreeSurfer (FreeSurfer Version 4.4): 2016-02-01 |
| UCSFFSL51 | 3,311 | 365 | 689 | Longitudinal FreeSurfer (5.1) - Final Run w/ All A: 2022-03-01 |
| UCSFFSL51ALL | 2,009 | 365 | 469 | Longitudinal FreeSurfer (5.1) - All Available Base Image: 2016-08-01 |
| UCSFFSL51Y1 | 1,356 | 365 | 357 | Longitudinal FreeSurfer (5.1) - Year 1 Base Image: 2016-08-01 |
| UCSFFSX | 4,486 | 367 | 844 | Cross-Sectional FreeSurfer (FreeSurfer Version 4.3): 2015-11-02 |
| UCSFFSX51 | 4,896 | 366 | 1,067 | Cross-Sectional FreeSurfer (5.1): 2019-11-08 |
| UCSFFSX51_ADNI1_3T | 484 | 395 | 143 | ADNI-1 3T Cross-Sectional FreeSurfer (5.1): 2016-02-01 |
| UCSFFSX6 | 2,270 | 347 | 1,130 | Cross-Sectional FreeSurfer (6.0) |
| UCSFFSX7 | 12,289 | 348 | 3,179 | Cross-Sectional FreeSurfer (7.x) |
| UCSFSNTVOL | 1,874 | 16 | 587 | UCSF SNT Hippocampal Volumes |
| UGOTPTAU181 | 3,758 | 9 | 1,191 | University of Gothenburg Longitudinal plasma P-tau181: 2020-06-18 |
| UPENN_PLASMA_FUJIREBIO_QUANTERIX | 2,422 | 20 | 1,595 | UPENN - Plasma Biomarkers (Aβ42, Aβ40, ptau217, NfL, GFAP) measured by Fujirebio & Quanterix AD |
| UPENNBIOMK_MASTER | 5,876 | 15 | 1,249 | UPENN CSF Biomarker Master Alzbio3 (BATCH1-8) |
| UPENNBIOMK_ROCHE_ELECSYS | 3,174 | 14 | 1,660 | UPENN CSF Biomarkers Elecsys ADNI1,GO,2,3 |
| UPENNBIOMKADNIDIAN2017 | 422 | 14 | 184 | UPENNBIOMKADNIDIAN2017 |
| UPENNPLASMA | 2,453 | 6 | 733 | UPENN Plasma Biomarker Data |
| UPENNSPARE_AD | 840 | 13 | 840 | Spatial Pattern of Abnormalities for Recognition of Early AD (SPARE-AD). C. Davatzikos. U. Penn |
| UPENNSPARE_MCI | 330 | 14 | 330 | Spatial Pattern of Abnormalities for Recognition of Early MCI to AD conversion (SPARE-MCI). C.  |
| URMC_LABDATA | 137,834 | 29 | 1,887 | ADNI3 URMC Lab Data |
| UUCACIR | 1,822 | 17 | 1,004 | UU PET Analysis: 2016-07-18 |
| UWNPSYCHSUM | 11,519 | 12 | 2,428 | Crane Lab (UW) Neuropsych Summary Scores |
| VISITS | 69 | 5 |  | ADNI study visit code across study phases |
| VITALS | 17,623 | 28 | 4,392 | Vital Signs |
| VS | 123,361 | 20 | 4,392 | DERIVED Vital Signs |
| WATC | 968 | 59 | 968 | Word Accentuation Test - Chicago |
