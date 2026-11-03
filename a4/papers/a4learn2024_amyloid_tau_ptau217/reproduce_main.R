# Reproduction of Sperling RA, Donohue MC, Rissman RA, et al. JPAD 2024;11(4):802-813 (PMC11266444)
# "Amyloid and Tau Prediction of Cognitive and Functional Decline in Unimpaired Older
#  Individuals: Longitudinal Data from the A4 and LEARN Studies"
# Prints aggregate results only; writes aggregate CSVs to output/.
# Run: cd <this folder> && Rscript reproduce_main.R

suppressPackageStartupMessages({
  library(A4LEARN); library(dplyr); library(tidyr); library(nlme); library(splines); library(survival)
})
options(dplyr.summarise.inform = FALSE, width = 140)
dir.create("output", showWarnings = FALSE)
t_start <- Sys.time()
cat("A4LEARN version:", as.character(packageVersion("A4LEARN")), "\n")

# =============================================================== population & baseline data
fh <- famhxpar %>% group_by(BID) %>% summarise(fp = any(MOTHER == 1 | FATHER == 1, na.rm = TRUE)) %>%
  full_join(famhxsib %>% group_by(BID) %>% summarise(fs = any(SIBDEMENT == 1, na.rm = TRUE)), by = "BID") %>%
  transmute(BID, FAMHX = coalesce(fp, FALSE) | coalesce(fs, FALSE))

v6 <- ADQS %>% filter(VISITCD == "006", QSTESTCD %in% c("PACC", "LMIIa", "MMSE")) %>%
  select(BID, QSTESTCD, QSSTRESN) %>% pivot_wider(names_from = QSTESTCD, values_from = QSSTRESN)
v1 <- ADQS %>% filter(VISITCD == "001", QSTESTCD %in% c("CFITOTAL", "ADLPQSP", "CDRSB", "CDSOB")) %>%
  select(BID, QSTESTCD, QSSTRESN) %>% pivot_wider(names_from = QSTESTCD, values_from = QSSTRESN) %>%
  mutate(CDRSB = coalesce(CDRSB, CDSOB)) %>% select(-CDSOB)

ptau <- biomarker_pTau217 %>%
  mutate(VISCODE = as.numeric(VISCODE),
         RAW = suppressWarnings(as.numeric(ORRESRAW)), REP = suppressWarnings(as.numeric(ORRES)))
ptau_bl <- ptau %>% filter(VISCODE %in% c(1, 6)) %>%      # protocol baseline: A4 wk0 (6), LEARN visit 1
  group_by(BID) %>% slice(1) %>% ungroup() %>% transmute(BID, PTAU = RAW, PTAU_REP = REP)

# Early neocortical tau: mean of inferior temporal, fusiform, middle temporal, inferior parietal (L/R),
# FreeSurfer VOIs, cerebellar crus reference (suvr_crus; suvr_cer is empty for tau), first tau scan
neo_regions <- paste0(rep(c("inferiortemporal", "fusiform", "middletemporal", "inferiorparietal"), each = 2),
                      c("_lh_VOI", "_rh_VOI"))
tau_first <- imaging_SUVR_tau %>% filter(SUBSTUDY == "A4") %>%
  group_by(BID) %>% filter(VISCODE == min(VISCODE)) %>% ungroup()
tau_comp <- function(regions, ref = "suvr_crus", name = "NEO") {
  tau_first %>% filter(brain_region %in% regions) %>% group_by(BID) %>%
    summarise(!!name := mean(.data[[ref]], na.rm = TRUE)) %>% filter(is.finite(.data[[name]]))
}
tau <- tau_comp(neo_regions)

base <- SUBJINFO %>%
  filter(MITTFL == 1 | SUBSTUDY == "LEARN") %>%
  mutate(GROUP = factor(ifelse(SUBSTUDY == "LEARN", "LEARN", as.character(TX)),
                        levels = c("Placebo", "Solanezumab", "LEARN")),
         FEMALE = as.numeric(SEX == "Female"), APOE4 = as.numeric(AAPOEGNPRSNFLG == 1),
         URG = as.numeric(RACE != "White" | ETHNIC == "Hispanic or Latino"),
         CL = AMYLCENT) %>%
  left_join(fh, by = "BID") %>% left_join(v6, by = "BID") %>% left_join(v1, by = "BID") %>%
  left_join(ptau_bl, by = "BID") %>% left_join(tau, by = "BID")

