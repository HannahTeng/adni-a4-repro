# Donohue et al., JAMA 2017 -- reproduction following the Supplement's exact model specs
# (eTables 2-4 imputation models, eTables 8-11 outcome models). Aggregate output only.
suppressPackageStartupMessages({
  library(ADNIMERGE2); library(dplyr); library(tidyr); library(lme4); library(nlme); library(assertr)
})
pdf(NULL)
t_all <- Sys.time()
CUTOFF <- as.Date("2016-06-07")
BL_WINDOW <- 182 # days: a measure within +/- 6 months of enrollment counts as a baseline observation
res <- list()
add <- function(section, variant, metric, value) {
  res[[length(res) + 1]] <<- data.frame(section, variant, metric, value = as.character(value))
}

# ---- Cohort base: enrolled CN in ADNI1/GO/2 -----------------------------------
base <- ADSL %>%
  filter(ENRLFL %in% "Y", ORIGPROT %in% c("ADNI1", "ADNIGO", "ADNI2"), DX %in% "CN") %>%
  transmute(RID = as.numeric(SUBJID), ORIGPROT, ENRLDT, AGE, EDUC,
            FEMALE = as.integer(SEX == "Female"), APOE4 = as.integer(grepl("4", APOE))) %>%
  assert_uniq(RID)

# Family history: mother/father with AD (FHQ) or any sibling with AD (RECFHQ). Gives 37.5% in the
# candidate cohort vs paper's 39%; the broader "any dementia" (FHQMOM/FHQDAD) definition gives ~52%.
fh <- bind_rows(
  FHQ %>% transmute(RID = as.numeric(RID), y = FHQMOMAD %in% "Yes" | FHQDADAD %in% "Yes"),
  RECFHQ %>% transmute(RID = as.numeric(RID), y = FHQSIBAD %in% "Yes")
) %>% group_by(RID) %>% summarise(FAMHIST = as.integer(any(y)), .groups = "drop")
base <- base %>% left_join(fh, by = "RID")

# ---- PACC (cohort-restandardized mPACCtrailsB), as in 06 -----------------------
pe <- new.env(); pe$params <- list(INCLUDE_PACC = TRUE)
src <- readLines("rlib-src/ADNIMERGE2/inst/doc/ADNIMERGE2-PACC.R")
src <- src[seq_len(grep("^PACC <- compute_pacc_score", src)[1] - 1)]
invisible(capture.output(eval(parse(text = src), envir = pe)))
wide <- pe$pacc_input_data_wide %>% mutate(RID_N = as.numeric(RID))
pacc_for <- function(rids) {
  bl <- wide %>%
    filter(RID_N %in% rids, ENRLFG %in% "Yes", ORIGPROT == COLPROT, VISCODE %in% get_baseline_vistcode()) %>%
    mutate(TRABSCOR = log(TRABSCOR + 1)) %>% assert_uniq(RID)
  bls <- compute_score_summary(.data = bl, wideFormat = TRUE, scoreVar = pe$pacc_component,
                               groupVar = "DX", filterGroup = "CN")
  P <- compute_pacc_score(.data = wide %>% filter(RID_N %in% rids), bl.summary = bls,
                          componentVars = pe$pacc_component_list, rescale_trailsB = TRUE,
                          keepComponents = TRUE, wideFormat = TRUE)
  bdate <- P %>% filter(ORIGPROT == COLPROT, VISCODE %in% get_baseline_vistcode()) %>%
    transmute(RID = as.numeric(RID), BLDATE = as.Date(PACC_VISDATE))
  P %>% transmute(RID = as.numeric(RID), DATE = as.Date(PACC_VISDATE), AVAL = mPACCtrailsB) %>%
    inner_join(bdate, by = "RID") %>% mutate(TIME = as.numeric(DATE - BLDATE) / 365.25) %>%
    filter(!is.na(AVAL), !is.na(TIME), TIME >= 0)
}
qs_for <- function(rids, param) {
  d <- ADQS %>% filter(PARAMCD == param) %>%
    transmute(RID = as.numeric(SUBJID), DATE = as.Date(ADT), ABLFL, AVAL) %>% filter(RID %in% rids)
  bdate <- d %>% filter(ABLFL %in% "Y") %>% group_by(RID) %>% summarise(BLDATE = min(DATE), .groups = "drop")
  d %>% inner_join(bdate, by = "RID") %>% mutate(TIME = as.numeric(DATE - BLDATE) / 365.25) %>%
    filter(!is.na(AVAL), !is.na(TIME), TIME >= 0)
}

