# Reproduction of Grill et al. 2020 JAMA Neurol 77(12):1504-1513 (PMC7418046)
# "Short-term psychological outcomes of disclosing amyloid imaging results ..."
# Uses the A4LEARN R data package. Prints and writes AGGREGATE results only.
# Run: cd papers/grill2020_disclosure && Rscript reproduce.R

suppressPackageStartupMessages({
  library(A4LEARN); library(dplyr); library(tidyr)
})
options(width = 140, dplyr.summarise.inform = FALSE)
dir.create("output", showWarnings = FALSE)
t_start <- Sys.time()

cat("A4LEARN version:", as.character(packageVersion("A4LEARN")),
    "| data download:", as.character(A4LEARN::data_download_date), "\n\n")

yn <- function(x) !is.na(x) & x == 1

# ---------------------------------------------------------------- scoring ----
# C-SSRS ordinal "highest level" score 0-9: ideation 1-5 (wish, non-specific,
# method, intent, plan), behaviour 6-9 (preparatory, aborted, interrupted, attempt).
cssrs_score <- function(wish, act, meth, intent, plan, prep, abort, inter, att)
  pmax(1 * yn(wish), 2 * yn(act), 3 * yn(meth), 4 * yn(intent), 5 * yn(plan),
       6 * yn(prep), 7 * yn(abort), 8 * yn(inter), 9 * yn(att))

ftp_items <- c("FTOPPS", "FTGOAL", "FTPOSSBL", "FTLIFE", "FTINFINIT", "FTANYTHNG",
               "FTNEW", "FTRUNOUT", "FTLIMIT", "FTGETOLD")
ftp_rev   <- c("FTRUNOUT", "FTLIMIT", "FTGETOLD")
cad_items <- c("CADDVLP", "CADDVLP5", "CADKNOW", "CADBLIEV", "CADWRST", "CADCNCRN")
ies_items <- c("IETHINK", "IEAVOID", "IEREMOVE", "IESLEEP", "IEWAVES", "IEDREAMS", "IEAWAY",
               "IEREAL", "IETALK", "IEMIND", "IETHINGS", "IEDEAL", "IENOTTHNK", "IEREMIND", "IENUMB")

# ------------------------------------------------------ build analysis data ----
# opts allow deliberately injected analyst errors (see REPORT.md)
default_opts <- list(
  post_visit_a4 = 6, post_visit_learn = 6,  # post-disclosure GDS/STAI/C-SSRS visit
  cssrs_base = "3m5y",                      # baseline C-SSRS window: "3m5y" or "lifetime"
  ftp_reverse = TRUE,                       # reverse-score FTP items 8-10
  comparator = "LEARN",                     # "LEARN" or "all_negative" (screen-fails too)
  drop_rescreens = TRUE,
  ies_recode = FALSE                        # wrongly recode IES 0/1/3/5 -> 0/1/2/3
)

