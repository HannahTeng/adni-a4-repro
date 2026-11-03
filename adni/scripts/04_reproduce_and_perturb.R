# Independent reproduction of 3 vignette analyses + sensitivity to plausible analyst mistakes.
# Aggregate output only (counts, means, model estimates). No participant-level rows printed.
suppressPackageStartupMessages({
  library(ADNIMERGE2); library(dplyr); library(tidyr); library(lme4); library(assertr)
})
pdf(NULL)
res <- list()
add <- function(target, variant, metric, value) {
  res[[length(res) + 1]] <<- data.frame(target, variant, metric, value = as.character(value))
}
t_all <- Sys.time()

# ---- A. Enrollment -------------------------------------------------------
t0 <- Sys.time()
enr <- ADSL %>% filter(ENRLFL %in% "Y")
for (p in names(table(enr$ORIGPROT))) add("A_enrollment", "correct", paste0("N_", p), sum(enr$ORIGPROT == p))
add("A_enrollment", "correct", "N_total", nrow(enr))
for (d in c("CN", "MCI", "DEM")) add("A_enrollment", "correct", paste0("N_", d), sum(enr$DX %in% d))
add("A_enrollment", "correct", "N_with_DX", sum(!is.na(enr$DX)))
add("A_enrollment", "correct", "Age_mean_sd", sprintf("%.1f (%.1f)", mean(enr$AGE, na.rm = TRUE), sd(enr$AGE, na.rm = TRUE)))
# Mistake: no enrollment filter (screen failures kept)
add("A_enrollment", "no_ENRLFL_filter", "N_total", nrow(ADSL))
add("A_enrollment", "no_ENRLFL_filter", "N_ADNI1", sum(ADSL$ORIGPROT == "ADNI1"))
add("A_enrollment", "no_ENRLFL_filter", "Age_mean_sd", sprintf("%.1f (%.1f)", mean(ADSL$AGE, na.rm = TRUE), sd(ADSL$AGE, na.rm = TRUE)))
# Mistake: drop the TEAM phase (task listed only ADNI1/GO/2/3/4)
add("A_enrollment", "phases_ADNI1-4_only", "N_total", sum(enr$ORIGPROT != "TEAM"))
add("A_enrollment", "_runtime", "seconds", round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1))

# ---- B. Longitudinal ADAS-Cog13 LMM -------------------------------------
t0 <- Sys.time()
prep <- function(enrolled_only = TRUE, time = c("visit", "actual")) {
  time <- match.arg(time)
  d <- ADQS %>% filter(PARAMCD %in% "ADASTT13")
  if (enrolled_only) d <- d %>% filter(ENRLFL %in% "Y")
  d %>%
    mutate(TIME = if (time == "visit") convert_number_days(AVISITN, unit = "year") else ADY / 365.25,
           DX = factor(DX, levels = levels(ADSL$DX))) %>%
    filter(!if_any(all_of(c("TIME", "DX", "AVAL")), ~ is.na(.x)))
}
fit_lmm <- function(d, spline = TRUE, slope = TRUE) {
  basis <- splines::ns(d$TIME, df = 2, Boundary.knots = c(0, max(d$TIME)))
  b1 <- function(t) as.numeric(predict(basis, t)[, 1])
  b2 <- function(t) as.numeric(predict(basis, t)[, 2])
  environment(b1)$basis <- basis; environment(b2)$basis <- basis
  assign("b1", b1, envir = .GlobalEnv); assign("b2", b2, envir = .GlobalEnv)
  re <- if (slope) "(TIME | USUBJID)" else "(1 | USUBJID)"
  fx <- if (spline) "(I(b1(TIME)) + I(b2(TIME))) * DX" else "TIME * DX"
  lmer(as.formula(paste("AVAL ~", fx, "+", re)), data = d,
       control = lmerControl(optimizer = "Nelder_Mead"))
}
summ_lmm <- function(variant, m, d) {
  add("B_longitudinal", variant, "N_obs", nobs(m))
  add("B_longitudinal", variant, "N_subj", length(unique(d$USUBJID)))
  add("B_longitudinal", variant, "REML", sprintf("%.2f", REMLcrit(m)))
  fe <- fixef(m)
  for (k in c("(Intercept)", "DXMCI", "DXDEM")) add("B_longitudinal", variant, paste0("b_", k), sprintf("%.2f", fe[[k]]))
  nd <- expand_grid(TIME = c(0, 2), DX = factor(c("CN", "MCI", "DEM"), levels = levels(d$DX)))
  nd$pred <- predict(m, newdata = nd, re.form = NA)
  for (g in c("CN", "MCI", "DEM")) {
    p <- nd$pred[nd$DX == g]
    add("B_longitudinal", variant, paste0("chg2y_", g), sprintf("%.2f", p[2] - p[1]))
  }
}
d0 <- prep(); m0 <- fit_lmm(d0); summ_lmm("correct", m0, d0)
for (k in names(fixef(m0))) add("B_longitudinal", "correct", paste0("fe_", k), sprintf("%.2f", fixef(m0)[[k]]))
d1 <- prep(enrolled_only = FALSE); summ_lmm("no_ENRLFL_filter", fit_lmm(d1), d1)
summ_lmm("linear_time", fit_lmm(d0, spline = FALSE), d0)
summ_lmm("random_intercept_only", fit_lmm(d0, slope = FALSE), d0)
d4 <- prep(time = "actual"); summ_lmm("actual_days_time_ADY", fit_lmm(d4), d4)
add("B_longitudinal", "_runtime", "seconds", round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1))

