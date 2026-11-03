# Reproduction of Sperling et al. 2020, JAMA Neurology 77(6):735-745
# "Association of Factors With Elevated Amyloid Burden in Clinically Normal Older Individuals"
# Data: A4LEARN R package (1.1.20250808). Prints and writes AGGREGATE results only.
#
# Usage: cd papers/sperling2020_amyloid_factors && Rscript reproduce.R
#        Rscript reproduce.R --no-errors   (skip the injected-error sensitivity runs)

suppressMessages({
  library(A4LEARN)
  library(dplyr)
  library(tidyr)
  library(pROC)
})
options(width = 160, dplyr.summarise.inform = FALSE)
dir.create("output", showWarnings = FALSE)
set.seed(1)
run_errors <- !("--no-errors" %in% commandArgs(trailingOnly = TRUE))
t0 <- Sys.time()

# ---------------------------------------------------------------------------
# 1. Screening PET population (follows the package vignette
#    "A4-LEARN-Baseline-Characteristics"): screening florbetapir PET (VISCODE 2),
#    rescreened participants mapped to their latest BID and counted once.
# ---------------------------------------------------------------------------
rescreens <- SUBJINFO %>% filter(!is.na(PREVBID)) %>% select(BID1 = PREVBID, BID2 = BID)

build_pet <- function(dedup = TRUE) {
  pet <- imaging_SUVR_amyloid %>%
    filter(brain_region != "" & VISCODE == 2) %>%
    pivot_wider(id_cols = "BID", names_from = brain_region, values_from = suvr_cer) %>%
    left_join(imaging_PET_VA %>% select(-SUBSTUDY, -VISCODE), by = "BID")
  if (dedup) {
    pet <- pet %>%
      left_join(rescreens, by = c("BID" = "BID1")) %>%
      mutate(BID = coalesce(BID2, BID)) %>%
      arrange(BID, BID2) %>%
      filter(!duplicated(BID, fromLast = TRUE)) %>%
      select(-BID2)
  }
  pet
}

flow <- list()
flow$pet_scans <- sum(imaging_PET_VA$VISCODE == 2)
pet <- build_pet()
flow$pet_after_rescreen_dedup <- nrow(pet)

# ---------------------------------------------------------------------------
# 2. Covariates and outcomes, all from screening visit 1 (VISCODE 1)
# ---------------------------------------------------------------------------
demog <- ptdemog %>%
  transmute(BID,
    age = PTAGE, educ = PTEDUCAT,
    female = as.integer(PTGENDER == "Female"),
    ethnic = factor(PTETHNIC, c("Hispanic or Latino", "Not Hispanic or Latino", "Unknown or Not reported"),
                    c("Hispanic or Latino", "Not Hispanic or Latino", "Unknown")),
    marital = factor(coalesce(as.character(PTMARRY), "Unknown/Other"),
                     c("Married", "Widowed", "Divorced", "Never married", "Unknown/Other"),
                     c("Married", "Widowed", "Divorced", "Never married", "Unknown")),
    retired = as.integer(PTNOTRT == "Yes"),
    race_aian  = `PTRACE: American Indian or Alaskan Native`,
    race_asian = `PTRACE: Asian`,
    race_nhpi  = `PTRACE: Native Hawaiian or Other Pacific Islander`,
    race_black = `PTRACE: Black or African American`,
    race_white = `PTRACE: White`,
    race_unk   = `PTRACE: Unknown or Not Reported`)

apoe <- SUBJINFO %>% transmute(BID, apoe = APOEGN,
  e4 = case_when(is.na(APOEGN) ~ NA_integer_, grepl("E4", APOEGN) ~ 1L, TRUE ~ 0L))

# Family history: any first-degree relative (mother, father, sibling) with dementia
# or significant memory impairment, as reported on the screening family history CRFs.
sib <- famhxsib %>% filter(VISCODE == 1) %>% group_by(BID) %>%
  summarise(sib_dem = as.integer(any(SIBDEMENT == 1, na.rm = TRUE)),
            sib_ad80 = as.integer(any(SIBDEMENT == 1 & SIBAGE < 80, na.rm = TRUE)))