pacc_all <- pacc_for(base$RID) %>% filter(DATE <= CUTOFF)
bl_pacc <- pacc_all %>% filter(TIME == 0) %>% group_by(RID) %>% slice(1) %>% ungroup() %>%
  select(RID, BL_PACC = AVAL)
base <- base %>% left_join(bl_pacc, by = "RID")

# ---- Baseline imputation helper (eTables 2-4) ----------------------------------
# Long measures -> years from enrollment. Baseline obs = within +/- BL_WINDOW days.
# Otherwise impute: LMM y ~ YEARS + AGE + APOE4 + BL_PACC + RE, predicted at YEARS = 0 with BLUPs.
impute_baseline <- function(long, slope = FALSE, impute = TRUE) {
  d <- long %>% inner_join(base %>% select(RID, ENRLDT, AGE, APOE4, BL_PACC), by = "RID") %>%
    mutate(GAP = as.numeric(DATE - ENRLDT), YEARS = GAP / 365.25)
  obs <- d %>% filter(abs(GAP) <= BL_WINDOW) %>% group_by(RID) %>%
    slice_min(abs(GAP), n = 1, with_ties = FALSE) %>% ungroup() %>% transmute(RID, BL = Y, IMPUTED = FALSE)
  if (!impute) {
    near <- d %>% group_by(RID) %>% slice_min(abs(GAP), n = 1, with_ties = FALSE) %>% ungroup() %>%
      transmute(RID, BL = Y, IMPUTED = !(RID %in% obs$RID))
    return(near)
  }
  fitd <- d %>% filter(!is.na(AGE), !is.na(APOE4), !is.na(BL_PACC))
  re <- if (slope) "(YEARS | RID)" else "(1 | RID)"
  m <- lmer(as.formula(paste("Y ~ YEARS + AGE + APOE4 + BL_PACC +", re)), data = fitd, REML = TRUE)
  need <- fitd %>% filter(!(RID %in% obs$RID)) %>% distinct(RID, AGE, APOE4, BL_PACC) %>% mutate(YEARS = 0)
  imp <- need %>% mutate(BL = predict(m, newdata = need, allow.new.levels = TRUE), IMPUTED = TRUE) %>%
    select(RID, BL, IMPUTED)
  bind_rows(obs, imp)
}

fbp_long <- UCBERKELEY_AMY_6MM %>% filter(TRACER == "FBP") %>%
  transmute(RID = as.numeric(RID), DATE = as.Date(SCANDATE), Y = SUMMARY_SUVR) %>%
  filter(!is.na(Y), DATE <= CUTOFF, RID %in% base$RID)
pib_long <- PIBPETSUVR %>%
  transmute(RID = as.numeric(RID), DATE = as.Date(EXAMDATE), Y = rowMeans(cbind(ACG, FRC, LTC, PAR, PRC))) %>%
  filter(!is.na(Y), DATE <= CUTOFF, RID %in% base$RID)
csf_bl <- UPENNBIOMK_MASTER %>% filter(BATCH == "MEDIAN") %>%
  transmute(RID = as.numeric(RID), DATE = as.Date(DRAWDTE), ABETA = as.numeric(ABETA)) %>%
  filter(!is.na(ABETA), DATE <= CUTOFF) %>%
  inner_join(base %>% select(RID, ENRLDT), by = "RID") %>% group_by(RID) %>%
  slice_min(abs(as.numeric(DATE - ENRLDT)), n = 1, with_ties = FALSE) %>% ungroup() %>% select(RID, ABETA)

