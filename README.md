# adni-a4-repro

Independent reproductions of published Alzheimer's disease trial and cohort analyses from the
official ATRI R data packages, `ADNIMERGE2` (ADNI) and `A4LEARN` (A4/LEARN). Each reproduction is
scripted end to end, compared against the published tables and estimates, and, where useful,
re-run with deliberately injected errors to measure how sensitive the published quantities are to
common programming mistakes.

The repository is a testbed for two questions:

1. Can a published analysis be rebuilt from the released data package and its data dictionary alone?
2. Which published quantities would catch an error in derivation, population or model
   specification, and which would not?

## Data governance

**This repository contains code and aggregate-only reports. It contains no data.** Under the ADNI and
A4 data-use agreements, participant-level data, package tarballs, package sources and rendered
vignettes (which include participant-level plots) are git-ignored. Each `setup.sh` rebuilds the
local working tree from the user's own LONI or A4 download. Scripts print aggregates only.

## Contents

| Directory | Data package | Published target | Outcome | Report |
|---|---|---|---|---|
| `adni/` | ADNIMERGE2 0.1.4 (data cut 2026-10-05) | ATRI vignettes: Enrollment, Longitudinal ADAS-Cog LMM, PACC | Exact match on 1,118 table cells, all model output and the PACC standardization | [`adni/ADNI_SETUP_REPORT.md`](adni/ADNI_SETUP_REPORT.md) §4–7 |
| `adni/` | ADNIMERGE2 0.1.4 | Donohue et al., *JAMA* 2017: amyloid status and 4-year cognitive decline in cognitively normal participants | PACC, MMSE and CDR-SB reproduced within ~0.1 under the Supplement's specifications; Logical Memory 4-year estimate not reproduced | §11–12 |
| `a4/` | A4LEARN 1.1.20250808 | Sperling et al., *NEJM* 2023: A4 solanezumab primary results | Primary endpoint exact (difference −0.30, 95% CI −0.82 to 0.22); secondary endpoints partially reproduced | [`a4/REPRODUCTION_REPORT.md`](a4/REPRODUCTION_REPORT.md) |
| `a4/papers/a4learn2024_amyloid_tau_ptau217/` | A4LEARN | Sperling et al., *J Prev Alzheimers Dis* 2024 (amyloid and tau PET as predictors of decline); Rissman et al. 2024 (plasma p-tau217 vs amyloid PET) | Reproduced; includes injected-error sensitivity runs | [`REPORT.md`](a4/papers/a4learn2024_amyloid_tau_ptau217/REPORT.md) |
| `a4/papers/grill2020_disclosure/` | A4LEARN | Grill et al., *JAMA Neurol* 2020: short-term psychological outcomes of amyloid disclosure | Ns, Table 1 (one APOE cell differs by 10) and headline adjusted estimates reproduced | [`REPORT.md`](a4/papers/grill2020_disclosure/REPORT.md) |
| `a4/papers/sperling2020_amyloid_factors/` | A4LEARN | Sperling et al., *JAMA Neurol* 2020: factors associated with elevated amyloid at screening | Screening population and Table 1 exact; injected-error sensitivity table | `reproduce.R` (console output) |

The companion repository [`clinical-program-review`](https://github.com/HannahTeng/clinical-program-review)
uses the Sperling 2020 screening population as the worked example for an audited, AI-assisted
program-specification and R-vs-Python reconciliation workflow.

## Requirements

- R ≥ 4.4 with `dplyr`, `tidyr`, `nlme`, `mmrm`, `emmeans`, `gt`, `knitr`, `rmarkdown`
- Python ≥ 3.9 (standard library only; used for HTML table comparison)
- pandoc
- Your own ADNIMERGE2 download from LONI IDA and/or the A4LEARN package from the A4 Study Data
  Sharing portal. Neither is distributed here.

## ADNI

```sh
sh adni/setup.sh ~/Downloads/download.zip   # LONI IDA ADNIMERGE2 download; creates adni/{raw,rlib-src,Rlib,output}
cd adni
Rscript scripts/01_inventory.R               # dataset inventory -> output/dataset_inventory.csv
Rscript scripts/02_render_vignettes.R ADNI-Enrollment ADNI-Longitudinal ADNIMERGE2-PACC
for v in ADNI-Enrollment ADNI-Longitudinal ADNIMERGE2-PACC; do
  python3 -I scripts/03_compare.py rlib-src/ADNIMERGE2/inst/doc/$v.html output/$v.html
done
Rscript scripts/04_reproduce_and_perturb.R   # independent reproduction + injected-error impact
Rscript scripts/05_inventory_md.R            # appendix table for the report
Rscript scripts/06_donohue2017.R             # Donohue 2017, first pass
Rscript scripts/07_donohue2017_spec.R        # Donohue 2017, Supplement eTable 2-11 specifications
```

Each script runs in under 40 seconds on an Apple Silicon Mac.

## A4

```sh
sh a4/setup.sh /path/to/A4LEARN_1.1.20250808.tar.gz   # extracts vignettes, installs A4LEARN into a local library
cd a4
Rscript render.R          # renders A4-Primary-Results and A4-LEARN-Baseline-Characteristics into output/
Rscript supplementary.R   # secondary endpoints with the vignette's spline GLS model
```

Each folder under `a4/papers/` reproduces one paper: `cd a4/papers/<paper> && Rscript reproduce*.R`.
Aggregate CSVs are written to that folder's `output/`, which is git-ignored.

## Method

Every reproduction follows the same steps, recorded in its report:

1. **Population.** Rebuild the analysis population from the package's analysis datasets (ADSL, ADQS,
   ADPET and related CDISC-style tables) using the flags and visit codes documented in the data
   dictionary, and match the published N at each stage.
2. **Derivations.** Re-derive composite scores (PACC, ADAS-Cog, CDR-SB) from component items where
   the package provides them, and compare against the package's own derived variables.
3. **Models.** Fit the published model (MMRM, mixed-effects, GLS with natural splines) with the
   stated covariates and covariance structure; report estimates, confidence intervals and P values
   next to the published values with the absolute difference.
4. **Sensitivity.** Where the report includes an injected-error table, re-run the analysis with one
   deliberate defect at a time (wrong population flag, dropped covariate, off-by-one visit window,
   mis-coded treatment arm) and record which published quantities move and by how much.

## Contributing under the DUA

- Output aggregates only. Never print participant-level rows (`head()`, `print(df)`, `View()`).
- Data stays local. Do not upload data, excerpts or rendered outputs to any service.
- Keep `.gitignore` as is and run `git status` before every commit.