steps <- list(
  "A4 mITT + LEARN enrolled" = base,
  "with baseline p-tau217 (raw)" = filter(base, !is.na(PTAU)),
  "with baseline p-tau217 + all 9 other baseline predictors" =
    filter(base, !is.na(PTAU), !is.na(CL), !is.na(PACC), !is.na(CFITOTAL), !is.na(APOE4), !is.na(EDCCNTU)),
  "Tau substudy: + early neocortical tau (A4 only)" =
    filter(base, !is.na(PTAU), !is.na(CL), !is.na(PACC), !is.na(CFITOTAL), !is.na(APOE4), !is.na(NEO)))
pop <- bind_rows(lapply(names(steps), function(s) steps[[s]] %>% count(GROUP) %>% mutate(step = s))) %>%
  pivot_wider(names_from = GROUP, values_from = n, values_fill = 0)
cat("\n== Population derivation (counts)\n"); print(as.data.frame(pop), right = FALSE)
cat("TAUPETFL==1 among A4 mITT:", sum(base$TAUPETFL == 1 & base$GROUP != "LEARN"),
    "; with any tau scan:", sum(!is.na(base$NEO)), "\n")
write.csv(pop, "output/main_population.csv", row.names = FALSE)

# =============================================================== Table 1 (p-tau217 subset)
msd <- function(x, d = 1) sprintf(paste0("%.", d, "f (%.", d, "f)"), mean(x, na.rm = TRUE), sd(x, na.rm = TRUE))
npct <- function(x) sprintf("%d (%.1f%%)", sum(x, na.rm = TRUE), 100 * mean(x, na.rm = TRUE))
tab1 <- function(d) d %>% summarise(N = as.character(n()), Age = msd(AGEYR), Female = npct(FEMALE == 1),
  Education = msd(EDCCNTU), White = npct(RACE == "White"), Hispanic = npct(ETHNIC == "Hispanic or Latino"),
  `Family history` = npct(FAMHX), `E3/E3` = npct(APOEGN == "E3/E3"), `E3/E4` = npct(APOEGN == "E3/E4"),
  `E4/E4` = npct(APOEGN == "E4/E4"), `P-tau217` = msd(PTAU, 2), `FBP SUVr` = msd(SUVRCER, 2),
  `FBP Centiloid` = msd(CL), PACC = msd(PACC), `LM Delayed Recall` = msd(LMIIa), MMSE = msd(MMSE),
  `CFI Combined` = msd(CFITOTAL), `ADL Partner` = msd(ADLPQSP), `CDR-SB` = msd(CDRSB))
tb <- filter(base, !is.na(PTAU))
t1 <- bind_rows(tb %>% group_by(GROUP) %>% tab1() %>% mutate(GROUP = as.character(GROUP)),
                tb %>% filter(GROUP != "LEARN") %>% tab1() %>% mutate(GROUP = "All A4")) %>%
  pivot_longer(-GROUP) %>% pivot_wider(names_from = GROUP, values_from = value)
cat("\n== Table 1 (A4 mITT + LEARN with baseline p-tau217)\n"); print(as.data.frame(t1), right = FALSE)
write.csv(t1, "output/main_table1.csv", row.names = FALSE)

# =============================================================== longitudinal data
long_outcome <- function(code) {
  ADQS %>% filter(QSTESTCD %in% code, BID %in% base$BID, !is.na(QSSTRESN), !is.na(ADURW),
                  EPOCH %in% c("BLINDED TREATMENT", "Analysis visit <= 66", "SCREENING") ) %>%
    filter(EPOCH != "SCREENING" | VISITCD == "001") %>%
    transmute(BID, Y = QSSTRESN, WEEK = pmax(ADURW, 0), QSVERSION = factor(coalesce(QSVERSION, "NA")),
              VISITCD, EPOCH)
}
pacc_long <- long_outcome("PACC") %>% filter(VISITCD != "001")   # PACC baseline is visit 6 (week 0)
cat("\nPACC observations used:", nrow(pacc_long), " participants:", n_distinct(pacc_long$BID), "\n")

# =============================================================== tertiles (A4 mITT)
a4 <- base %>% filter(GROUP != "LEARN")
cl_cut <- quantile(a4$CL, c(1, 2) / 3, na.rm = TRUE)
pt_cut <- quantile(a4$PTAU, c(1, 2) / 3, na.rm = TRUE)
cat("\n== Tertile cutpoints in A4 mITT: Centiloid", round(cl_cut, 1), "| p-tau217", round(pt_cut, 3), "U/mL\n")
base <- base %>% mutate(
  CL_T = ifelse(GROUP == "LEARN", "LEARN", paste0("CL_T", cut(CL, c(-Inf, cl_cut, Inf), labels = FALSE))),
  PT_T = ifelse(GROUP == "LEARN", "LEARN",
                ifelse(is.na(PTAU), NA, paste0("PT_T", cut(PTAU, c(-Inf, pt_cut, Inf), labels = FALSE)))))

