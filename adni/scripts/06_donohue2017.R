# Reproduction of Donohue et al., JAMA 2017;317(22):2305-16 (PMC5736301):
# elevated vs normal amyloid in cognitively normal ADNI participants -> 4-year cognitive decline.
# Aggregate output only (counts, means, model estimates). No participant-level rows printed.
suppressPackageStartupMessages({
  library(ADNIMERGE2); library(dplyr); library(tidyr); library(lme4); library(assertr)
})
pdf(NULL)
t_all <- Sys.time()
CUTOFF <- as.Date("2016-06-07") # paper: data collected 2005-08-23 to 2016-06-07
res <- list()
add <- function(section, variant, metric, value) {
  res[[length(res) + 1]] <<- data.frame(section, variant, metric, value = as.character(value))
}

# ---- 1. Candidate cohort: enrolled CN at baseline in ADNI1/GO/2 -------------
base <- ADSL %>%
  filter(ENRLFL %in% "Y", ORIGPROT %in% c("ADNI1", "ADNIGO", "ADNI2"), DX %in% "CN") %>%
  transmute(RID = as.numeric(SUBJID), ORIGPROT, ENRLDT, AGE, EDUC,
            FEMALE = as.integer(SEX == "Female"),
            APOE4 = as.integer(grepl("4", APOE)), APOE_MISSING = is.na(APOE)) %>%
  assert_uniq(RID)

# ---- 2. Amyloid status (paper: FBP SUVR > 1.1, PiB converted 0.15 + 0.67x, CSF AB42 < 192) ----
# Deviation: package has Berkeley 6mm FBP processing (not the 2016 pipeline); primary cutoff is
# that pipeline's own threshold 1.11, 1.10 as sensitivity. Baseline SUVR is the scan closest to
# enrollment (paper interpolated back to baseline with a mixed model).
closest <- function(d, date_col) {
  d %>% inner_join(base %>% select(RID, ENRLDT), by = "RID") %>%
    mutate(gap = abs(as.numeric(.data[[date_col]] - ENRLDT))) %>%
    group_by(RID) %>% slice_min(gap, n = 1, with_ties = FALSE) %>% ungroup()
}
amy_inputs <- function(cutoff) {
  fbp <- UCBERKELEY_AMY_6MM %>%
    filter(TRACER == "FBP") %>%
    transmute(RID = as.numeric(RID), DATE = as.Date(SCANDATE), FBP_SUVR = SUMMARY_SUVR) %>%
    filter(!is.na(FBP_SUVR), DATE <= cutoff) %>% closest("DATE") %>% select(RID, FBP_SUVR)
  pib <- PIBPETSUVR %>%
    transmute(RID = as.numeric(RID), DATE = as.Date(EXAMDATE),
              PIB = rowMeans(cbind(ACG, FRC, LTC, PAR, PRC))) %>%
    filter(!is.na(PIB), DATE <= cutoff) %>% closest("DATE") %>%
    transmute(RID, PIB_FBPEQ = 0.15 + 0.67 * PIB)
  csf <- UPENNBIOMK_MASTER %>%
    filter(BATCH == "MEDIAN") %>%
    transmute(RID = as.numeric(RID), DATE = as.Date(DRAWDTE), ABETA = as.numeric(ABETA)) %>%
    filter(!is.na(ABETA), DATE <= cutoff) %>% closest("DATE") %>% select(RID, ABETA)
  list(fbp = fbp, pib = pib, csf = csf)
}
classify <- function(amy, fbp_thr) {
  base %>%
    left_join(amy$fbp, by = "RID") %>% left_join(amy$pib, by = "RID") %>% left_join(amy$csf, by = "RID") %>%
    mutate(PET = coalesce(FBP_SUVR, PIB_FBPEQ),
           ELEV = (coalesce(FBP_SUVR > fbp_thr, FALSE)) | (coalesce(PIB_FBPEQ > 1.1, FALSE)) |
                  (coalesce(ABETA < 192, FALSE)),
           HAS_AMY = !is.na(PET) | !is.na(ABETA),
           GROUP = factor(ifelse(ELEV, "Elevated", "Normal"), levels = c("Normal", "Elevated")))
}