famhx <- famhxpar %>% filter(VISCODE == 1) %>%
  select(BID, MOTHER, FATHER, MOTHAGE, FATHAGE) %>%
  full_join(sib, by = "BID") %>%
  transmute(BID,
    famhx = as.integer(coalesce(MOTHER == 1, FALSE) | coalesce(FATHER == 1, FALSE) | coalesce(sib_dem == 1, FALSE)),
    famhx_parent = as.integer(coalesce(MOTHER == 1, FALSE) | coalesce(FATHER == 1, FALSE)),
    famhx_lt80 = as.integer(coalesce(MOTHER == 1 & MOTHAGE < 80, FALSE) | coalesce(FATHER == 1 & FATHAGE < 80, FALSE) |
                            coalesce(sib_ad80 == 1, FALSE)))

hab <- habits %>% filter(VISCODE == 1) %>%
  transmute(BID, aerobic = AEROBIC, walking = WALKING, sleep = SLEEP,
            caffeine = CAFFEINE, alcohol = ALCOHOL, tobacco = SMOKE)

vit <- vitals %>% filter(VISCODE == 1) %>%
  transmute(BID, bmi = STDWT / (STDHT / 100)^2)

cog <- mmse %>% filter(VISCODE == 1) %>% select(BID, mmse = MMSCORE) %>%
  full_join(coglogic %>% filter(VISCODE == 1) %>% select(BID, lmdr = LDELTOTAL), by = "BID") %>%
  full_join(cogdigit %>% filter(VISCODE == 1) %>% select(BID, dsst = DIGITTOTAL), by = "BID") %>%
  full_join(cogfcsr16 %>% filter(VISCODE == 1) %>%
              transmute(BID, fc_free = FCTOTF, fc_total = FCTOTF + FCTOTC, fc96 = FCTOTAL96), by = "BID")

cfis <- cfi %>% filter(VISCODE == 1) %>% select(BID, cfi_self = CFIPTTOTAL) %>%
  full_join(cfisp %>% filter(VISCODE == 1) %>% select(BID, cfi_sp = CFSPTTOTAL), by = "BID")

assemble <- function(pet) {
  pet %>%
    transmute(BID, suvr = Composite_Summary, pmod_suvr, overall_score, elig_vi_1,
              amy = as.integer(overall_score == "Positive")) %>%
    filter(!is.na(suvr)) %>%
    left_join(demog, by = "BID") %>% left_join(apoe, by = "BID") %>%
    left_join(famhx, by = "BID") %>% left_join(hab, by = "BID") %>%
    left_join(vit, by = "BID") %>% left_join(cog, by = "BID") %>% left_join(cfis, by = "BID") %>%
    mutate(cfi_comb = cfi_self + cfi_sp)
}

