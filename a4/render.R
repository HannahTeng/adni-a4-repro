for (v in c("A4-Primary-Results", "A4-LEARN-Baseline-Characteristics")) {
  t0 <- Sys.time()
  rmarkdown::render(file.path("vignettes", paste0(v, ".Rmd")),
                    output_dir = "output", envir = new.env(), quiet = TRUE)
  cat(v, "rendered in", format(Sys.time() - t0), "\n")
}
writeLines(capture.output(sessionInfo()), "output/sessionInfo.txt")
