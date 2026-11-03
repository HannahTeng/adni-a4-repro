# Reproduction report: Grill et al. 2020 (A4 amyloid disclosure, short-term psychological outcomes)

**Paper.** Grill JD, Raman R, Ernstrom K, et al. *Short-term Psychological Outcomes of Disclosing Amyloid Imaging Results to Research Participants Who Do Not Have Cognitive Impairment.* JAMA Neurol. 2020;77(12):1504-1513. doi:10.1001/jamaneurol.2020.2734. PMC: https://pmc.ncbi.nlm.nih.gov/articles/PMC7418046/

**Code.** `reproduce.R` in this folder (`Rscript reproduce.R`, runtime about 1 s after the package loads). Aggregate output goes to `output/results.csv`; the console log is in `output/run_log.txt`.

**Verdict: reproduced.** The analysed Ns match exactly (1,167 elevated and 538 not elevated). The population flow (156 elevated excluded) matches. Every Table 1 row matches except APOE e4 in the elevated group, which is 10 participants (0.8 percentage points) off. The headline adjusted estimates for STAI, Concerns About AD and IES match to the printed precision. The IES distress counts, the clinical-threshold counts and the disclosure-to-follow-up timing also match. The conclusions are the same: no group difference in change in depression, anxiety or suicidality; more AD concern in the elevated group; more intrusive thoughts in the elevated group. One finding is new. The abstract's group-specific change means for GDS, STAI and C-SSRS appear to have the elevated and not-elevated values swapped (see D1).

The paper is an observational before/after comparison. It has **no non-inferiority margins**: it uses ANCOVA on change scores plus descriptive threshold counts.

---

## 1. Data used

A4LEARN 1.1.20250808, data download 2025-08-08.

| Dataset | Variables | Visit(s) |
|---|---|---|
| `SUBJINFO` | BID, SUBSTUDY (A4 / LEARN / SF), PREVBID (rescreen map), APOEGN | - |
| `imaging_PET_VA` | overall_score (Positive / Negative = A4 amyloid eligibility) | VISCODE 2 |
| `ptdemog` | PTAGE, PTGENDER, PTRACE, PTETHNIC, PTEDUCAT | 1 |
| `famhxpar`, `famhxsib` | MOTHER, FATHER, SIBDEMENT (dementia or significant memory impairment); MOTHDIAG, FATHDIAG, SIBDIAG (AD diagnosis) | 1 |
| `cfi`, `cfisp` | CFIPTTOTAL (participant), CFSPTTOTAL (partner) | 1 |
| `psychwell` | GDTOTAL (GDS-15), STAITOTAL (6-item state STAI, 6-24) | 1 (pre), 6 (post) |
| `cssrs` | screening C-SSRS: past-3-month ideation items (WISH3, ACT3, METHOD3, INTENT3, PLAN3) and past-5-year behaviour (PREP5, ABORT5, INTER5, ATTMPT5) | 1 |
| `cssrslv` | since-last-visit C-SSRS (WISHLV ... ATTMPTLV), DONE==1 | 6 |
| `concerns` | 6 Concerns About AD items (CADDVLP ... CADCNCRN), summed 6-30 | 1, 3 |
| `ftpscale` | 10 Future Time Perspective items, 1-7; items 8-10 (FTRUNOUT, FTLIMIT, FTGETOLD) reverse-scored; sum 10-70 | 1, 3 |
| `ies` | IESCORE (15-item Impact of Event Scale, 0-75), DONE==1 | 3 (phone call 24-72 h after disclosure) |
| `SV` | SVSTDTC_DAYS_CONSENT for VISITCD "003" (disclosure) and "006" (baseline) | 3, 6 |

The `views` dataset (reasons for participating) is not analysed in this paper.

## 2. Population derivation

| Step | Elevated | Not elevated |
|---|---|---|
| All SUBJINFO BIDs: 6,945. Drop first appearance of the 178 rescreens (vignette method) | - | - |
| Screening PET read (VISCODE 2) after rescreen mapping | 1,323 Positive (A4 1,169 + SF 154) | 3,163 Negative (LEARN 538 + SF 2,625) |
| Comparator pool | 1,323 | 538 (LEARN-enrolled only; paper: "subset ... enrolled in LEARN") |
| At least one of GDS, STAI or C-SSRS present at visit 6 | **1,167** (A4 1,165 + SF 2) | **538** |
| Excluded for no post-disclosure measure | **156** (paper: 156) | 0 |

