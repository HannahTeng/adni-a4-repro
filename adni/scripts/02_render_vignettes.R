# Render selected ADNIMERGE2 vignettes into output/ and record runtime.
# Usage: Rscript scripts/02_render_vignettes.R ADNI-Enrollment ADNI-Longitudinal ...
suppressPackageStartupMessages(library(rmarkdown))
args <- commandArgs(trailingOnly = TRUE)
src <- "rlib-src/ADNIMERGE2/vignettes"
out <- normalizePath("output")
work <- file.path(tempdir(), "vig")
dir.create(work, showWarnings = FALSE)
file.copy(list.files(src, full.names = TRUE), work, overwrite = TRUE)

times <- data.frame(vignette = character(), seconds = numeric(), status = character())
for (v in args) {
  t0 <- Sys.time()
  status <- tryCatch({
    render(file.path(work, paste0(v, ".Rmd")), output_dir = out,
           intermediates_dir = work, envir = new.env(), quiet = TRUE)
    "ok"
  }, error = function(e) paste("ERROR:", conditionMessage(e)))
  secs <- round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1)
  cat(sprintf("%-32s %7.1fs  %s\n", v, secs, status))
  times <- rbind(times, data.frame(vignette = v, seconds = secs, status = status))
}
f <- file.path(out, "render_times.csv")
if (file.exists(f)) times <- rbind(read.csv(f), times)
write.csv(times, f, row.names = FALSE)