# Ventricular volume %ICV: classic ADNIMERGE definition from UCSF FreeSurfer
vent_long <- bind_rows(UCSFFSX %>% mutate(SRC = "FS4.3"), UCSFFSX51 %>% mutate(SRC = "FS5.1")) %>%
  filter(OVERALLQC %in% c("Pass", "Partial")) %>%
  transmute(RID = as.numeric(RID), DATE = as.Date(EXAMDATE),
            Y = 100 * (ST30SV + ST37SV + ST89SV + ST96SV) / ST10CV) %>%
  filter(!is.na(Y), DATE <= CUTOFF, RID %in% base$RID) %>% distinct(RID, DATE, .keep_all = TRUE)

build_cohort <- function(fbp_thr = 1.10, impute = TRUE) {
  fbp <- impute_baseline(fbp_long, impute = impute) %>% rename(FBP_BL = BL, FBP_IMP = IMPUTED)
  pib <- impute_baseline(pib_long, impute = impute) %>% transmute(RID, PIB_FBPEQ = 0.15 + 0.67 * BL, PIB_IMP = IMPUTED)
  vent <- impute_baseline(vent_long, slope = TRUE, impute = impute) %>% rename(VENT = BL, VENT_IMP = IMPUTED)
  base %>% left_join(fbp, by = "RID") %>% left_join(pib, by = "RID") %>%
    left_join(csf_bl, by = "RID") %>% left_join(vent, by = "RID") %>%
    mutate(ELEV = coalesce(FBP_BL > fbp_thr, FALSE) | coalesce(PIB_FBPEQ > 1.1, FALSE) | coalesce(ABETA < 192, FALSE),
           HAS_AMY = !is.na(FBP_BL) | !is.na(PIB_FBPEQ) | !is.na(ABETA),
           GROUP = factor(ifelse(ELEV, "Elevated", "Normal"), levels = c("Normal", "Elevated"))) %>%
    filter(HAS_AMY, !is.na(BL_PACC))
}

# ---- Outcome models per eTables 8-11 -------------------------------------------
SPEC <- list(
  PACC  = list(covs = c("APOE4", "AGE", "FEMALE", "EDUC", "VENT", "FAMHIST"), worse_higher = FALSE, cs = FALSE),
  MMSE  = list(covs = c("AGE", "FEMALE", "EDUC"), worse_higher = FALSE, cs = FALSE),
  CDRSB = list(covs = c("AGE"), worse_higher = TRUE, cs = TRUE),
  LMDR  = list(covs = c("APOE4", "AGE", "FEMALE", "EDUC", "VENT"), worse_higher = FALSE, cs = FALSE)
)
SCHED <- c(0, 6, 12, 24, 36, 48, 60, 72, 84, 96, 108, 120)
fit_spec <- function(d, cohort, spec) {
  d <- d %>% inner_join(cohort %>% select(RID, GROUP, all_of(unique(unlist(lapply(SPEC, `[[`, "covs"))))), by = "RID") %>%
    filter(if_all(all_of(spec$covs), ~ !is.na(.x))) %>%
    mutate(MONTH = factor(sapply(TIME * 12, function(m) SCHED[which.min(abs(SCHED - m))])))
  f <- as.formula(paste("AVAL ~ GROUP * (TIME + I(TIME^2)) +", paste(spec$covs, collapse = " + ")))
  if (spec$cs) {
    m <- gls(f, data = d, correlation = corCompSymm(form = ~ 1 | RID),
             weights = varIdent(form = ~ 1 | MONTH), method = "ML", control = glsControl(msMaxIter = 200))
    fe <- coef(m); V <- vcov(m)
    extra <- sprintf("rho=%.2f", coef(m$modelStruct$corStruct, unconstrained = FALSE))
  } else {
    m <- lmer(as.formula(paste(deparse(f, width.cutoff = 500), "+ (TIME | RID)")), data = d, REML = FALSE,
              control = lmerControl(optimizer = "bobyqa"))
    fe <- fixef(m); V <- as.matrix(vcov(m))
    vc <- as.data.frame(VarCorr(m))
    extra <- sprintf("RE SD int=%.2f slope=%.2f corr=%.2f resid=%.2f", vc$sdcor[1], vc$sdcor[2], vc$sdcor[3], vc$sdcor[4])
  }
  con <- function(t) {
    L <- setNames(rep(0, length(fe)), names(fe))
    L["GROUPElevated"] <- 1; L["GROUPElevated:TIME"] <- t; L["GROUPElevated:I(TIME^2)"] <- t^2
    est <- sum(L * fe); se <- sqrt(drop(t(L) %*% V %*% L))
    c(est = est, lo = est - 1.96 * se, hi = est + 1.96 * se, p = 2 * pnorm(-abs(est / se)))
  }
  covfx <- paste(sprintf("%s=%.2f", spec$covs, fe[spec$covs]), collapse = " ")
  list(con = con, n_obs = nrow(d), n_subj = length(unique(d$RID)), aic = AIC(m), extra = extra, covfx = covfx)
}