The paper reports 1,167 and 538. Both match exactly.

## 3. Table 1: Paper vs Reproduced (visit 1, pre-disclosure)

Values are elevated vs not elevated. P values come from t tests (continuous) or Fisher exact tests (categorical), as in the paper.

| Quantity | Paper | Reproduced | Match |
|---|---|---|---|
| N | 1167 / 538 | 1167 / 538 | Yes |
| Age, mean (SD) [range] | 71.9 (4.8) [65.0-85.7] / 70.5 (4.3) [65.0-85.6]; P<.001 | 71.93 (4.82) [65.0-85.7] / 70.53 (4.32) [65.0-85.6]; P=2.5e-9 | Yes |
| Male, n (%) | 472 (40.4) / 208 (38.7); P=.49 | 472 (40.4) / 208 (38.7); P=.49 | Yes |
| White, n (%) | 1105 (94.7) / 506 (94.1); P>.99 | 1105 (94.7) / 506 (94.1) (any White, incl. multiracial); P=.65 | Yes, counts (P differs, see D4) |
| Latino, n (%) | 34 (2.9) / 18 (3.3); P=.83 | 34 (2.9) / 18 (3.3); P=.65 | Yes, counts |
| Education, mean (SD) [range] | 16.6 (2.8) [7-30] / 16.8 (2.6) [8-30]; P=.12 | 16.57 (2.79) [7-30] / 16.79 (2.63) [8-30]; P=.12 | Yes |
| APOE e4 carrier, n (%) | 679 (58.2) / 123 (22.9); P<.001 | **689 (59.0)** / 123 (22.9); P<.001 | Partial: elevated +10 (D3) |
| Family history of AD, n (%) | 878 (75.2) / 355 (66.0); P<.001 | 878 (75.2) / 355 (66.0); P=9e-5 | Yes (defined as a parent or sibling with dementia or significant memory impairment) |
| CFI participant, mean (SD) [range] | 2.36 (2.2) [0-14] / 1.80 (1.9) [0-9.64]; P<.001 | 2.36 (2.17) [0-14] / 1.80 (1.90) [0-9.6]; P=1e-7 | Yes |
| CFI partner, mean (SD) [range] | 1.48 (2.0) [0-14] / 1.14 (1.7) [0-10.2]; P<.001 | 1.48 (2.00) [0-14] / 1.14 (1.68) [0-10.2]; P=2e-4 | Yes |
| FTP, mean (SD) [range] | 44.3 (10.4) [15-70] / 45.6 (10.6) [18-70]; P=.02 | 44.27 (10.37) [15-70] / 45.58 (10.63) [18-70]; P=.018 | Yes |
| Concerns About AD, mean (SD) [range] | 21.7 (4.5) [8-30] / 20.6 (4.5) [8-30]; P<.001 | 21.68 (4.47) [8-30] / 20.59 (4.53) [8-30]; P=4e-6 | Yes |
| GDS, median (IQR) [range] | 1.0 (0-2) [0-10] / 0.0 (0-1) [0-12]; P=.49 | 1.0 (0-2) [0-10] / 0.0 (0-1) [0-12]; P=.49 | Yes |
| STAI, median (IQR) [range] | 10.0 (8-12) [6-22] / 10.0 (7-12) [6-22]; P=.57 | 10.0 (8-12) [6-22] / 10.0 (7-12) [6-22]; P=.57 | Yes |
| C-SSRS (the paper labels 0.04 / 0.02 as medians; they are means), (IQR 0-0) [range] | 0.04 [0-9] / 0.02 [0-5]; P=.58 | mean 0.035 [0-9] / 0.020 [0-5]; P=.40 | Yes, values (P differs slightly) |
| Days from disclosure to visit 6, mean (SD) [range] | 41.6 (23.2) [2-189] / 56.6 (53.5) [0-391] | 41.6 (21.2) [2-189] / 56.6 (53.5) [0-391] | Yes (elevated SD 21.2 vs 23.2) |