build_data <- function(o = default_opts) {
  resc <- SUBJINFO %>% filter(!is.na(PREVBID)) %>% select(BID1 = PREVBID, BID2 = BID)
  pet <- imaging_PET_VA %>% filter(VISCODE == 2)
  if (o$drop_rescreens) pet <- pet %>% left_join(resc, by = c("BID" = "BID1")) %>%
    mutate(BID = coalesce(BID2, BID)) %>% filter(!duplicated(BID, fromLast = TRUE))
  pet <- pet %>% select(BID, overall_score)

  subj <- SUBJINFO %>% select(BID, SUBSTUDY, APOEGN)
  if (o$drop_rescreens) subj <- subj %>% filter(!BID %in% resc$BID1)
  subj <- subj %>% left_join(pet, by = "BID")

  demo <- ptdemog %>% transmute(BID, age = PTAGE, male = PTGENDER == "Male",
    white = PTRACE == "5", white_any = grepl("5", PTRACE),
    latino = PTETHNIC == "Hispanic or Latino", educ = PTEDUCAT)

  fh_par <- famhxpar %>% filter(VISCODE == 1) %>%
    transmute(BID, fh_dem_p = yn(MOTHER) | yn(FATHER), fh_ad_p = yn(MOTHDIAG) | yn(FATHDIAG))
  fh_sib <- famhxsib %>% filter(VISCODE == 1) %>% group_by(BID) %>%
    summarise(fh_dem_s = any(yn(SIBDEMENT)), fh_ad_s = any(yn(SIBDIAG)))
  cfi_pt <- cfi %>% filter(VISCODE == 1) %>% select(BID, cfi_pt = CFIPTTOTAL)
  cfi_sp <- cfisp %>% filter(VISCODE == 1) %>% select(BID, cfi_sp = CFSPTTOTAL)

  pw <- psychwell %>% select(BID, SUBSTUDY, VISCODE, GDTOTAL, STAITOTAL)
  pw1 <- pw %>% filter(VISCODE == 1) %>% select(BID, gds_pre = GDTOTAL, stai_pre = STAITOTAL)
  pw6 <- pw %>% filter((SUBSTUDY != "LEARN" & VISCODE == o$post_visit_a4) |
                       (SUBSTUDY == "LEARN" & VISCODE == o$post_visit_learn)) %>%
    select(BID, gds_post = GDTOTAL, stai_post = STAITOTAL)

  cs1 <- cssrs %>% filter(VISCODE == 1)
  cs1 <- if (o$cssrs_base == "lifetime") {
    cs1 %>% transmute(BID, cssrs_pre = cssrs_score(WISHLIFE, ACTLIFE, METHOD, INTENT, PLAN,
                                                   PREP, ABORT, INTER, ATTMPT))
  } else {
    cs1 %>% transmute(BID, cssrs_pre = cssrs_score(WISH3, ACT3, METHOD3, INTENT3, PLAN3,
                                                   PREP5, ABORT5, INTER5, ATTMPT5))
  }
  cs6 <- cssrslv %>% filter(DONE == 1, (SUBSTUDY != "LEARN" & VISCODE == o$post_visit_a4) |
                             (SUBSTUDY == "LEARN" & VISCODE == o$post_visit_learn)) %>%
    transmute(BID, cssrs_post = cssrs_score(WISHLV, ACTLV, METHODLV, INTENTLV, PLANLV,
                                            PREPLV, ABORTLV, INTERLV, ATTMPTLV))

  ftp <- ftpscale %>% filter(DONE == 1, VISCODE %in% c(1, 3))
  if (o$ftp_reverse) ftp <- ftp %>% mutate(across(all_of(ftp_rev), ~ 8 - .x))
  ftp <- ftp %>% mutate(ftp = rowSums(across(all_of(ftp_items)))) %>%
    select(BID, VISCODE, ftp) %>% pivot_wider(names_from = VISCODE, values_from = ftp,
                                              names_prefix = "ftp_v")
  cad <- concerns %>% filter(DONE == 1, VISCODE %in% c(1, 3)) %>%
    mutate(cad = rowSums(across(all_of(cad_items)))) %>%
    select(BID, VISCODE, cad) %>% pivot_wider(names_from = VISCODE, values_from = cad,
                                              names_prefix = "cad_v")
  iesd <- ies %>% filter(DONE == 1, VISCODE == 3)
  if (o$ies_recode) iesd <- iesd %>% mutate(across(all_of(ies_items),
                                                   ~ c(0, 1, NA, 2, NA, 3)[.x + 1]))
  iesd <- iesd %>% transmute(BID, ies = if (o$ies_recode) rowSums(across(all_of(ies_items)))
                             else IESCORE)

  sv <- SV %>% filter(VISITCD %in% c("003", "006")) %>%
    select(BID, VISITCD, day = SVSTDTC_DAYS_CONSENT) %>%
    group_by(BID, VISITCD) %>% summarise(day = suppressWarnings(min(day, na.rm = TRUE))) %>%
    mutate(day = ifelse(is.finite(day), day, NA)) %>%
    pivot_wider(names_from = VISITCD, values_from = day, names_prefix = "d")

  d <- subj %>%
    mutate(grp = case_when(overall_score == "Positive" ~ "Elevated",
                           o$comparator == "LEARN" & SUBSTUDY == "LEARN" ~ "NotElevated",
                           o$comparator == "all_negative" & overall_score == "Negative" ~ "NotElevated")) %>%
    filter(!is.na(grp)) %>%
    left_join(demo, by = "BID") %>% left_join(fh_par, by = "BID") %>% left_join(fh_sib, by = "BID") %>%
    left_join(cfi_pt, by = "BID") %>% left_join(cfi_sp, by = "BID") %>%
    left_join(pw1, by = "BID") %>% left_join(pw6, by = "BID") %>%
    left_join(cs1, by = "BID") %>% left_join(cs6, by = "BID") %>%
    left_join(ftp, by = "BID") %>% left_join(cad, by = "BID") %>% left_join(iesd, by = "BID") %>%
    left_join(sv, by = "BID") %>%
    mutate(grp = factor(grp, levels = c("NotElevated", "Elevated")),
           apoe4 = grepl("E4", APOEGN),
           famhx = coalesce(fh_dem_p, FALSE) | coalesce(fh_dem_s, FALSE),
           famhx_ad = coalesce(fh_ad_p, FALSE) | coalesce(fh_ad_s, FALSE),
           d_gds = gds_post - gds_pre, d_stai = stai_post - stai_pre,
           d_cssrs = cssrs_post - cssrs_pre,
           d_cad = cad_v3 - cad_v1, d_ftp = ftp_v3 - ftp_v1,
           days_disc = d006 - d003,
           has_post = !is.na(gds_post) | !is.na(stai_post) | !is.na(cssrs_post))
  d
}