run_spec <- function(variant, fbp_thr = 1.10, impute = TRUE, require_fu = FALSE) {
  coh <- build_cohort(fbp_thr, impute)
  if (require_fu) {
    fu <- pacc_all %>% group_by(RID) %>% summarise(FU = max(TIME), .groups = "drop")
    coh <- coh %>% inner_join(fu, by = "RID") %>% filter(FU > 0)
  }
  add("cohort", variant, "N (normal / elevated)", sprintf("%d (%d / %d)", nrow(coh), sum(coh$GROUP == "Normal"), sum(coh$GROUP == "Elevated")))
  add("cohort", variant, "FBP imputed (normal / elevated)",
      sprintf("%d / %d", sum(coh$FBP_IMP & coh$GROUP == "Normal", na.rm = TRUE), sum(coh$FBP_IMP & coh$GROUP == "Elevated", na.rm = TRUE)))
  add("cohort", variant, "PiB imputed (normal / elevated)",
      sprintf("%d / %d", sum(coh$PIB_IMP & coh$GROUP == "Normal", na.rm = TRUE), sum(coh$PIB_IMP & coh$GROUP == "Elevated", na.rm = TRUE)))
  add("cohort", variant, "Family history n (%)", sprintf("%d (%.0f%%)", sum(coh$FAMHIST, na.rm = TRUE), 100 * mean(coh$FAMHIST, na.rm = TRUE)))
  add("cohort", variant, "Ventricles %ICV mean (SD), normal / elevated",
      sprintf("%.2f (%.2f) / %.2f (%.2f)", mean(coh$VENT[coh$GROUP == "Normal"], na.rm = TRUE), sd(coh$VENT[coh$GROUP == "Normal"], na.rm = TRUE),
              mean(coh$VENT[coh$GROUP == "Elevated"], na.rm = TRUE), sd(coh$VENT[coh$GROUP == "Elevated"], na.rm = TRUE)))
  outs <- list(PACC = pacc_all, MMSE = qs_for(coh$RID, "MMSCORE"), CDRSB = qs_for(coh$RID, "CDRSB"),
               LMDR = qs_for(coh$RID, "LDELTOTL"))
  for (o in names(SPEC)) {
    r <- fit_spec(outs[[o]] %>% filter(DATE <= CUTOFF), coh, SPEC[[o]])
    for (t in c(0, 2, 4, 10)) {
      x <- r$con(t)
      add(o, variant, sprintf("contrast y%d (elev - normal)", t), sprintf("%.2f (%.2f to %.2f), p=%.2g", x["est"], x["lo"], x["hi"], x["p"]))
    }
    add(o, variant, "N_obs / N_subj", paste(r$n_obs, "/", r$n_subj))
    add(o, variant, "AIC", round(r$aic))
    add(o, variant, "variance structure", r$extra)
    add(o, variant, "covariate coefs", r$covfx)
  }
}

run_spec("supplement_spec")
run_spec("spec_FBP_1.11", fbp_thr = 1.11)
run_spec("spec_no_imputation_closest_scan", impute = FALSE)
run_spec("spec_require_followup", require_fu = TRUE)

out <- do.call(rbind, res)
write.csv(out, "output/donohue2017_spec_results.csv", row.names = FALSE)
print(out, row.names = FALSE, right = FALSE)
cat("Total runtime:", round(as.numeric(difftime(Sys.time(), t_all, units = "secs")), 1), "s\n")
