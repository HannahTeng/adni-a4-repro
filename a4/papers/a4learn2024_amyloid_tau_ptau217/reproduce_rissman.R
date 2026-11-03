# Reproduction of Rissman RA et al. JPAD 2024;11(4):823-830 (PMC11266279)
# "Longitudinal Phospho-tau217 Predicts Amyloid PET in Asymptomatic AD"
# Prints aggregate results only; writes aggregate CSVs to output/.
# Run: cd <this folder> && Rscript reproduce_rissman.R

suppressPackageStartupMessages({
  library(A4LEARN); library(dplyr); library(tidyr); library(pROC)
  library(nlme); library(splines)
})
options(dplyr.summarise.inform = FALSE, width = 120)
dir.create("output", showWarnings = FALSE)
t_start <- Sys.time()
cat("A4LEARN version:", as.character(packageVersion("A4LEARN")), "\n")

# ---------------------------------------------------------------- population
subj <- SUBJINFO %>%
  filter(MITTFL == 1 | SUBSTUDY == "LEARN") %>%
  mutate(GROUP = factor(ifelse(SUBSTUDY == "LEARN", "LEARN", as.character(TX)),
                        levels = c("Placebo", "Solanezumab", "LEARN")),
         FEMALE = SEX == "Female",
         APOE4 = AAPOEGNPRSNFLG == 1)

ptau_all <- biomarker_pTau217 %>%
  mutate(VISCODE = as.numeric(VISCODE),
         PTAU_RAW = suppressWarnings(as.numeric(ORRESRAW)),   # raw reading incl. <LLOQ / >ULOQ
         PTAU_REP = suppressWarnings(as.numeric(ORRES)),      # reported (censored -> NA)
         DAYS = COLLECTION_DATE_DAYS_T0)

# "baseline" = first available non-missing raw p-tau217 per participant
first_ptau <- function(pt, var = "PTAU_RAW") {
  pt %>% filter(!is.na(.data[[var]])) %>% arrange(BID, VISCODE) %>%
    group_by(BID) %>% slice(1) %>% ungroup() %>%
    transmute(BID, PTAU = .data[[var]], PTAU_VIS = VISCODE)
}
bl <- subj %>% inner_join(first_ptau(ptau_all), by = "BID")

pop_steps <- bind_rows(
  subj %>% count(GROUP) %>% mutate(step = "A4 mITT + LEARN enrolled"),
  bl %>% count(GROUP) %>% mutate(step = "with >=1 numeric p-tau217 (first available)"))
cat("\n== Population derivation\n"); print(pop_steps %>% pivot_wider(names_from = GROUP, values_from = n))
cat("\nVisit providing 'baseline' p-tau217 (counts):\n"); print(table(bl$GROUP, bl$PTAU_VIS))

# ---------------------------------------------------------------- Table 1
v6 <- ADQS %>% filter(VISITCD == "006", QSTESTCD %in% c("PACC", "LMIIa", "MMSE")) %>%
  select(BID, QSTESTCD, QSSTRESN) %>% pivot_wider(names_from = QSTESTCD, values_from = QSSTRESN)
bl <- bl %>% left_join(v6, by = "BID")

msd <- function(x, d = 1) sprintf(paste0("%.", d, "f (%.", d, "f)"), mean(x, na.rm = TRUE), sd(x, na.rm = TRUE))
npct <- function(x) sprintf("%d (%.1f%%)", sum(x, na.rm = TRUE), 100 * mean(x, na.rm = TRUE))
tab1 <- function(d) {
  d %>% summarise(N = as.character(n()),
    Age = msd(AGEYR), Female = npct(FEMALE), Education = msd(EDCCNTU),
    White = npct(RACE == "White"), Black = npct(RACE == "Black or African American"),
    Asian = npct(RACE == "Asian"), Hispanic = npct(ETHNIC == "Hispanic or Latino"),
    `APOE E3/E4` = npct(APOEGN == "E3/E4"), `APOE E4/E4` = npct(APOEGN == "E4/E4"),
    `APOE E3/E3` = npct(APOEGN == "E3/E3"),
    `FBP SUVr` = msd(SUVRCER), `FBP Centiloid` = msd(AMYLCENT),
    `P-tau217 (U/mL)` = msd(PTAU, 2), PACC = msd(PACC), `LM Delayed Recall` = msd(LMIIa),
    MMSE = msd(MMSE))
}
t1 <- bind_rows(bl %>% group_by(GROUP) %>% tab1() %>% mutate(GROUP = as.character(GROUP)),
                bl %>% tab1() %>% mutate(GROUP = "Total")) %>%
  pivot_longer(-GROUP) %>% pivot_wider(names_from = GROUP, values_from = value)