# ------------------------------------------------------------- analysis ------
covs <- "age + male + cfi_pt + famhx"
ancova <- function(dat, y, extra = "") {
  f <- as.formula(paste(y, "~ grp +", covs, extra))
  co <- summary(lm(f, data = dat))$coefficients["grpElevated", ]
  c(est = unname(co[1]), se = unname(co[2]), p = unname(co[4]),
    n = sum(complete.cases(dat[, all.vars(f)])))
}
msd <- function(x) sprintf("%.2f (%.2f)", mean(x, na.rm = TRUE), sd(x, na.rm = TRUE))
headline <- function(a) {
  # key outcome numbers used for main results and injected-error comparisons
  out <- list()
  for (y in c("d_gds", "d_stai", "d_cssrs", "d_cad", "d_ftp", "ies")) {
    m <- tapply(a[[y]], a$grp, mean, na.rm = TRUE)
    s <- tapply(a[[y]], a$grp, sd, na.rm = TRUE)
    nn <- tapply(!is.na(a[[y]]), a$grp, sum)
    an <- ancova(a, y)
    out[[y]] <- data.frame(outcome = y, n_elev = nn["Elevated"], mean_elev = m["Elevated"],
      sd_elev = s["Elevated"], n_not = nn["NotElevated"], mean_not = m["NotElevated"],
      sd_not = s["NotElevated"], t_p = t.test(a[[y]] ~ a$grp)$p.value,
      adj_est = an["est"], adj_se = an["se"], adj_p = an["p"], adj_n = an["n"],
      row.names = NULL)
  }
  bind_rows(out)
}

# =============================================================== MAIN ========
d_all <- build_data()
cat("== Population derivation ==\n")
flow <- d_all %>% group_by(grp) %>% summarise(
  pool = n(), with_any_post_GDS_STAI_CSSRS_v6 = sum(has_post),
  excluded_no_post = sum(!has_post))