# Mixed model with natural-spline time (2 df) by group; random intercept + linear slope
spline_by_group <- function(d, grp, label, version = TRUE) {
  d <- d %>% inner_join(base %>% select(BID, G = all_of(grp), AGEYR, EDCCNTU, APOE4), by = "BID") %>%
    filter(!is.na(G)) %>% mutate(G = relevel(factor(G), ref = "LEARN"), YR = WEEK / 52)
  basis <- ns(d$WEEK, df = 2, Boundary.knots = c(0, max(d$WEEK)))
  d$s1 <- basis[, 1]; d$s2 <- basis[, 2]
  fo <- Y ~ (s1 + s2) * G + AGEYR + EDCCNTU + APOE4
  if (version) fo <- update(fo, . ~ . + QSVERSION)
  m <- lme(fo, data = d, random = ~ YR | BID, na.action = na.omit,
           control = lmeControl(opt = "optim", maxIter = 200, msMaxIter = 200))
  b <- predict(basis, 240); fe <- fixef(m); V <- vcov(m)
  bind_rows(lapply(levels(d$G), function(g) {
    L <- setNames(rep(0, length(fe)), names(fe)); L[c("s1", "s2")] <- b
    if (g != "LEARN") L[paste0(c("s1:G", "s2:G"), g)] <- b
    est <- sum(L * fe); se <- sqrt(drop(t(L) %*% V %*% L))
    tibble(outcome = label, grouping = grp, group = g, N = n_distinct(d$BID[d$G == g]),
           change_wk240 = est, lo = est - 1.96 * se, hi = est + 1.96 * se)
  }))
}
func_long <- list(CFI = long_outcome("CFITOTAL"), ADL = long_outcome("ADLPQSP"),
                  `CDR-SB` = long_outcome(c("CDRSB", "CDSOB")))
traj <- bind_rows(
  spline_by_group(pacc_long, "CL_T", "PACC"), spline_by_group(pacc_long, "PT_T", "PACC"),
  bind_rows(lapply(names(func_long), function(o) bind_rows(
    spline_by_group(func_long[[o]], "CL_T", o, version = FALSE),
    spline_by_group(func_long[[o]], "PT_T", o, version = FALSE)))))
cat("\n== Model-estimated mean change from baseline at week 240 by tertile (LEARN = reference group)\n")
print(as.data.frame(traj), digits = 3)
write.csv(traj, "output/main_tertile_trajectories.csv", row.names = FALSE)

# =============================================================== CDR-GS progression (Kaplan-Meier)
cdr_l <- cdr %>% filter(BID %in% base$BID, !is.na(CDGLOBAL),
                        EPOCH %in% c("BLINDED TREATMENT", "Analysis visit <= 66", "SCREENING")) %>%
  mutate(WEEK = pmax(CDADTC_DAYS_T0, 0) / 7) %>% arrange(BID, WEEK) %>% group_by(BID) %>%
  mutate(pos = CDGLOBAL > 0, nxt = lead(pos), last = row_number() == n(),
         ev = pos & (coalesce(nxt, FALSE) | last))
km_dat <- cdr_l %>% filter(WEEK > 0 | n() == 1) %>%
  summarise(event = any(ev & WEEK > 0), time = ifelse(event, min(WEEK[ev & WEEK > 0]), max(WEEK))) %>%
  ungroup() %>% inner_join(base %>% select(BID, CL_T, PT_T), by = "BID")
km_at <- function(grp) {
  d <- km_dat %>% filter(!is.na(.data[[grp]]))
  f <- survfit(Surv(time, event) ~ d[[grp]], data = d)
  s <- summary(f, times = c(204, 240), extend = TRUE)
  tibble(grouping = grp, group = sub(".*=", "", s$strata), week = s$time, n_risk = s$n.risk,
         cum_progression = 1 - s$surv, lo = 1 - s$upper, hi = 1 - s$lower)
}
km <- bind_rows(km_at("CL_T"), km_at("PT_T"))
cat("\n== Kaplan-Meier cumulative probability of CDR-GS progression\n"); print(as.data.frame(km), digits = 3)
write.csv(km, "output/main_cdr_progression_km.csv", row.names = FALSE)