cat("\n== Table 1 (reproduced)\n"); print(as.data.frame(t1), right = FALSE)
write.csv(t1, "output/rissman_table1.csv", row.names = FALSE)

# ---------------------------------------------------------------- ROC
roc_row <- function(d, cut, label, pred = "PTAU", cl = "AMYLCENT") {
  y <- d[[cl]] >= cut
  if (length(unique(na.omit(y))) < 2)
    return(tibble(analysis = label, cutoff_CL = cut, N = sum(!is.na(y)), N_pos = sum(y, na.rm = TRUE)))
  r <- pROC::roc(y, d[[pred]], quiet = TRUE, direction = "<", levels = c(FALSE, TRUE))
  ci <- as.numeric(pROC::ci.auc(r, method = "delong"))
  yo <- pROC::coords(r, "best", best.method = "youden", ret = c("threshold", "sensitivity", "specificity"))[1, ]
  tibble(analysis = label, cutoff_CL = cut, N = sum(!is.na(y) & !is.na(d[[pred]])), N_pos = sum(y, na.rm = TRUE),
         AUC = ci[2], lo = ci[1], hi = ci[3],
         youden_thr = yo$threshold, sens = yo$sensitivity, spec = yo$specificity)
}
roc_main <- bind_rows(roc_row(bl, 20, "Primary: A4 mITT + LEARN"),
                      roc_row(bl, 33, "Primary: A4 mITT + LEARN"))
cat("\n== ROC: baseline p-tau217 vs amyloid PET positivity (DeLong 95% CI)\n"); print(as.data.frame(roc_main), digits = 3)

# ---------------------------------------------------------------- correlations
spear <- function(x, y) {
  ok <- complete.cases(x, y); n <- sum(ok)
  r <- cor(x[ok], y[ok], method = "spearman"); z <- atanh(r); se <- 1 / sqrt(n - 3)
  tibble(N = n, rho = r, lo = tanh(z - 1.96 * se), hi = tanh(z + 1.96 * se))
}
cor_cl <- spear(bl$PTAU, bl$AMYLCENT) %>% mutate(quantity = "Spearman p-tau217 vs Centiloid")

# Test-retest: placebo wk0 vs wk12 (<=143 d apart), LEARN visit 1 vs 24 (1.4-1.75 y apart)
pair <- function(v1, v2, grp, lo, hi) {
  ptau_all %>% filter(VISCODE %in% c(v1, v2), !is.na(PTAU_RAW)) %>%
    inner_join(subj %>% filter(GROUP == grp) %>% select(BID), by = "BID") %>%
    select(BID, VISCODE, PTAU_RAW, DAYS) %>%
    pivot_wider(names_from = VISCODE, values_from = c(PTAU_RAW, DAYS)) %>%
    rename(a = 2, b = 3, da = 4, db = 5) %>%
    filter(!is.na(a), !is.na(b), (db - da) >= lo, (db - da) <= hi)
}
rep_pairs <- bind_rows(pair(6, 9, "Placebo", 0, 143) %>% mutate(g = "Placebo"),
                       pair(1, 24, "LEARN", 1.4 * 365.25, 1.75 * 365.25) %>% mutate(g = "LEARN"))
cor_rep <- bind_rows(spear(rep_pairs$a, rep_pairs$b) %>% mutate(quantity = "Repeatability (pooled)"),
                     rep_pairs %>% group_by(g) %>% group_modify(~ spear(.x$a, .x$b)) %>% ungroup() %>%
                       mutate(quantity = paste("Repeatability", g)) %>% select(-g))