print(as.data.frame(flow))
a <- d_all %>% filter(has_post)
cat("Analysed by substudy:\n"); print(table(a$grp, a$SUBSTUDY))

# ----------------------------------------------------------- Table 1 ---------
cat("\n== Table 1 (pre-disclosure, visit 1) ==\n")
tab1 <- list()
cont <- c(age = "age", educ = "educ", cfi_pt = "cfi_pt", cfi_sp = "cfi_sp", ftp = "ftp_v1",
          concerns = "cad_v1", gds = "gds_pre", stai = "stai_pre", cssrs = "cssrs_pre")
for (nm in names(cont)) {
  v <- cont[[nm]]
  f <- function(g) { x <- a[[v]][a$grp == g]; x <- x[!is.na(x)]
    sprintf("n=%d mean %.2f (SD %.2f) median %.1f [IQR %.1f-%.1f] range %.1f-%.1f", length(x),
            mean(x), sd(x), median(x), quantile(x, .25), quantile(x, .75), min(x), max(x)) }
  tab1[[nm]] <- data.frame(quantity = nm, elevated = f("Elevated"), not_elevated = f("NotElevated"),
                           p = signif(t.test(a[[v]] ~ a$grp)$p.value, 2))
}
cat_vars <- c(male = "male", white_only = "white", white_any = "white_any", latino = "latino", apoe4 = "apoe4",
              famhx_dementia = "famhx", famhx_AD_dx = "famhx_ad")
for (nm in names(cat_vars)) {
  v <- cat_vars[[nm]]
  tb <- table(a$grp, a[[v]])
  f <- function(g) sprintf("%d/%d (%.1f%%)", tb[g, "TRUE"], sum(tb[g, ]), 100 * tb[g, "TRUE"] / sum(tb[g, ]))
  tab1[[nm]] <- data.frame(quantity = nm, elevated = f("Elevated"), not_elevated = f("NotElevated"),
                           p = signif(fisher.test(tb)$p.value, 2))
}
tab1 <- bind_rows(tab1); print(tab1, row.names = FALSE, right = FALSE)

# ----------------------------------------------------------- timing ----------
cat("\n== Days from disclosure (visit 3) to visit 6 ==\n")
print(as.data.frame(a %>% group_by(grp) %>% summarise(n = sum(!is.na(days_disc)),
  mean = mean(days_disc, na.rm = TRUE), sd = sd(days_disc, na.rm = TRUE),
  min = min(days_disc, na.rm = TRUE), max = max(days_disc, na.rm = TRUE))))

# ----------------------------------------------------------- outcomes --------
cat("\n== Change scores (post - pre) and ANCOVA (Elevated - NotElevated; adj. age, sex, CFI, family hx) ==\n")
cat("GDS/STAI/C-SSRS: visit 6 - visit 1; Concerns/FTP: visit 3 - visit 1; IES: visit 3 phone call\n")
hl <- headline(a)
print(hl %>% mutate(across(where(is.numeric) & !matches("^n_|^n$|adj_n"), ~ signif(.x, 3))), row.names = FALSE)

cat("\nWithin-group change vs 0 (one-sample t test P):\n")
wg <- a %>% select(grp, d_gds, d_stai, d_cssrs, d_cad, d_ftp) %>% pivot_longer(-grp) %>%
  filter(!is.na(value)) %>% group_by(outcome = name, grp) %>%
  summarise(n = n(), mean = mean(value), p_vs_0 = t.test(value)$p.value) %>% ungroup()
print(as.data.frame(wg %>% mutate(across(where(is.numeric) & !matches("^n_|^n$|adj_n"), ~ signif(.x, 3)))))

cat("\nSensitivity: ANCOVA additionally adjusting for the baseline score\n")
sens <- bind_rows(lapply(list(c("d_gds", "gds_pre"), c("d_stai", "stai_pre"), c("d_cssrs", "cssrs_pre"),
                              c("d_cad", "cad_v1"), c("d_ftp", "ftp_v1")), function(p) {
  r <- ancova(a, p[1], paste("+", p[2])); data.frame(outcome = p[1], t(signif(r, 3))) }))