# ---- 3. PACC (mPACCtrailsB: ADAS Q4, LM DR, MMSE, log Trails B), restandardized to cohort baseline ----
pe <- new.env(); pe$params <- list(INCLUDE_PACC = TRUE)
src <- readLines("rlib-src/ADNIMERGE2/inst/doc/ADNIMERGE2-PACC.R")
src <- src[seq_len(grep("^PACC <- compute_pacc_score", src)[1] - 1)]
invisible(capture.output(eval(parse(text = src), envir = pe)))
wide <- pe$pacc_input_data_wide %>% mutate(RID_N = as.numeric(RID))

pacc_for <- function(rids) {
  bl <- wide %>%
    filter(RID_N %in% rids, ENRLFG %in% "Yes", ORIGPROT == COLPROT,
           VISCODE %in% get_baseline_vistcode()) %>%
    mutate(TRABSCOR = log(TRABSCOR + 1)) %>% assert_uniq(RID)
  bls <- compute_score_summary(.data = bl, wideFormat = TRUE, scoreVar = pe$pacc_component,
                               groupVar = "DX", filterGroup = "CN")
  P <- compute_pacc_score(.data = wide %>% filter(RID_N %in% rids), bl.summary = bls,
                          componentVars = pe$pacc_component_list, rescale_trailsB = TRUE,
                          keepComponents = TRUE, wideFormat = TRUE)
  bdate <- P %>% filter(ORIGPROT == COLPROT, VISCODE %in% get_baseline_vistcode()) %>%
    transmute(RID = as.numeric(RID), BLDATE = as.Date(PACC_VISDATE))
  P %>% transmute(RID = as.numeric(RID), DATE = as.Date(PACC_VISDATE), AVAL = mPACCtrailsB) %>%
    inner_join(bdate, by = "RID") %>%
    mutate(TIME = as.numeric(DATE - BLDATE) / 365.25) %>%
    filter(!is.na(AVAL), !is.na(TIME), TIME >= 0)
}
pkg_pacc_for <- function(rids) { # injected-error variant: package mPACC (all-phase CN standardization)
  P <- ADNIMERGE2::PACC %>% filter(RID %in% rids)
  bdate <- P %>% filter(ORIGPROT == COLPROT, VISCODE %in% get_baseline_vistcode()) %>%
    transmute(RID, BLDATE = as.Date(PACC_VISDATE))
  P %>% transmute(RID, DATE = as.Date(PACC_VISDATE), AVAL = mPACCtrailsB) %>%
    inner_join(bdate, by = "RID") %>%
    mutate(TIME = as.numeric(DATE - BLDATE) / 365.25) %>% filter(!is.na(AVAL), TIME >= 0)
}

# ---- 4. MMSE, CDR-SB, Logical Memory DR from ADQS ---------------------------
qs_for <- function(rids, param) {
  d <- ADQS %>% filter(PARAMCD == param) %>%
    transmute(RID = as.numeric(SUBJID), DATE = as.Date(ADT), ABLFL, AVAL) %>%
    filter(RID %in% rids)
  bdate <- d %>% filter(ABLFL %in% "Y") %>% group_by(RID) %>%
    summarise(BLDATE = min(DATE), .groups = "drop")
  d %>% inner_join(bdate, by = "RID") %>%
    mutate(TIME = as.numeric(DATE - BLDATE) / 365.25) %>%
    filter(!is.na(AVAL), !is.na(TIME), TIME >= 0)
}

