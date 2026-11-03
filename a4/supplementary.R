# Supplementary checks beyond the A4LEARN "A4 Primary Results" vignette.
# Prints aggregate results only (Ns, model estimates, CIs, p-values).
# Reuses the vignette's spline GLS specification for the secondary endpoints.
suppressPackageStartupMessages({
  library(tidyverse); library(nlme); library(emmeans); library(splines)
  library(clubSandwich); library(A4LEARN)
})
options(width = 120)
mitt <- A4LEARN::SUBJINFO %>% dplyr::filter(MITTFL == 1)

cat("== Population ==\n")
print(table(A4LEARN::SUBJINFO$TX, useNA = "no"))
print(table(mitt$TX))

fit_spline <- function(code, baseline_visit, version = FALSE) {
  d <- A4LEARN::ADQS %>%
    dplyr::filter(MITTFL == 1, QSTESTCD == code) %>%
    dplyr::filter(EPOCH == "BLINDED TREATMENT" | AVISIT == baseline_visit) %>%
    rename(Y = QSSTRESN) %>%
    select(BID, ASEQNCS, TX, ADURW, AGEYR, AAPOEGNPRSNFLG, EDCCNTU, SUVRCER,
      QSVERSION, Y) %>%
    { if (version) . else select(., -QSVERSION) } %>%
    mutate(TX = factor(TX, levels = c("Placebo", "Solanezumab"))) %>%
    na.omit()
  basis <- splines::ns(d$ADURW, df = 2, Boundary.knots = c(0, max(d$ADURW)))
  b1 <- function(t) as.numeric(predict(basis, t)[, 1])
  b2 <- function(t) as.numeric(predict(basis, t)[, 2])
  assign("b1", b1, envir = .GlobalEnv); assign("b2", b2, envir = .GlobalEnv)
  f <- Y ~ I(b1(ADURW)) + I(b2(ADURW)) + (I(b1(ADURW)) + I(b2(ADURW))):TX +
    AGEYR + AAPOEGNPRSNFLG + EDCCNTU + SUVRCER
  if (version) f <- update(f, . ~ . + QSVERSION)
  # Same fallback sequence as the paper (unstructured skipped: vignette reports
  # it does not converge for PACC)
  structs <- list(
    "het. Toeplitz" = list(corARMA(form = ~ ASEQNCS | BID, p = max(d$ASEQNCS) - 1),
      varIdent(form = ~ 1 | ASEQNCS)),
    "het. AR(1)" = list(corAR1(form = ~ ASEQNCS | BID), varIdent(form = ~ 1 | ASEQNCS)),
    "het. CS" = list(corCompSymm(form = ~ 1 | BID), varIdent(form = ~ 1 | ASEQNCS)),
    "CS" = list(corCompSymm(form = ~ 1 | BID), NULL))
  for (s in names(structs)) {
    args <- list(model = f, data = d, correlation = structs[[s]][[1]])
    if (!is.null(structs[[s]][[2]])) args$weights <- structs[[s]][[2]]
    fit <- tryCatch(do.call("gls", args), error = function(e) {
      cat(sprintf("  [%s] %s: %s\n", code, s, conditionMessage(e))); NULL })
    if (!is.null(fit)) break
  }
  rg <- ref_grid(fit, at = list(ADURW = c(0, 240), TX = levels(d$TX)),
    vcov. = as.matrix(clubSandwich::vcovCR(fit, type = "CR2")),
    data = d, mode = "satterthwaite")
  within <- emmeans(rg, ~ ADURW | TX) %>% pairs(reverse = TRUE) %>%
    summary(infer = TRUE)
  rg240 <- ref_grid(fit, at = list(ADURW = 240, TX = levels(d$TX)),
    vcov. = as.matrix(clubSandwich::vcovCR(fit, type = "CR2")),
    data = d, mode = "satterthwaite")
  diff <- emmeans(rg240, ~ TX | ADURW) %>%
    pairs(reverse = TRUE, adjust = "none") %>% summary(infer = TRUE)
  final_n <- d %>% dplyr::filter(ASEQNCS == max(ASEQNCS)) %>% count(TX)
  cat(sprintf("\n== %s (covariance: %s; obs=%d, participants=%d) ==\n",
    code, s, nrow(d), n_distinct(d$BID)))
  cat("Participants with final blinded visit (max ASEQNCS):\n"); print(final_n)
  print(within %>% as_tibble() %>% select(TX, estimate, SE, lower.CL, upper.CL),
    digits = 4)
  print(diff %>% as_tibble() %>%
    select(contrast, estimate, SE, df, lower.CL, upper.CL, p.value), digits = 4)
  # Normal-reference CI for comparison with the Satterthwaite df the vignette uses
  cat(sprintf("diff +/- 1.96*SE: %.3f (%.3f, %.3f)\n", diff$estimate,
    diff$estimate - 1.96 * diff$SE, diff$estimate + 1.96 * diff$SE))
  invisible(fit)
}

fit_spline("PACC", "006", version = TRUE)
fit_spline("CFITOTAL", "001")
fit_spline("ADLPQSP", "001")
fit_spline("CDRSB", "001")

cat("\n== Amyloid PET (Composite_Summary, florbetapir), observed change ==\n")
amy <- A4LEARN::imaging_SUVR_amyloid %>%
  dplyr::filter(brain_region == "Composite_Summary", VISCODE %in% c("2", "66"),
    BID %in% mitt$BID) %>%
  mutate(CL = 183.07 * suvr_cer - 177.26) %>%
  select(BID, VISCODE, CL) %>%
  pivot_wider(names_from = VISCODE, values_from = CL, names_prefix = "V") %>%
  dplyr::filter(!is.na(V2), !is.na(V66)) %>%
  left_join(mitt %>% select(BID, TX), by = "BID") %>%
  mutate(chg = V66 - V2)
amy %>% group_by(TX) %>%
  summarise(n = n(), baseline_CL = mean(V2), week240_CL = mean(V66),
    mean_change = mean(chg), sd_change = sd(chg), .groups = "drop") %>%
  print(digits = 4)
tt <- t.test(chg ~ TX, data = amy)
cat(sprintf("Placebo - Solanezumab change: %.2f (95%% CI %.2f to %.2f), Welch p=%.2g\n",
  tt$estimate[1] - tt$estimate[2], tt$conf.int[1], tt$conf.int[2], tt$p.value))