print(sens, row.names = FALSE)

# ----------------------------------------------------------- IES categories --
cat("\n== IES (24-72 h post disclosure) distress categories ==\n")
ies_cat <- a %>% filter(!is.na(ies)) %>% group_by(grp) %>% summarise(n = n(),
  mild_9_25 = sum(ies >= 9 & ies <= 25), pct_mild = 100 * mean(ies >= 9 & ies <= 25),
  moderate_gt25 = sum(ies > 25), pct_mod = 100 * mean(ies > 25))
print(as.data.frame(ies_cat))

# ----------------------------------------------------------- thresholds ------
cat("\n== Clinical thresholds (GDS > 6, STAI > 17, C-SSRS > 0) ==\n")
thr <- a %>% group_by(grp) %>% summarise(
  n_gds_both = sum(!is.na(gds_pre) & !is.na(gds_post)),
  gds_new_gt6 = sum(gds_pre <= 6 & gds_post > 6, na.rm = TRUE),
  gds_pre_gt6 = sum(gds_pre > 6, na.rm = TRUE),
  gds_pre_gt6_fell = sum(gds_pre > 6 & gds_post <= 6, na.rm = TRUE),
  n_stai_both = sum(!is.na(stai_pre) & !is.na(stai_post)),
  stai_new_gt17 = sum(stai_pre <= 17 & stai_post > 17, na.rm = TRUE),
  stai_pre_gt17 = sum(stai_pre > 17, na.rm = TRUE),
  stai_pre_gt17_fell = sum(stai_pre > 17 & stai_post <= 17, na.rm = TRUE),
  n_cssrs_both = sum(!is.na(cssrs_pre) & !is.na(cssrs_post)),
  cssrs_pre_gt0 = sum(cssrs_pre > 0, na.rm = TRUE),
  cssrs_post_gt0 = sum(cssrs_post > 0, na.rm = TRUE),
  cssrs_new_onset = sum(cssrs_pre == 0 & cssrs_post > 0, na.rm = TRUE),
  cssrs_post_behaviour = sum(cssrs_post >= 6, na.rm = TRUE))
print(as.data.frame(thr))
p_thr <- sapply(c("gds_new_gt6", "stai_new_gt17", "cssrs_new_onset"), function(v) {
  nb <- c(gds_new_gt6 = "n_gds_both", stai_new_gt17 = "n_stai_both", cssrs_new_onset = "n_cssrs_both")[v]
  x <- thr[[v]]; n <- thr[[nb]]; fisher.test(cbind(x, n - x))$p.value })
cat("Fisher P (Elevated vs NotElevated):\n"); print(signif(p_thr, 3))

# ----------------------------------------------------------- rank regression -
cat("\n== Pre-disclosure rank regression (lm on ranks; adj. age, sex, CFI, family hx) ==\n")
rr <- bind_rows(lapply(c("gds_pre", "stai_pre", "cad_v1", "ftp_v1"), function(y) {
  dd <- a %>% filter(!is.na(.data[[y]])) %>% mutate(r = rank(.data[[y]]))
  co <- summary(lm(as.formula(paste("r ~ grp +", covs)), data = dd))$coefficients
  data.frame(outcome = y, term = rownames(co)[-1], est = signif(co[-1, 1], 3),
             se = signif(co[-1, 2], 3), p = signif(co[-1, 4], 3))
}))
print(rr, row.names = FALSE)

# ----------------------------------------------------------- injected errors -
cat("\n== Injected-error reruns (headline ANCOVA estimates) ==\n")
key <- function(h, label) h %>% transmute(scenario = label, outcome, n_elev, mean_elev, n_not,
                                          mean_not, adj_est, adj_se, adj_p)
