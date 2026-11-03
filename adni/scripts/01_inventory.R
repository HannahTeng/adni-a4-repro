# Dataset inventory: aggregate only (names, dims, distinct participants, key-variable hits).
suppressPackageStartupMessages(library(ADNIMERGE2))
out <- "output"
dir.create(out, showWarnings = FALSE)

cat("R:", R.version.string, "\n")
cat("ADNIMERGE2:", as.character(packageVersion("ADNIMERGE2")), "\n")
src_date <- tryCatch(get("DATA_DOWNLOADED_DATE", asNamespace("ADNIMERGE2")),
                     error = function(e) NA)
cat("Data downloaded date:", format(src_date), "\n")

ds <- data(package = "ADNIMERGE2")$results[, c("Item", "Title")]
ds <- as.data.frame(ds, stringsAsFactors = FALSE)

key_pat <- c(
  dx       = "^(DX|DIAGNOSIS|DXCURREN|DXCHANGE)$",
  cog      = "MMSE|CDRSB|CDGLOBAL|ADAS|PACC|MOCA|FAQ|LDELTOTL|TRAB|DIGIT",
  apoe     = "APOE|GENOTYPE",
  amyloid  = "SUVR|CENTILOID|AMYLOID|AMYSTAT|TRACER|FBP|FBB|PIB|NAV",
  tau_pet  = "META_TEMPORAL|BRAAK|FTP|TAU",
  csf      = "ABETA|PTAU|^TAU|AB42|AB40",
  plasma   = "PLASMA|P217|PT217|PTAU217|NFL|GFAP|C2N|FUJI|ALZPATH|ROCHE|QUANTERIX",
  dates    = "DATE|DTC$|^ADT$|EXAMDATE|SCANDATE|VISDATE"
)

rows <- lapply(seq_len(nrow(ds)), function(i) {
  nm <- ds$Item[i]
  d <- tryCatch(get(nm, envir = asNamespace("ADNIMERGE2")), error = function(e) NULL)
  if (!is.data.frame(d)) {
    return(data.frame(name = nm, title = ds$Title[i], rows = NA, cols = NA,
                      n_participants = NA, key_vars = "", stringsAsFactors = FALSE))
  }
  idcol <- intersect(c("RID", "USUBJID", "PTID", "SUBJID"), names(d))[1]
  npt <- if (!is.na(idcol)) length(unique(d[[idcol]])) else NA
  hits <- unlist(lapply(names(key_pat), function(k) {
    v <- grep(key_pat[[k]], names(d), value = TRUE, ignore.case = TRUE)
    if (length(v)) paste0(k, ":", paste(head(v, 6), collapse = ","))
  }))
  data.frame(name = nm, title = ds$Title[i], rows = nrow(d), cols = ncol(d),
             n_participants = npt, key_vars = paste(hits, collapse = "; "),
             stringsAsFactors = FALSE)
})
inv <- do.call(rbind, rows)
write.csv(inv, file.path(out, "dataset_inventory.csv"), row.names = FALSE)
cat("Datasets:", nrow(inv), "| data.frames:", sum(!is.na(inv$rows)), "\n")
