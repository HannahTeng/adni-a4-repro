# ADNI & A4 reproduction testbed

Reproductions of published Alzheimer's disease analyses from the official ATRI R data packages. They are candidate targets for evaluating agents that verify scientific analyses.

**This repo holds code and aggregate-only reports. It holds no data.** Participant-level data, package tarballs, package sources, and rendered vignettes are git-ignored under the ADNI and A4 data-use agreements. The rendered vignettes are excluded because they contain participant-level plots. Each `setup.sh` rebuilds the local working tree from your own LONI / A4 downloads.

| Part | Data package | Target | Result | Report |
|---|---|---|---|---|
| `adni/` | ADNIMERGE2 0.1.4 (data cut 2026-10-05) | ATRI vignettes: Enrollment, Longitudinal ADAS-Cog LMM, PACC | Exact match: 1,118 table cells, all model output, PACC standardization | [`adni/ADNI_SETUP_REPORT.md`](adni/ADNI_SETUP_REPORT.md) §4–7 |
| `adni/` | same | Donohue et al., *JAMA* 2017: amyloid vs 4-yr cognitive decline in CN | PACC, MMSE and CDR-SB reproduced within ~0.1 under the Supplement's specs; Logical Memory 4-yr not reproduced | §11–12 |
| `a4/` | A4LEARN 1.1.20250808 | Sperling et al., *NEJM* 2023: A4 solanezumab primary results | Primary endpoint exact (−0.30, 95% CI −0.82 to 0.22); secondary endpoints partial | [`a4/REPRODUCTION_REPORT.md`](a4/REPRODUCTION_REPORT.md) |

The reports were generated in `~/adni-repro` and `~/a4-repro`, and the paths inside them refer to those working directories.

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
Rscript scripts/05_inventory_md.R            # appendix table
Rscript scripts/06_donohue2017.R             # Donohue 2017, first pass
Rscript scripts/07_donohue2017_spec.R        # Donohue 2017, Supplement eTable 2-11 specs
```

All scripts run in under 40 s each on an M-series Mac.

## A4

```sh
sh a4/setup.sh ~/proposal/a4clinicaldata/A4LEARN_1.1.20250808.tar.gz   # extracts vignettes, installs A4LEARN
cd a4
Rscript render.R          # renders A4-Primary-Results + A4-LEARN-Baseline-Characteristics into output/
Rscript supplementary.R   # secondary endpoints with the vignette's spline GLS
```

## Rules for contributors (DUA)

- **No participant-level output.** Never print participant-level rows (`head()`, `print(df)`, `View()`); output aggregates only.
- **Data stays local.** Never upload data, excerpts or rendered outputs to any website, API, GitHub, Colab or cloud service.
- **Keep the ignore list.** Keep `.gitignore` as is, and run `git status` before every commit.