cors <- bind_rows(cor_cl, cor_rep)
cat("\n== Spearman correlations (Fisher-z 95% CI)\n"); print(as.data.frame(cors), digits = 3)
cat("CSF Abeta42/40 is not distributed in A4LEARN -> correlation with CSF not reproducible.\n")

# ---------------------------------------------------------------- longitudinal (A4 mITT)
a4 <- subj %>% filter(GROUP != "LEARN") %>% mutate(TX = droplevels(GROUP))
# Samples of the blinded period: baseline (6), week 12 (9), week 240 (66), early-termination endpoint (999).
# VISCODE 997 (open-label end, median ~7 y) is excluded.
pt_long <- ptau_all %>% filter(!is.na(PTAU_RAW), !is.na(DAYS), VISCODE %in% c(6, 9, 66, 999)) %>%
  inner_join(a4 %>% select(BID, TX, AGEYR, APOE4), by = "BID") %>%
  mutate(WEEK = pmax(DAYS, 0) / 7, Y = PTAU_RAW)
am_long <- imaging_SUVR_amyloid %>% filter(brain_region == "Composite_Summary") %>%
  inner_join(a4 %>% select(BID, TX, AGEYR, APOE4), by = "BID") %>%
  mutate(WEEK = ifelse(VISCODE == 2, 0, pmax(scan_date_DAYS_T0, 0) / 7),
         Y = 183.07 * suvr_cer - 177.26) %>% filter(!is.na(Y), !is.na(WEEK))

fit_spline <- function(d, label, df = 2) {
  # df = 2: natural cubic spline in weeks; df = 1: linear (amyloid PET has ~2 scans/person)
  bk <- c(0, max(d$WEEK))
  basis <- if (df == 2) ns(d$WEEK, df = 2, Boundary.knots = bk) else matrix(d$WEEK / 52, ncol = 1)
  for (j in seq_len(df)) d[[paste0("s", j)]] <- basis[, j]
  d$YR <- d$WEEK / 52
  d$SOLA <- as.numeric(d$TX == "Solanezumab")
  # No baseline treatment difference (constrained, as in the A4 primary analysis)
  sv <- paste0("s", seq_len(df))
  fo <- as.formula(paste("Y ~", paste(c(sv, paste0(sv, ":SOLA"), "AGEYR", "APOE4"), collapse = " + ")))
  m <- lme(fo, data = d, random = ~ YR | BID,
           control = lmeControl(opt = "optim", maxIter = 200), na.action = na.omit)
  b240 <- if (df == 2) predict(basis, 240) else 240 / 52
  L <- setNames(rep(0, length(fixef(m))), names(fixef(m)))
  L[paste0(sv, ":SOLA")] <- b240
  est <- sum(L * fixef(m)); se <- sqrt(drop(t(L) %*% vcov(m) %*% L))
  list(model = m,
       res = tibble(outcome = label, N = n_distinct(d$BID), obs = nrow(d),
                    diff_wk240 = est, lo = est - 1.96 * se, hi = est + 1.96 * se,
                    p = 2 * pnorm(-abs(est / se))))
}
f_pt <- fit_spline(pt_long, "P-tau217 (U/mL), Sola - Pbo at wk 240")
f_am <- fit_spline(am_long, "Amyloid PET (CL), Sola - Pbo at wk 240 [linear time]", df = 1)
long_res <- bind_rows(f_pt$res, f_am$res)
cat("\n== Treatment-group differences at week 240 (natural spline, 2 df; adj. age, APOE4)\n")
print(as.data.frame(long_res), digits = 3)

# Participant-specific annualised change (BLUP slopes) correlation p-tau217 vs CL
slope <- function(f) {
  re <- ranef(f$model); tibble(BID = rownames(re), sl = re$YR)
}
sl <- inner_join(slope(f_pt), slope(f_am), by = "BID", suffix = c("_pt", "_cl"))
cor_slope <- spear(sl$sl_pt, sl$sl_cl) %>% mutate(quantity = "Spearman of BLUP annual slopes: p-tau217 vs CL (A4)")
cat("\n"); print(as.data.frame(cor_slope), digits = 3)