# ---- 5. Mixed model: group x time (+ quadratic if AIC prefers), covariates, RI + RS, ML ----
fit_outcome <- function(d, cohort, covs, worse_higher, force = NA) {
  d <- d %>% inner_join(cohort %>% select(RID, GROUP, AGE, EDUC, FEMALE, APOE4), by = "RID") %>%
    filter(if_all(all_of(covs), ~ !is.na(.x)))
  cv <- paste(covs, collapse = " + ")
  ctl <- lmerControl(optimizer = "bobyqa")
  f_lin <- as.formula(paste("AVAL ~ GROUP * TIME +", cv, "+ (TIME | RID)"))
  f_quad <- as.formula(paste("AVAL ~ GROUP * (TIME + I(TIME^2)) +", cv, "+ (TIME | RID)"))
  m_lin <- lmer(f_lin, data = d, REML = FALSE, control = ctl)
  m_quad <- lmer(f_quad, data = d, REML = FALSE, control = ctl)
  quad <- if (is.na(force)) AIC(m_quad) < AIC(m_lin) else force == "quadratic"
  m <- if (quad) m_quad else m_lin
  m0 <- lmer(as.formula(paste("AVAL ~", if (quad) "TIME + I(TIME^2)" else "TIME", "+", cv, "+ (TIME | RID)")),
             data = d, REML = FALSE, control = ctl)
  lrt <- anova(m0, m)
  diff_at <- function(t) {
    fe <- fixef(m); V <- as.matrix(vcov(m)); L <- setNames(rep(0, length(fe)), names(fe))
    L["GROUPElevated"] <- 1; L["GROUPElevated:TIME"] <- t
    if (quad) L["GROUPElevated:I(TIME^2)"] <- t^2
    est <- sum(L * fe); se <- sqrt(drop(t(L) %*% V %*% L))
    s <- if (worse_higher) 1 else -1 # report as "how much worse the elevated group is"
    c(est = s * est, lo = s * est - 1.96 * se, hi = s * est + 1.96 * se, p = 2 * pnorm(-abs(est / se)))
  }
  list(n_obs = nobs(m), n_subj = length(unique(d$RID)), quad = quad,
       d4 = diff_at(4), d2 = diff_at(2),
       chisq = unname(lrt$Chisq[2]), df = unname(lrt$Df[2]), p_lrt = unname(lrt$`Pr(>Chisq)`[2]))
}

run_variant <- function(variant, cutoff = CUTOFF, fbp_thr = 1.11,
                        covs = c("AGE", "EDUC", "FEMALE", "APOE4"), pkg_pacc = FALSE,
                        time_spec = c(PACC = NA, MMSE = NA, CDRSB = NA, LMDR = NA)) {
  cl <- classify(amy_inputs(cutoff), fbp_thr)
  n0 <- nrow(cl); cl <- cl %>% filter(HAS_AMY); n1 <- nrow(cl)
  pacc <- (if (pkg_pacc) pkg_pacc_for(cl$RID) else pacc_for(cl$RID)) %>% filter(DATE <= cutoff)
  fu <- pacc %>% group_by(RID) %>% summarise(FU = max(TIME), .groups = "drop")
  cohort <- cl %>% inner_join(fu, by = "RID") %>% filter(FU > 0)
  add("cohort", variant, "N_CN_ADNI1/GO/2", n0)
  add("cohort", variant, "N_with_amyloid", n1)
  add("cohort", variant, "N_final_with_followup", nrow(cohort))
  add("cohort", variant, "N_normal/elevated", paste(table(cohort$GROUP), collapse = " / "))
  outs <- list(
    PACC = list(d = pacc, worse_higher = FALSE),
    MMSE = list(d = qs_for(cohort$RID, "MMSCORE") %>% filter(DATE <= cutoff), worse_higher = FALSE),
    CDRSB = list(d = qs_for(cohort$RID, "CDRSB") %>% filter(DATE <= cutoff), worse_higher = TRUE),
    LMDR = list(d = qs_for(cohort$RID, "LDELTOTL") %>% filter(DATE <= cutoff), worse_higher = FALSE)
  )
  for (o in names(outs)) {
    r <- fit_outcome(outs[[o]]$d, cohort, covs, outs[[o]]$worse_higher, force = time_spec[[o]])
    add(o, variant, "diff_4y (95% CI), p",
        sprintf("%.2f (%.2f to %.2f), p=%.2g", r$d4["est"], r$d4["lo"], r$d4["hi"], r$d4["p"]))
    add(o, variant, "diff_2y (95% CI), p",
        sprintf("%.2f (%.2f to %.2f), p=%.2g", r$d2["est"], r$d2["lo"], r$d2["hi"], r$d2["p"]))
    add(o, variant, "LRT chisq (df), p", sprintf("%.1f (%d), p=%.2g", r$chisq, r$df, r$p_lrt))
    add(o, variant, "time term (AIC)", if (r$quad) "quadratic" else "linear")
    add(o, variant, "N_obs / N_subj", paste(r$n_obs, "/", r$n_subj))
  }
  invisible(list(cohort = cohort, pacc = pacc))
}