# PACC: sum of z-scores of MMSE, LMDR, DSST and FCSRT (free + total, 0-96),
# standardised to the screening PET sample itself (overall mean 0 by construction).
add_pacc <- function(d) {
  z <- function(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
  d %>% mutate(pacc = z(mmse) + z(lmdr) + z(dsst) + z(fc96))
}

dat <- assemble(pet) %>% add_pacc()
flow$analysis_n <- nrow(dat)
flow$abpos <- sum(dat$amy == 1)
flow$abneg <- sum(dat$amy == 0)

# ---------------------------------------------------------------------------
# 3. Helper functions
# ---------------------------------------------------------------------------
fmt_msd <- function(x, k = 2) sprintf(paste0("%.", k, "f (%.", k, "f)"), mean(x, na.rm = TRUE), sd(x, na.rm = TRUE))
fmt_p <- function(p) ifelse(p < .001, "<.001", ifelse(p > .99, ">.99", sprintf("%.3f", p)))

results <- list()
add <- function(section, quantity, paper, reproduced, n = NA) {
  results[[length(results) + 1]] <<- data.frame(section = section, quantity = quantity,
    paper = as.character(paper), reproduced = as.character(reproduced), n = n)
}

cont_row <- function(d, var, label, paper_vals, k = 2) {
  x <- d[[var]]; g <- d$amy
  p <- t.test(x[g == 1], x[g == 0], var.equal = FALSE)$p.value
  add("Table1", paste(label, "- All"), paper_vals[1], fmt_msd(x, k), sum(!is.na(x)))
  add("Table1", paste(label, "- Abeta-"), paper_vals[2], fmt_msd(x[g == 0], k), sum(!is.na(x[g == 0])))
  add("Table1", paste(label, "- Abeta+"), paper_vals[3], fmt_msd(x[g == 1], k), sum(!is.na(x[g == 1])))
  add("Table1", paste(label, "- P (Welch t)"), paper_vals[4], fmt_p(p))
}

cat_row <- function(d, ind, label, paper_vals, p = NULL) {
  x <- d[[ind]]; g <- d$amy
  f <- function(v) sprintf("%d (%.0f)", sum(v == 1, na.rm = TRUE), 100 * mean(v == 1, na.rm = TRUE))
  add("Table1", paste(label, "- All"), paper_vals[1], f(x))
  add("Table1", paste(label, "- Abeta-"), paper_vals[2], f(x[g == 0]))
  add("Table1", paste(label, "- Abeta+"), paper_vals[3], f(x[g == 1]))
  if (is.null(p)) p <- fisher.test(table(factor(x, 0:1), g))$p.value
  add("Table1", paste(label, "- P (Fisher)"), paper_vals[4], fmt_p(p))
}

# Cohen's d (Abeta+ minus Abeta-, pooled SD) with normal-approximation CI
cohen_d <- function(x, g) {
  x1 <- x[g == 1 & !is.na(x)]; x0 <- x[g == 0 & !is.na(x)]
  n1 <- length(x1); n0 <- length(x0)
  sp <- sqrt(((n1 - 1) * var(x1) + (n0 - 1) * var(x0)) / (n1 + n0 - 2))
  d <- (mean(x1) - mean(x0)) / sp
  se <- sqrt((n1 + n0) / (n1 * n0) + d^2 / (2 * (n1 + n0)))
  c(d = d, lo = d - 1.96 * se, hi = d + 1.96 * se)
}

# Covariate-adjusted standardized difference: ANCOVA of the outcome standardised by its
# sample SD on Abeta status + age + sex + education.
adj_d <- function(d, var, covs = c("age", "female", "educ")) {
  dd <- d[!is.na(d[[var]]), ]
  dd$y <- (dd[[var]] - mean(dd[[var]])) / sd(dd[[var]])
  fit <- lm(reformulate(c("amy", covs), "y"), data = dd)
  est <- coef(summary(fit))["amy", ]
  ci <- confint(fit)["amy", ]
  c(d = unname(est[1]), lo = unname(ci[1]), hi = unname(ci[2]), p = unname(est[4]))
}
fmt_ci <- function(v) sprintf("%.2f (%.2f to %.2f)", v[1], v[2], v[3])

# ---------------------------------------------------------------------------
# 4. Table 1
# ---------------------------------------------------------------------------
add("Population", "Screening PET N", 4486, nrow(dat))
add("Population", "Abeta- N", 3163, flow$abneg)
add("Population", "Abeta+ N (%)", "1323 (29.5)", sprintf("%d (%.1f)", flow$abpos, 100 * mean(dat$amy)))
add("Population", "Visual read positive among Abeta+ (%)", "663 (50.1)",
    sprintf("%d (%.1f)", sum(dat$elig_vi_1 == "Positive" & dat$amy == 1),
            100 * mean(dat$elig_vi_1[dat$amy == 1] == "Positive")))

# How the eligibility call relates to the eligibility SUVR (paper: >=1.15 positive; 1.10-1.15 positive only if visual read positive)
add("Population", "Abeta+ among pmod_suvr >= 1.15", "all (by definition)",
    sprintf("%d of %d", sum(dat$amy[dat$pmod_suvr >= 1.15]), sum(dat$pmod_suvr >= 1.15)))
add("Population", "Abeta+ among pmod_suvr 1.10-1.15", "visual-read positives only",
    sprintf("%d of %d", sum(dat$amy[dat$pmod_suvr >= 1.10 & dat$pmod_suvr < 1.15]), sum(dat$pmod_suvr >= 1.10 & dat$pmod_suvr < 1.15)))
add("Population", "Abeta+ among pmod_suvr < 1.10", "none", sprintf("%d of %d", sum(dat$amy[dat$pmod_suvr < 1.10]), sum(dat$pmod_suvr < 1.10)))

cont_row(dat, "age",  "Age, y",         c("71.29 (4.67)", "70.95 (4.53)", "72.10 (4.89)", "<.001"))
cont_row(dat, "educ", "Education, y",   c("16.58 (2.84)", "16.60 (2.85)", "16.54 (2.81)", ".53"))
cont_row(dat, "suvr", "PET SUVr (Composite_Summary, suvr_cer)", c("1.09 (0.19)", "0.99 (0.07)", "1.33 (0.18)", "<.001"))
cont_row(dat, "pmod_suvr", "PET SUVr (pmod_suvr, eligibility)", c("1.09 (0.19)", "0.99 (0.07)", "1.33 (0.18)", "<.001"))
cat_row(dat, "female", "Female sex", c("2663 (59)", "1885 (60)", "778 (59)", ".64"))

# Race: each category vs not, Fisher exact, Holm across the 6 categories
race_vars <- c(race_aian = "American Indian/Alaskan Native", race_asian = "Asian",
  race_nhpi = "Native Hawaiian/Pacific Islander", race_black = "Black/African American",
  race_white = "White", race_unk = "Unknown/not reported")
race_paper <- list(c("32 (1)", "22 (1)", "10 (1)", ">.99"), c("171 (4)", "141 (4)", "30 (2)", ".002"),
  c("2 (0)", "2 (0)", "0 (0)", ">.99"), c("167 (4)", "133 (4)", "34 (3)", ".03"),
  c("4116 (92)", "2866 (91)", "1250 (94)", "<.001"), c("26 (1)", "18 (1)", "8 (1)", ">.99"))
race_p <- p.adjust(sapply(names(race_vars), function(v)
  fisher.test(table(factor(dat[[v]], 0:1), dat$amy))$p.value), "holm")
for (i in seq_along(race_vars)) cat_row(dat, names(race_vars)[i], paste("Race:", race_vars[i]), race_paper[[i]], race_p[i])

lvl_rows <- function(var, label, paper, ptest) {
  tab <- table(dat[[var]], dat$amy, useNA = "ifany")
  for (lv in names(paper)) {
    k <- if (is.na(lv) || lv == "NA") which(is.na(rownames(tab))) else which(rownames(tab) == lv)
    cnt <- if (length(k)) tab[k, ] else c(0, 0)
    tot <- colSums(tab)
    rep <- c(sprintf("%d (%.0f)", sum(cnt), 100 * sum(cnt) / sum(tot)),
             sprintf("%d (%.0f)", cnt[1], 100 * cnt[1] / tot[1]),
             sprintf("%d (%.0f)", cnt[2], 100 * cnt[2] / tot[2]))
    for (j in 1:3) add("Table1", paste0(label, ": ", lv, c(" - All", " - Abeta-", " - Abeta+")[j]), paper[[lv]][j], rep[j])
  }
  add("Table1", paste(label, "- P (Fisher)"), attr(paper, "p"), fmt_p(ptest))
}
eth_paper <- structure(list("Hispanic or Latino" = c("142 (3)", "103 (3)", "39 (3)"),
  "Not Hispanic or Latino" = c("4309 (96)", "3040 (96)", "1269 (96)"), "Unknown" = c("35 (1)", "20 (1)", "15 (1)")), p = ".19")
lvl_rows("ethnic", "Ethnicity", eth_paper, fisher.test(table(dat$ethnic, dat$amy))$p.value)
mar_paper <- structure(list(Married = c("3166 (71)", "2223 (70)", "943 (71)"), Divorced = c("628 (14)", "438 (14)", "190 (14)"),
  Widowed = c("426 (9)", "304 (10)", "122 (9)"), "Never married" = c("183 (4)", "135 (4)", "48 (4)"),
  Unknown = c("83 (2)", "63 (2)", "20 (2)")), p = ".66")
lvl_rows("marital", "Marital status", mar_paper, fisher.test(table(dat$marital, dat$amy), simulate.p.value = TRUE, B = 1e5)$p.value)
cat_row(dat, "retired", "Participant retired", c("3401 (76)", "2396 (76)", "1005 (76)", ".93"))
ret3 <- table(addNA(ptdemog$PTNOTRT[match(dat$BID, ptdemog$BID)]), dat$amy)
add("Table1", "Participant retired - P (Fisher, all response levels) [alt]", ".93",
    fmt_p(fisher.test(ret3, simulate.p.value = TRUE, B = 1e5)$p.value))
add("Table1", "Family history - exact Fisher P", ".001", sprintf("%.1e", fisher.test(table(dat$famhx, dat$amy))$p.value))
cat_row(dat, "famhx", "Family history of dementia (parent or sibling)", c("3113 (69)", "2137 (68)", "976 (74)", ".001"))
cat_row(dat, "famhx_parent", "Family history (parent only) [alt]", c("3113 (69)", "2137 (68)", "976 (74)", ".001"))

# APOE genotype: each genotype vs others among genotyped, Fisher + Holm
gts <- c("E2/E2", "E2/E3", "E2/E4", "E3/E3", "E3/E4", "E4/E4")
apoe_paper <- list(c("25 (1)", "23 (1)", "2 (0)", ".03"), c("449 (10)", "380 (12)", "69 (5)", "<.001"),
  c("116 (3)", "74 (2)", "42 (3)", ".12"), c("2417 (54)", "1936 (61)", "481 (36)", "<.001"),
  c("1295 (29)", "684 (22)", "611 (46)", "<.001"), c("139 (3)", "34 (1)", "105 (8)", "<.001"))
gd <- dat %>% filter(!is.na(apoe))
apoe_p <- p.adjust(sapply(gts, function(g) fisher.test(table(factor(gd$apoe == g, c(FALSE, TRUE)), gd$amy))$p.value), "holm")
for (i in seq_along(gts)) {
  dat[[paste0("gt", i)]] <- as.integer(dat$apoe == gts[i])
  cat_row(dat, paste0("gt", i), paste("APOE", gts[i]), apoe_paper[[i]], apoe_p[i])
}
add("Table1", "APOE missing", "45 (1.0%)", sprintf("%d (%.1f%%)", sum(is.na(dat$apoe)), 100 * mean(is.na(dat$apoe))))
add("APOE", "e4 carriers among Abeta+ (%)", "58%", sprintf("%.1f%%", 100 * mean(dat$e4[dat$amy == 1], na.rm = TRUE)))
add("APOE", "e4 carriers among Abeta- (%)", "25%", sprintf("%.1f%%", 100 * mean(dat$e4[dat$amy == 0], na.rm = TRUE)))
pos <- dat %>% filter(amy == 1, !is.na(e4))
add("APOE", "SUVr among Abeta+: e4 carriers", "1.36 (0.176)", fmt_msd(pos$suvr[pos$e4 == 1], 3))
add("APOE", "SUVr among Abeta+: non-carriers", "1.2 (0.175)", fmt_msd(pos$suvr[pos$e4 == 0], 3))
add("APOE", "SUVr among Abeta+: P (Welch)", "<.001", fmt_p(t.test(suvr ~ e4, data = pos)$p.value))

# ---------------------------------------------------------------------------
# 5. Table 2: lifestyle, PACC and components, CFI
# ---------------------------------------------------------------------------
t2 <- list(
  aerobic = list("Aerobic exercise, h/wk", c("2.89 (3.81)", "2.89 (3.85)", "2.90 (3.72)", "0 (-0.08 to 0.09)", "0.01 (-0.05 to 0.08)", ".91", ".66")),
  walking = list("Walking, min/d", c("58.53 (61.22)", "58.84 (61.39)", "57.78 (60.83)", "-0.02 (-0.11 to 0.06)", "-0.01 (-0.07 to 0.06)", ".60", ".83")),
  sleep = list("Sleep, h/night", c("7.11 (1.07)", "7.12 (1.06)", "7.07 (1.07)", "-0.07 (-0.15 to 0.02)", "-0.05 (-0.12 to 0.01)", ".13", ".11")),
  caffeine = list("Caffeine, cups/d", c("2.20 (2.11)", "2.21 (2.12)", "2.17 (2.09)", "-0.02 (-0.11 to 0.06)", "0 (-0.07 to 0.06)", ".62", ".95")),
  alcohol = list("Alcohol, drinks/d", c("0.78 (1.19)", "0.79 (1.28)", "0.75 (0.92)", "-0.05 (-0.12 to 0.03)", "-0.03 (-0.10 to 0.03)", ".21", ".29")),
  tobacco = list("Tobacco, packs/d", c("0.03 (0.47)", "0.04 (0.53)", "0.02 (0.26)", "-0.03 (-0.10 to 0.03)", "-0.02 (-0.09 to 0.04)", ".29", ".46")),
  bmi = list("BMI", c("27.50 (5.09)", "27.53 (5.09)", "27.44 (5.07)", "-0.02 (-0.11 to 0.06)", "0 (-0.07 to 0.06)", ".61", ".93")),
  pacc = list("PACC (sum of z)", c("0.00 (2.54)", "0.18 (2.45)", "-0.43 (2.68)", "-0.32 (-0.41 to -0.23)", "-0.18 (-0.25 to -0.12)", "<.001", "<.001")),
  mmse = list("MMSE", c("28.81 (1.21)", "28.84 (1.18)", "28.73 (1.28)", "-0.11 (-0.20 to -0.02)", "-0.05 (-0.12 to 0.01)", ".01", ".10")),
  fc_free = list("FCSRT free", c("28.97 (5.59)", "29.28 (5.49)", "28.21 (5.75)", "-0.26 (-0.35 to -0.17)", "-0.14 (-0.21 to -0.08)", "<.001", "<.001")),
  fc_total = list("FCSRT total", c("47.37 (0.91)", "47.41 (0.87)", "47.28 (0.99)", "-0.19 (-0.28 to -0.10)", "-0.12 (-0.18 to -0.05)", "<.001", "<.001")),
  lmdr = list("Logical memory delay", c("11.71 (3.21)", "11.83 (3.16)", "11.43 (3.31)", "-0.17 (-0.26 to -0.08)", "-0.1 (-0.16 to -0.03)", "<.001", ".003")),
  dsst = list("Digit symbol", c("43.77 (8.96)", "44.28 (8.93)", "42.53 (8.92)", "-0.26 (-0.35 to -0.18)", "-0.13 (-0.20 to -0.07)", "<.001", "<.001")),
  cfi_self = list("CFI-self", c("2.03 (2.08)", "1.89 (2.01)", "2.36 (2.20)", "0.31 (0.22 to 0.40)", "0.21 (0.15 to 0.27)", "<.001", "<.001")),
  cfi_sp = list("CFI-study partner", c("1.26 (1.85)", "1.17 (1.77)", "1.49 (2.02)", "0.23 (0.14 to 0.32)", "0.16 (0.09 to 0.22)", "<.001", "<.001")))

table2 <- function(d, section = "Table2", vars = names(t2)) {
  for (v in vars) {
    lab <- t2[[v]][[1]]; pv <- t2[[v]][[2]]; x <- d[[v]]; g <- d$amy
    ad <- adj_d(d, v)
    rep <- c(fmt_msd(x), fmt_msd(x[g == 0]), fmt_msd(x[g == 1]), fmt_ci(cohen_d(x, g)), fmt_ci(ad),
             fmt_p(t.test(x[g == 1], x[g == 0])$p.value), fmt_p(ad["p"]))
    cols <- c("All", "Abeta-", "Abeta+", "Cohen d", "Adjusted d", "P", "Adjusted P")
    for (j in seq_along(cols)) add(section, paste(lab, "-", cols[j]), pv[j], rep[j], if (j == 1) sum(!is.na(x)) else NA)
  }
}
table2(dat)

# Pooled-SD Cohen d implied by the paper's OWN printed means/SDs (internal consistency check)
implied_d <- function(m0, s0, m1, s1, n0 = 3163, n1 = 1323) (m1 - m0) / sqrt(((n0 - 1) * s0^2 + (n1 - 1) * s1^2) / (n0 + n1 - 2))
add("Check", "PACC d implied by paper's Table 2 means/SDs", "-0.32 (printed)", sprintf("%.2f", implied_d(0.18, 2.45, -0.43, 2.68)))
add("Check", "CFI-self d implied by paper's Table 2 means/SDs", "0.31 (printed)", sprintf("%.2f", implied_d(1.89, 2.01, 2.36, 2.20)))
add("Check", "Digit symbol d implied by paper's Table 2 means/SDs", "-0.26 (printed)", sprintf("%.2f", implied_d(44.28, 8.93, 42.53, 8.92)))

# Combined CFI and other in-text associations
add("Text", "CFI self+partner Cohen d", "0.33", sprintf("%.2f", cohen_d(dat$cfi_comb, dat$amy)["d"]))
add("Text", "CFI self+partner P", "<.0001", fmt_p(t.test(cfi_comb ~ amy, data = dat)$p.value))

# APOE e4 x Abeta interaction on FCSRT free recall (adjusted for age, sex, education)
fit_int <- lm(fc_free ~ amy * e4 + age + female + educ, data = dat)
ci <- coef(summary(fit_int))["amy:e4", ]
add("Text", "FCSRT free: Abeta x e4 interaction estimate (SE)", "-0.920 (0.363)", sprintf("%.3f (%.3f)", ci[1], ci[2]))
add("Text", "FCSRT free: Abeta x e4 interaction t, P", "t=-2.536, P=.01", sprintf("t=%.3f, P=%s", ci[3], fmt_p(ci[4])))

# Sex x Abeta interaction on PACC (paper: women better, no interaction)
fit_sex <- lm(pacc ~ amy * female + age + educ, data = dat)
cs <- coef(summary(fit_sex))
add("Text", "PACC: female main effect (est, P)", "women better", sprintf("%.2f, P=%s", cs["female", 1], fmt_p(cs["female", 4])))
add("Text", "PACC: Abeta x sex interaction P", "not significant", fmt_p(cs["amy:female", 4]))

# e4 effect on CFI, adjusted for Abeta, age, sex, education (standardised outcome)
for (v in c("cfi_self", "cfi_sp")) {
  dd <- dat %>% filter(!is.na(.data[[v]]), !is.na(e4)) %>% mutate(y = (.data[[v]] - mean(.data[[v]])) / sd(.data[[v]]))
  f1 <- coef(summary(lm(y ~ e4 + amy + age + female + educ, data = dd)))["e4", ]
  f2 <- coef(summary(lm(y ~ e4 * amy + age + female + educ, data = dd)))["e4:amy", ]
  add("Text", paste(v, "e4 effect d (P)"), ifelse(v == "cfi_self", "0.16 (P=.01)", "0.12 (P=.03)"),
      sprintf("%.2f (P=%s)", f1[1], fmt_p(f1[4])))
  add("Text", paste(v, "e4 x Abeta interaction P"), "no interaction", fmt_p(f2[4]))
}

# ---------------------------------------------------------------------------
# 6. Exploratory predictive model (NOT in the paper): logistic regression for Abeta+
# ---------------------------------------------------------------------------
md <- dat %>% select(amy, age, female, educ, e4, famhx, pacc, cfi_self, cfi_sp) %>% na.omit()
auc_of <- function(f) as.numeric(auc(roc(md$amy, fitted(glm(f, binomial, data = md)), quiet = TRUE)))
add("Exploratory", "AUC: age + sex + education", "not reported", sprintf("%.3f", auc_of(amy ~ age + female + educ)), nrow(md))
add("Exploratory", "AUC: + APOE e4 + family history", "not reported", sprintf("%.3f", auc_of(amy ~ age + female + educ + e4 + famhx)), nrow(md))
add("Exploratory", "AUC: + PACC + CFI self/partner", "not reported",
    sprintf("%.3f", auc_of(amy ~ age + female + educ + e4 + famhx + pacc + cfi_self + cfi_sp)), nrow(md))

# ---------------------------------------------------------------------------
# 7. Injected-error sensitivity runs: headline numbers under plausible analyst mistakes
# ---------------------------------------------------------------------------
headline <- function(d, label) {
  d <- add_pacc(d)
  data.frame(scenario = label, N = nrow(d), n_pacc = sum(!is.na(d$pacc)), abpos = sum(d$amy == 1), pct_pos = round(100 * mean(d$amy), 1),
    age_diff = round(mean(d$age[d$amy == 1]) - mean(d$age[d$amy == 0]), 2),
    e4_pos = round(100 * mean(d$e4[d$amy == 1], na.rm = TRUE), 1), e4_neg = round(100 * mean(d$e4[d$amy == 0], na.rm = TRUE), 1),
    famhx_pos = round(100 * mean(d$famhx[d$amy == 1], na.rm = TRUE), 1), famhx_neg = round(100 * mean(d$famhx[d$amy == 0], na.rm = TRUE), 1),
    pacc_d = round(cohen_d(d$pacc, d$amy)["d"], 2), pacc_adj_d = round(adj_d(d, "pacc")["d"], 2),
    cfi_self_d = round(cohen_d(d$cfi_self, d$amy)["d"], 2), cfi_self_adj_d = round(adj_d(d, "cfi_self")["d"], 2))
}

sens <- list(headline(dat, "0. Correct reproduction"))
if (run_errors) {
  base <- assemble(pet)
  # E1: no rescreen de-duplication (rescreened people counted twice)
  sens[[length(sens) + 1]] <- headline(assemble(build_pet(dedup = FALSE)), "E1. No rescreen de-duplication")
  # E2: amyloid status from SUVR >= 1.15 only (ignores visual-read rule for 1.10-1.15)
  sens[[length(sens) + 1]] <- headline(base %>% mutate(amy = as.integer(pmod_suvr >= 1.15)), "E2. Cutoff SUVR>=1.15 only (pmod_suvr)")
  # E3: cutoff applied to the Composite_Summary SUVR column instead of eligibility SUVR
  sens[[length(sens) + 1]] <- headline(base %>% mutate(amy = as.integer(suvr >= 1.15)), "E3. Cutoff 1.15 on Composite_Summary suvr_cer")
  # E4: cutoff 1.10 (lower threshold, everyone in grey zone called positive)
  sens[[length(sens) + 1]] <- headline(base %>% mutate(amy = as.integer(pmod_suvr >= 1.10)), "E4. Cutoff SUVR>=1.10")
  # E5: visual read (first reader) alone used as amyloid status
  #     (alternative reference-region SUVRs, suvr_persi/suvr_crus, are all missing at screening, so a
  #      wrong-reference-region error cannot be simulated with the package data)
  sens[[length(sens) + 1]] <- headline(base %>% mutate(amy = as.integer(elig_vi_1 == "Positive")), "E5. Visual read only")
  # E6: complete-case analysis across all variables (listwise deletion)
  cc <- base %>% filter(if_all(c(age, educ, female, e4, famhx, aerobic, walking, sleep, caffeine, alcohol, tobacco, bmi,
                                 mmse, lmdr, dsst, fc96, cfi_self, cfi_sp), ~ !is.na(.x)))
  sens[[length(sens) + 1]] <- headline(cc, "E6. Listwise deletion on all variables")
  # E7: randomization-visit (VISCODE 6) cognition from PACC dataset instead of screening visit 1
  #     (only randomized/LEARN participants have it -> massive selection)
  v6 <- PACC %>% filter(VISCODE == 6) %>% select(BID, mmse6 = MMSCORE, lmdr6 = LDELTOTAL, dsst6 = DIGITTOTAL, fc966 = FCTOTAL96)
  e7 <- base %>% left_join(v6, by = "BID") %>% mutate(mmse = mmse6, lmdr = lmdr6, dsst = dsst6, fc96 = fc966)
  sens[[length(sens) + 1]] <- headline(e7, "E7. Cognition from baseline visit 6 (PACC dataset)")
  # E8: family history from parents only (ignores siblings)
  sens[[length(sens) + 1]] <- headline(base %>% mutate(famhx = famhx_parent), "E8. Family history = parents only")
  # E9: APOE e4 "carrier" coded as e4/e4 homozygotes only
  sens[[length(sens) + 1]] <- headline(base %>% mutate(e4 = as.integer(apoe == "E4/E4")), "E9. e4 carrier = E4/E4 only")
  # (Flipping the sex coding was also checked: a binary covariate's coding does not change any
  #  adjusted Abeta estimate, so that error is invisible in the headline numbers.)
}
sens <- bind_rows(sens)

# ---------------------------------------------------------------------------
# 8. Output
# ---------------------------------------------------------------------------
res <- bind_rows(results)
cat("\n=== Population flow ===\n"); print(unlist(flow))
for (s in unique(res$section)) {
  cat("\n===", s, "===\n")
  print(res[res$section == s, c("quantity", "paper", "reproduced", "n")], row.names = FALSE, right = FALSE)
}
cat("\n=== Injected-error sensitivity (headline numbers) ===\n")
print(sens, row.names = FALSE)

write.csv(res, "output/results.csv", row.names = FALSE)
write.csv(sens, "output/sensitivity.csv", row.names = FALSE)
cat(sprintf("\nRuntime: %.1f s\n", as.numeric(difftime(Sys.time(), t0, units = "secs"))))