# =============================================================== variance explained (commonality)
# Step 1: per-cohort mixed model; participant-specific PACC change at week 240
#         = fixed spline change + BLUP random slope * (240/52)
step1_change <- function(d, cohort_var = "GROUP") {
  d <- d %>% inner_join(base %>% select(BID, C = all_of(cohort_var), AGEYR, EDCCNTU, APOE4), by = "BID") %>%
    filter(!is.na(C), !is.na(APOE4)) %>% mutate(YR = WEEK / 52)
  bind_rows(lapply(split(d, d$C), function(dc) {
    basis <- ns(dc$WEEK, df = 2, Boundary.knots = c(0, max(dc$WEEK)))
    dc$s1 <- basis[, 1]; dc$s2 <- basis[, 2]
    fo <- if (nlevels(droplevels(dc$QSVERSION)) > 1) Y ~ s1 + s2 + AGEYR + EDCCNTU + APOE4 + QSVERSION
          else Y ~ s1 + s2 + AGEYR + EDCCNTU + APOE4
    m <- lme(fo, data = dc, random = ~ YR | BID, na.action = na.omit,
             control = lmeControl(opt = "optim", maxIter = 200, msMaxIter = 200))
    fixed <- sum(fixef(m)[c("s1", "s2")] * predict(basis, 240))
    re <- ranef(m)
    tibble(BID = rownames(re), CHG240 = fixed + re$YR * 240 / 52)
  }))
}
chg <- step1_change(pacc_long)

preds_base <- c(Amyloid = "CL", `P-tau217` = "PTAU", `Baseline PACC` = "PACC", `Baseline CFI` = "CFITOTAL",
                Age = "AGEYR", APOE4 = "APOE4", Female = "FEMALE", Education = "EDCCNTU", URG = "URG",
                Treatment = "TRT")
commonality <- function(d, preds, label) {
  d <- d %>% select(CHG240, all_of(unname(preds))) %>% na.omit()
  preds <- preds[sapply(preds, function(p) length(unique(d[[p]])) > 1)]
  rhs <- function(p) if (length(p)) paste(p, collapse = " + ") else "1"
  full <- lm(as.formula(paste("CHG240 ~", rhs(preds))), d); R2 <- summary(full)$r.squared
  bind_rows(lapply(names(preds), function(nm) {
    red <- lm(as.formula(paste("CHG240 ~", rhs(preds[names(preds) != nm]))), d)
    alone <- summary(lm(as.formula(paste("CHG240 ~", preds[[nm]])), d))$r.squared
    U <- R2 - summary(red)$r.squared
    tibble(analysis = label, N = nrow(d), total_R2 = R2, predictor = nm, unique_R2 = U,
           common_R2 = alone - U, p_unique = anova(red, full)$`Pr(>F)`[2])
  }))
}
dat <- base %>% inner_join(chg, by = "BID") %>%
  mutate(TRT = factor(ifelse(GROUP == "LEARN", "LEARN", as.character(GROUP))))
run_set <- function(dat, preds_tau = c(preds_base, `Neocortical tau` = "NEO"), tag = "") {
  a4d <- filter(dat, GROUP != "LEARN")
  bind_rows(
    commonality(filter(dat, GROUP == "LEARN"), preds_base, paste0(tag, "LEARN")),
    commonality(dat, preds_base, paste0(tag, "LEARN + all A4")),
    commonality(filter(dat, GROUP == "Placebo"), preds_base, paste0(tag, "A4 placebo")),
    commonality(filter(dat, GROUP == "Solanezumab"), preds_base, paste0(tag, "A4 solanezumab")),
    commonality(a4d, preds_base, paste0(tag, "A4 combined")),
    commonality(filter(a4d, GROUP == "Placebo", !is.na(NEO)), preds_tau, paste0(tag, "Tau: placebo")),
    commonality(filter(a4d, GROUP == "Solanezumab", !is.na(NEO)), preds_tau, paste0(tag, "Tau: solanezumab")),
    commonality(filter(a4d, !is.na(NEO)), preds_tau, paste0(tag, "Tau: A4 combined")))
}
r2 <- run_set(dat)
paper_r2 <- c(LEARN = 0.163, `LEARN + all A4` = 0.341, `A4 placebo` = 0.324, `A4 solanezumab` = 0.340,
              `A4 combined` = 0.329, `Tau: placebo` = 0.515, `Tau: solanezumab` = 0.356, `Tau: A4 combined` = 0.401)