# ---- 6. Primary + variants ---------------------------------------------------
prim <- run_variant("primary")
coh <- prim$cohort
# Table 1 (aggregate)
blp <- prim$pacc %>% filter(TIME == 0) %>% group_by(RID) %>% slice(1) %>% ungroup() %>% # same-date duplicates
  select(RID, BL_PACC = AVAL)
blq <- function(p) qs_for(coh$RID, p) %>% filter(ABLFL %in% "Y") %>% group_by(RID) %>% slice(1) %>% ungroup() %>% select(RID, AVAL)
t1 <- coh %>% left_join(blp, by = "RID") %>%
  left_join(blq("MMSCORE") %>% rename(MMSE = AVAL), by = "RID") %>%
  left_join(blq("LDELTOTL") %>% rename(LMDR = AVAL), by = "RID") %>%
  left_join(blq("ADASTT13") %>% rename(ADAS13 = AVAL), by = "RID")
msd <- function(x) sprintf("%.2f (%.2f)", mean(x, na.rm = TRUE), sd(x, na.rm = TRUE))
for (g in c("Normal", "Elevated", "Overall")) {
  s <- if (g == "Overall") t1 else t1 %>% filter(GROUP == g)
  add("table1", g, "N", nrow(s))
  add("table1", g, "Age", msd(s$AGE))
  add("table1", g, "Women n (%)", sprintf("%d (%.0f%%)", sum(s$FEMALE), 100 * mean(s$FEMALE)))
  add("table1", g, "Education", msd(s$EDUC))
  add("table1", g, ">=1 APOE4 n (%)", sprintf("%d (%.0f%%)", sum(s$APOE4[!s$APOE_MISSING]), 100 * mean(s$APOE4[!s$APOE_MISSING])))
  add("table1", g, "Baseline PACC", msd(s$BL_PACC))
  add("table1", g, "Baseline MMSE", msd(s$MMSE))
  add("table1", g, "Baseline LM DR", msd(s$LMDR))
  add("table1", g, "Baseline ADAS13", msd(s$ADAS13))
  add("table1", g, "Follow-up years (PACC)", msd(s$FU))
  add("table1", g, "Follow-up median (IQR)", sprintf("%.1f (%.1f-%.1f)", median(s$FU), quantile(s$FU, .25), quantile(s$FU, .75)))
  add("table1", g, "PET available", sum(!is.na(s$PET)))
  add("table1", g, "CSF available", sum(!is.na(s$ABETA)))
  add("table1", g, "Amyloid source: PET only / CSF only / both",
      sprintf("%d / %d / %d", sum(!is.na(s$PET) & is.na(s$ABETA)), sum(is.na(s$PET) & !is.na(s$ABETA)), sum(!is.na(s$PET) & !is.na(s$ABETA))))
}
add("table1", "Overall", "Cohort by phase", paste(names(table(coh$ORIGPROT)), table(coh$ORIGPROT), collapse = ", "))

# Paper's LRT df imply linear time for PACC/MMSE/LM (chi2 df 2) and quadratic for CDR-SB (df 3)
run_variant("paper_time_terms", time_spec = c(PACC = "linear", MMSE = "linear", CDRSB = "quadratic", LMDR = "linear"))
run_variant("FBP_cutoff_1.10", fbp_thr = 1.10)
run_variant("age_only_covariate", covs = "AGE")
run_variant("package_mPACC_std_all_phase_CN", pkg_pacc = TRUE)
run_variant("full_current_data_2026-10-05", cutoff = as.Date("2026-10-05"))

out <- do.call(rbind, res)
write.csv(out, "output/donohue2017_results.csv", row.names = FALSE)
print(out, row.names = FALSE, right = FALSE)
cat("Total runtime:", round(as.numeric(difftime(Sys.time(), t_all, units = "secs")), 1), "s\n")