# ---------------------------------------------------------------- injected-error variants
inj <- list()
# E1: use reported ORRES (values <LLOQ / >ULOQ become missing) instead of ORRESRAW
bl_rep <- subj %>% inner_join(first_ptau(ptau_all, "PTAU_REP"), by = "BID")
inj$E1 <- bind_rows(roc_row(bl_rep, 20, "E1: censored ORRES (drop <LLOQ/>ULOQ)"),
                    roc_row(bl_rep, 33, "E1: censored ORRES (drop <LLOQ/>ULOQ)"))
# E2: spectrum - A4 only (drop the amyloid-negative LEARN cohort)
inj$E2 <- bind_rows(roc_row(filter(bl, GROUP != "LEARN"), 20, "E2: A4 only (no LEARN)"),
                    roc_row(filter(bl, GROUP != "LEARN"), 33, "E2: A4 only (no LEARN)"))
# E3: wrong Centiloid transform - ADNI whole-cerebellum FBP equation (196.9*SUVR - 196.03)
#     applied to A4 SUVRs instead of the A4 equation (183.07*SUVR - 177.26)
bl_e3 <- bl %>% mutate(CL_ADNI = 196.9 * SUVRCER - 196.03)
inj$E3 <- bind_rows(roc_row(bl_e3, 20, "E3: ADNI CL equation", cl = "CL_ADNI"),
                    roc_row(bl_e3, 33, "E3: ADNI CL equation", cl = "CL_ADNI"))
cat("E3: positives at 20/33 CL with ADNI equation:", sum(bl_e3$CL_ADNI >= 20), "/", sum(bl_e3$CL_ADNI >= 33),
    " vs correct", sum(bl$AMYLCENT >= 20), "/", sum(bl$AMYLCENT >= 33), "\n")
# E4: leakage - logistic model (p-tau217 + age + APOE4) evaluated in-sample vs 10-fold CV
set.seed(20240724)
cv_auc <- function(d, cut) {
  d <- d %>% mutate(y = AMYLCENT >= cut) %>% filter(!is.na(APOE4))
  fo <- y ~ log(PTAU) + AGEYR + APOE4
  ins <- as.numeric(pROC::auc(d$y, fitted(glm(fo, binomial, d)), quiet = TRUE))
  fold <- sample(rep(1:10, length.out = nrow(d))); pr <- numeric(nrow(d))
  for (k in 1:10) pr[fold == k] <- predict(glm(fo, binomial, d[fold != k, ]), d[fold == k, ], type = "response")
  tibble(cutoff_CL = cut, AUC_in_sample = ins, AUC_10fold_CV = as.numeric(pROC::auc(d$y, pr, quiet = TRUE)))
}
inj_e4 <- bind_rows(cv_auc(bl, 20), cv_auc(bl, 33)) %>% mutate(analysis = "E4: p-tau217+age+APOE4 logistic")
# E5: baseline restricted to protocol baseline visit only (A4 wk0 / LEARN visit 1), no fallback
bl_strict <- subj %>% inner_join(ptau_all %>% filter(VISCODE %in% c(1, 6), !is.na(PTAU_RAW)) %>%
                                   transmute(BID, PTAU = PTAU_RAW), by = "BID")
inj$E5 <- bind_rows(roc_row(bl_strict, 20, "E5: strict baseline visit only"),
                    roc_row(bl_strict, 33, "E5: strict baseline visit only"))
inj_tab <- bind_rows(roc_main, bind_rows(inj))
cat("\n== Injected-error variants (ROC)\n"); print(as.data.frame(inj_tab), digits = 3)
cat("\n"); print(as.data.frame(inj_e4), digits = 3)
cat("E1 Ns by group:\n"); print(table(bl_rep$GROUP))

write.csv(roc_main, "output/rissman_roc.csv", row.names = FALSE)
write.csv(bind_rows(cors, cor_slope), "output/rissman_correlations.csv", row.names = FALSE)
write.csv(long_res, "output/rissman_longitudinal.csv", row.names = FALSE)
write.csv(inj_tab, "output/rissman_injected_roc.csv", row.names = FALSE)
write.csv(inj_e4, "output/rissman_injected_leakage.csv", row.names = FALSE)
cat("\nRuntime:", round(as.numeric(difftime(Sys.time(), t_start, units = "secs"))), "s\n")