inj <- list(key(hl, "0_correct"))
run_inj <- function(label, o_changes, filt = function(x) x %>% filter(has_post)) {
  o <- modifyList(default_opts, o_changes); dd <- filt(build_data(o)); key(headline(dd), label)
}
# E1: wrong post visit = next psychwell visit (A4 wk12 v9, LEARN wk24 v12) instead of visit 6
inj[[2]] <- run_inj("E1_post_visit_wk12_wk24", list(post_visit_a4 = 9, post_visit_learn = 12),
                    filt = function(x) x %>% filter(!is.na(gds_post) | !is.na(stai_post) | !is.na(cssrs_post)))
# E2: lifetime C-SSRS used as baseline (vs since-last-visit at follow-up)
inj[[3]] <- run_inj("E2_cssrs_lifetime_baseline", list(cssrs_base = "lifetime"))
# E3: comparator = all amyloid-negative screenees (not LEARN); no v6 filter for v3 outcomes
inj[[4]] <- run_inj("E3_comparator_all_negatives", list(comparator = "all_negative"),
                    filt = function(x) x %>% filter(has_post | grp == "NotElevated"))
# E4: FTP reverse-keyed items not reversed
inj[[5]] <- run_inj("E4_ftp_no_reverse", list(ftp_reverse = FALSE))
# E5: IES response codes 0/1/3/5 treated as 0/1/2/3
inj[[6]] <- run_inj("E5_ies_recoded_0123", list(ies_recode = TRUE))
# E6: ignore baseline - compare post-disclosure scores only (ANCOVA on post levels)
post_only <- a %>% mutate(d_gds = gds_post, d_stai = stai_post, d_cssrs = cssrs_post,
                          d_cad = cad_v3, d_ftp = ftp_v3)
inj[[7]] <- key(headline(post_only), "E6_post_score_ignoring_baseline")
# E7: group coded the wrong way round (NotElevated - Elevated)
rev_grp <- a %>% mutate(grp = factor(grp, levels = c("Elevated", "NotElevated"),
                                     labels = c("NotElevated", "Elevated")))
inj[[8]] <- key(headline(rev_grp), "E7_group_reversed")
inj <- bind_rows(inj)
print(inj %>% filter(outcome %in% c("d_gds", "d_stai", "d_cssrs", "d_cad", "d_ftp", "ies")) %>%
        mutate(across(where(is.numeric) & !matches("^n_|^n$|adj_n"), ~ signif(.x, 3))), row.names = FALSE)

# ----------------------------------------------------------- write output ----
res <- bind_rows(
  flow %>% pivot_longer(-grp) %>% transmute(section = "flow", quantity = paste(name, grp), value = as.character(value)),
  tab1 %>% mutate(p = as.character(p)) %>% pivot_longer(c(elevated, not_elevated, p)) %>% transmute(section = "table1", quantity = paste(quantity, name), value = as.character(value)),
  hl %>% pivot_longer(-outcome) %>% transmute(section = "outcome", quantity = paste(outcome, name), value = as.character(signif(value, 4))),
  wg %>% pivot_longer(-c(outcome, grp)) %>% transmute(section = "within_group", quantity = paste(outcome, grp, name), value = as.character(signif(value, 4))),
  ies_cat %>% pivot_longer(-grp) %>% transmute(section = "ies_cat", quantity = paste(name, grp), value = as.character(signif(value, 4))),
  thr %>% pivot_longer(-grp) %>% transmute(section = "threshold", quantity = paste(name, grp), value = as.character(value)),
  inj %>% pivot_longer(-c(scenario, outcome)) %>% transmute(section = "injected", quantity = paste(scenario, outcome, name), value = as.character(signif(value, 4)))
)
write.csv(res, "output/results.csv", row.names = FALSE)
cat("\nWrote output/results.csv (", nrow(res), "aggregate rows ). Runtime:",
    round(as.numeric(difftime(Sys.time(), t_start, units = "secs")), 1), "s\n")