# ---- C. PACC standardization + baseline mPACC ---------------------------
t0 <- Sys.time()
pe <- new.env()
pe$params <- list(INCLUDE_PACC = TRUE)
src <- readLines("rlib-src/ADNIMERGE2/inst/doc/ADNIMERGE2-PACC.R")
src <- src[seq_len(grep("^PACC <- compute_pacc_score", src)[1] - 1)] # stop before scoring
invisible(capture.output(eval(parse(text = src), envir = pe)))
wide <- pe$pacc_input_data_wide; comps <- pe$pacc_component

bl_pop <- function(log_trails = TRUE, baseline_only = TRUE, all_dx = FALSE) {
  d <- wide
  if (log_trails) d <- d %>% mutate(TRABSCOR = log(TRABSCOR + 1))
  d <- d %>% filter(ENRLFG %in% "Yes") %>% filter(ORIGPROT == COLPROT)
  if (baseline_only) d <- d %>% filter(VISCODE %in% get_baseline_vistcode())
  if (all_dx) d <- d %>% filter(!is.na(DX)) %>% mutate(DX = "CN")
  compute_score_summary(.data = d, wideFormat = TRUE, scoreVar = comps, groupVar = "DX", filterGroup = "CN")
}
score <- function(bls, rescale = TRUE) {
  compute_pacc_score(.data = wide, bl.summary = bls, componentVars = pe$pacc_component_list,
                     rescale_trailsB = rescale, keepComponents = TRUE, wideFormat = TRUE)
}
bl_scores <- function(variant, P) {
  b <- P %>% filter(ORIGPROT == COLPROT, VISCODE %in% get_baseline_vistcode(), ENRLFG %in% "Yes")
  for (g in c("CN", "MCI", "Dementia")) { # PACC uses "Dementia", ADSL uses "DEM"
    x <- b$mPACCtrailsB[b$DX %in% g]
    add("C_PACC", variant, paste0("bl_mPACCtrailsB_", g), sprintf("n=%d mean=%.2f sd=%.2f", sum(!is.na(x)), mean(x, na.rm = TRUE), sd(x, na.rm = TRUE)))
  }
}
s0 <- bl_pop()
for (i in seq_len(nrow(s0))) add("C_PACC", "correct", paste0("std_", s0$VAR[i]), sprintf("N=%d mean=%.4f sd=%.6f", s0$N[i], s0$MEAN[i], s0$SD[i]))
P0 <- score(s0); bl_scores("correct", P0)
# Check vs packaged PACC dataset
chk <- P0 %>% mutate(RID = as.numeric(RID)) %>%
  select(RID, VISCODE, mPACCtrailsB) %>%
  inner_join(ADNIMERGE2::PACC %>% select(RID, VISCODE, pk = mPACCtrailsB), by = c("RID", "VISCODE"))
add("C_PACC", "correct", "rows_matched_vs_package_PACC", nrow(chk))
add("C_PACC", "correct", "max_abs_diff_vs_package_PACC", signif(max(abs(chk$mPACCtrailsB - chk$pk), na.rm = TRUE), 3))
bl_scores("std_pop_all_DX", score(bl_pop(all_dx = TRUE)))
bl_scores("std_pop_all_visits", score(bl_pop(baseline_only = FALSE)))
bl_scores("no_log_TrailsB", score(bl_pop(log_trails = FALSE), rescale = FALSE))
add("C_PACC", "_runtime", "seconds", round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1))

out <- do.call(rbind, res)
write.csv(out, "output/reproduction_results.csv", row.names = FALSE)
print(out, row.names = FALSE, right = FALSE)
cat("Total runtime:", round(as.numeric(difftime(Sys.time(), t_all, units = "secs")), 1), "s\n")