r2_tot <- r2 %>% distinct(analysis, N, total_R2) %>% mutate(paper_R2 = paper_r2[analysis])
top <- r2 %>% group_by(analysis) %>% slice_max(unique_R2, n = 1) %>% select(analysis, top_unique = predictor)
r2_tot <- r2_tot %>% left_join(top, by = "analysis")
cat("\n== Total R2 of PACC change at week 240 (step 2 OLS) and largest unique contributor\n")
print(as.data.frame(r2_tot), digits = 3)
cat("\n== Unique / common R2 per predictor\n")
print(as.data.frame(r2 %>% select(-total_R2, -N) %>%
  mutate(across(c(unique_R2, common_R2), ~ round(.x, 4)), p_unique = signif(p_unique, 2))))
write.csv(r2, "output/main_commonality.csv", row.names = FALSE)
write.csv(r2_tot, "output/main_total_r2.csv", row.names = FALSE)

# =============================================================== injected-error variants
headline <- function(r, tag) {
  r %>% filter(predictor %in% c("Amyloid", "P-tau217", "Neocortical tau")) %>%
    select(analysis, N, total_R2, predictor, unique_R2) %>%
    pivot_wider(names_from = predictor, values_from = unique_R2, names_prefix = "U_") %>%
    mutate(variant = tag, .before = 1)
}
inj <- list(headline(r2, "Correct"))

# M1: reported (censored) ORRES p-tau217 - <LLOQ / >ULOQ samples dropped
inj$M1 <- headline(run_set(dat %>% mutate(PTAU = PTAU_REP)), "M1: censored ORRES p-tau217")

# M2: wrong tau composite - entorhinal only (medial temporal), and white-matter reference
tau_ent <- tau_comp(c("entorhinal_lh_VOI", "entorhinal_rh_VOI"))
tau_wm  <- tau_comp(neo_regions, ref = "suvr_persi")
inj$M2a <- headline(run_set(dat %>% select(-NEO) %>% left_join(tau_ent, by = "BID")), "M2a: entorhinal-only tau")
inj$M2b <- headline(run_set(dat %>% select(-NEO) %>% left_join(tau_wm, by = "BID")), "M2b: neocortical tau, WM ref")

# M3: time window - include A4 open-label and LEARN >week-240 data in step 1
pacc_all <- ADQS %>% filter(QSTESTCD == "PACC", BID %in% base$BID, !is.na(QSSTRESN), !is.na(ADURW),
                            EPOCH != "SCREENING") %>%
  transmute(BID, Y = QSSTRESN, WEEK = pmax(ADURW, 0), QSVERSION = factor(coalesce(QSVERSION, "NA")))
chg_m3 <- step1_change(pacc_all)
inj$M3 <- headline(run_set(base %>% inner_join(chg_m3, by = "BID") %>%
                             mutate(TRT = factor(as.character(GROUP)))), "M3: incl. open-label/extension PACC")

# M4: observed change at week 240 (visit 066, completers) instead of model-based change
obs240 <- pacc_long %>% filter(VISITCD == "066") %>% select(BID, Y240 = Y) %>%
  inner_join(base %>% select(BID, PACC), by = "BID") %>% transmute(BID, CHG240 = Y240 - PACC)
inj$M4 <- headline(run_set(base %>% inner_join(obs240, by = "BID") %>%
                             mutate(TRT = factor(as.character(GROUP)))), "M4: observed wk240 change (completers)")

# M5: ignore treatment arm - one step-1 model for all A4 and no treatment predictor
chg_m5 <- step1_change(pacc_long %>% mutate(dummy = 1), cohort_var = "SUBSTUDY")
dat_m5 <- base %>% inner_join(chg_m5, by = "BID") %>% mutate(TRT = factor("one"))
inj$M5 <- headline(run_set(dat_m5), "M5: arms pooled, no treatment term")

inj_tab <- bind_rows(inj)
cat("\n== Injected-error variants: total R2 and unique R2 of amyloid / p-tau217 / tau\n")
print(as.data.frame(inj_tab %>% mutate(across(where(is.numeric) & !N, ~ round(.x, 3)))))
write.csv(inj_tab, "output/main_injected_errors.csv", row.names = FALSE)

cat("\nRuntime:", round(as.numeric(difftime(Sys.time(), t_start, units = "secs"))), "s\n")