## 4. Key outcomes: Paper vs Reproduced

Change is post minus pre. For GDS, STAI and C-SSRS that is visit 6 minus visit 1. For Concerns and FTP it is visit 3 (immediately after disclosure) minus visit 1. ANCOVA: change ~ group + age + sex + screening CFI + family history. The estimate is elevated minus not elevated.

| Outcome | Paper | Reproduced | Match |
|---|---|---|---|
| GDS change, elevated / not | 0.02 (1.3) / 0.04 (1.3) | 0.035 (1.34) n=1165 / 0.019 (1.30) n=536 | Values look swapped between groups (D1) |
| GDS ANCOVA group estimate | -0.01 (SE 0.07), P=.90 | -0.004 (SE 0.071), P=.96 | Yes (rounding-level difference) |
| STAI change, elevated / not | -0.02 (3.2) / -0.15 (3.0) | -0.145 (3.03) n=1165 / -0.022 (3.18) n=535 | Swapped (D1) |
| STAI ANCOVA group estimate | -0.07 (SE 0.16), P=.65 | -0.074 (SE 0.165), P=.65 | Yes |
| C-SSRS change, elevated / not | 0.0 (0.4) / -0.01 (0.5); P=.67 | -0.006 (0.51) / 0.004 (0.41); t-test P=.67 (ANCOVA P=.88) | P matches; SDs swapped (D1) |
| Concerns About AD change, elevated / not | 0.8 (3.9) / -0.4 (3.8) | 0.81 (3.87) n=1163 / -0.41 (3.83) n=530 | Yes |
| Concerns ANCOVA group estimate | 1.28 (SE 0.21), P<.001 | 1.28 (SE 0.21), P=6e-10 | Yes, exact |
| FTP change, elevated / not | 0.33 (7.8) / 1.15 (7.4); not-elevated within-group P<.001 | 0.325 (7.83) n=1143 / 1.15 (7.40) n=527; within-group P=4e-4 (elevated P=.16) | Yes |
| FTP group difference | not reported | ANCOVA -0.99 (SE 0.41), P=.017 | n/a |
| IES (24-72 h), mean (SD) elevated / not | 10.2 (10.8) / 5.9 (7.6); P<.001 | 10.2 (10.8) n=1157 / 5.95 (7.58) n=512; P=6e-20 | Yes |
| IES ANCOVA group estimate | 4.35 (SE 0.53), P<.001 | 4.35 (SE 0.53), P=3e-16 | Yes, exact |
| IES mild distress 9-25 | 407/1155 (35.3%) / 119/534 (23.2%) | 407/1157 (35.2%) / 119/512 (23.2%) | Yes, counts (D2) |
| IES moderate distress >25 | 114 (9.8%) / 16 (3.1%) | 114 (9.9%) / 16 (3.1%) | Yes |
| GDS rising to >6 after disclosure | 10 (0.9%) / 5 (0.9%) | 10/1165 / 5/536; Fisher P=1.0 | Yes |
| STAI rising to >17 after disclosure | 17 (1.5%) / 10 (1.9%) | 17/1165 / 10/535; P=.54 | Yes |
| Pre GDS >6; fell to <=6 after disclosure | 9 (6 fell) / 8 (7 fell) | 9 (6) / 8 (7) | Yes |
| Pre STAI >17; fell to <=17 after disclosure | 24 (19 fell) / 13 (11 fell) | 24 (19) / **14** (11) | Yes / not elevated +1 |
| C-SSRS new-onset ideation | "infrequent, not different"; no attempts (eTable 2 not available) | pre 0 to post >0: 8/1166 vs 4/537 (P=1.0); post >0: 12 vs 5; behaviour-level (>=6) since last visit: 2 vs 1; actual attempts 0 | Yes, qualitatively |
| Rank regression of visit-1 scores: amyloid group | not associated with GDS or STAI | GDS P=.93; STAI P=.78 | Yes |
| Rank regression: CFI -> GDS | 74.4 (5.0) | 76.4 (5.0) | Close |
| Rank regression: CFI -> STAI | 46.4 (5.6) | 46.3 (5.6) | Yes |
| Rank regression: sex -> STAI | "female" -102.9 (23.8) | male -102.0 (23.8) | Magnitude matches (the paper's sign and label are inconsistent; males score lower) |

The behaviour-level C-SSRS counts are small (cells under 5). They are reported only because the paper discusses suicidality. No participant is identifiable from them.

A sensitivity analysis adds the baseline score to the ANCOVA. It leaves all conclusions unchanged: GDS -0.04 (P=.57), STAI -0.11 (P=.45), C-SSRS 0.00 (P=.97), Concerns 1.56 (P<.001), FTP -0.98 (P=.013).

## 5. Deviations and assumptions

- **D1. Group labels for the GDS, STAI and C-SSRS change means appear swapped in the paper's abstract and results text.** Our elevated means equal the paper's not-elevated values, and the reverse: GDS 0.035 vs 0.019; STAI -0.145 vs -0.022; C-SSRS SDs 0.51 vs 0.41. Two things support the swap. First, the paper's own adjusted STAI estimate (-0.07, elevated minus not elevated, the same convention as Concerns +1.28 and IES +4.35) has the sign that our labelling implies. Second, injected error E7 (group reversed) reproduces the paper's printed means exactly. Concerns and FTP are not swapped. The conclusions are unaffected because all of these differences are near zero.
- **D2. IES not-elevated N.** We find 512 completed IES calls. The paper's text gives 534 as the denominator, but its percentage (23.2%) equals 119/512, not 119/534 (22.3%). This is most likely a typo in the paper's denominator. Elevated: 1,157 vs 1,155.
- **D3. APOE e4 elevated: 689 vs 679.** The not-elevated count matches exactly. A likely cause is genotype updates or corrections in the 2025 data release. Carrier status is defined here as any genotype containing E4 (E2/E4, E3/E4, E4/E4).
- **D4. Fisher P values for race and ethnicity** (.65 vs >.99 and .83) differ although the counts are identical. The paper probably tested the full multi-category race and ethnicity tables rather than a 2x2 table. Not material.
- **D5. Timing SD** for the elevated group is 21.2 vs 23.2, with identical mean and range. The paper may have taken assessment dates from the CRF date rather than the SV visit date.
- **D6. C-SSRS score definition (assumption).** The paper describes a "highest level" score, range 0-9. We implemented ideation levels 1-5 and behaviour levels 6-9 (preparatory, aborted, interrupted, actual attempt). Visit 1 uses the screening form's past-3-month ideation and past-5-year behaviour; visit 6 uses the since-last-visit form. This reproduces the paper's baseline means (0.04 / 0.02) and ranges (0-9 / 0-5).
- **D7. Family history (assumption).** Any parent or full sibling with "dementia or significant memory impairment". This matches 878 / 355 exactly. Requiring a formal AD diagnosis gives 580 / 211, which does not match.
- **D8. White race** is counted as any White race, including multiracial participants. This matches 1105 / 506; White-only gives 1098 / 501.
- **D9. FTP scoring (assumption).** Items 8-10 are reverse-scored (8 - x). This reproduces the visit-1 means and the change scores to 0.01. Without reversal, the FTP changes would be 0.75 / 1.79.
- **D10. Rank regression** is implemented as OLS on ranked outcomes. The paper's software is not specified, so CFI->GDS gives 76.4 vs 74.4.
- **D11. Inclusion rule.** At least one of GDS, STAI or C-SSRS non-missing at visit 6. Each per-outcome analysis uses the available pairs, so Ns vary by outcome (for example, Concerns n=1163/530).
- **Not available or not done.** The supplement (eTable 1: visit-1 multivariable models; eTable 2: raw scale data including C-SSRS counts) could not be retrieved, so eTable 2's suicidality counts could not be compared. Figure 2 (box plots) and Figure 3 (item-level Concerns proportions) report no numbers in the text and were not reproduced. The PMC page was read through WebFetch, which returns a model summary. Numbers were cross-checked by several targeted queries, but a direct read of the PDF tables was not possible.

## 6. Candidate injected-error types

1. **E1 Wrong post-disclosure visit.** Using the first on-study follow-up (A4 week 12 = VISCODE 9; LEARN week 24 = VISCODE 12) instead of visit 6.
2. **E2 Mismatched C-SSRS windows.** Scoring visit 1 from the lifetime columns instead of the past-3-month and past-5-year columns, while visit 6 uses since-last-visit.
3. **E3 Wrong comparator population.** All 3,163 amyloid-negative screenees instead of LEARN enrollees. Screen-fails have visit-3 Concerns, FTP and IES data, so these outcomes run silently with N~3,000.
4. **E4 FTP reverse-keyed items not reversed.**
5. **E5 IES item codes 0/1/3/5 treated as 0/1/2/3** (a wrong rescoring instead of using IESCORE).
6. **E6 Ignoring baseline.** Analysing post-disclosure levels instead of change scores.
7. **E7 Group coding reversed** (estimate is not elevated minus elevated).
8. Not dropping first-appearance rescreen BIDs, which double-counts participants and mis-maps PET to the wrong BID.
9. Using the A4-randomized flag (SUBSTUDY == "A4") as the elevated group, which drops the 2 elevated screen-fails who have visit-6 data. The effect would be negligible.
10. Concerns and FTP "post" taken at visit 9 instead of visit 3 (immediately after disclosure).
11. IES moderate cut-off taken as >=25 instead of >25, or mild as 8-25.
12. Adjusting for partner CFI instead of participant CFI, or omitting family history.

### Measured impact (reruns in `reproduce.R`)

Elevated minus not elevated ANCOVA estimate (SE, P). The correct analysis is shown first in each cell.

| Error | Outcome affected | Correct | With error | Impact |
|---|---|---|---|---|
| E1 post visit = week 12 / week 24 | STAI change | -0.07 (0.17), P=.65; means -0.15 / -0.02 | +0.17 (0.18), P=.35; means +0.27 / +0.08 | The sign flips and both groups show increased anxiety. The conclusion still holds, but the numbers no longer match the paper. GDS: means 0.14 / 0.12 instead of 0.04 / 0.02. Ns fall to 1,137 / 518. |
| E2 lifetime C-SSRS baseline | C-SSRS change | -0.004 (0.026), P=.88; means -0.006 / 0.004 | +0.13 (0.085), P=.12; means -0.45 / -0.58 | A spurious large "decrease in suicidality" appears in both groups (about 100x too large), and the group estimate is 30x larger and near-trend. |
| E3 comparator = all amyloid-negatives | Concerns, FTP, IES | Concerns 1.28 (0.21); FTP -0.99 (0.41), P=.017; IES 4.35 (0.53) | Concerns 1.37 (0.14); FTP -0.80 (0.27), P=.003; IES 3.63 (0.31) | The comparator N rises from 530 to about 3,040. The IES difference shrinks 17% and the FTP P value shrinks about 5x. Table 1 Ns would no longer match. |
| E4 FTP not reverse-scored | FTP change | 0.33 / 1.15; -0.99 (0.41), P=.017 | 0.75 / 1.79; -1.04 (0.37), P=.005 | The group means are about 0.4-0.6 points too high and the baseline means would not match Table 1. The difference stays similar in size. |
| E5 IES recoded 0-3 | IES | 10.2 / 5.95; 4.35 (0.53) | 7.35 / 4.28; 3.12 (0.35) | Means fall 28% and the distress thresholds (9, 25) no longer apply. N drops slightly because of item-level missingness. |
| E6 post score, ignoring baseline | Concerns, FTP | Concerns 1.28 (0.21); FTP -0.99, P=.017 | Concerns 2.01 (0.24); FTP -0.98 (0.56), P=.083 | The Concerns effect is inflated 57% by the pre-existing group difference. FTP is no longer significant. GDS and STAI stay null. |
| E7 group reversed | all | +1.28 Concerns, +4.35 IES | -1.28, -4.35 | Every sign flips, and the group-specific GDS, STAI and C-SSRS means become exactly the paper's printed values (supports D1). |

The most sensitive checkpoints for detecting errors are the population Ns (1,167 / 538 / 156 excluded), the Concerns ANCOVA (1.28, SE 0.21), the IES ANCOVA (4.35, SE 0.53), the IES distress counts (407/114 vs 119/16), and the C-SSRS baseline means (0.04 / 0.02).
