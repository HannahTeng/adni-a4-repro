#!/bin/sh
# Rebuild the ADNI working tree next to the scripts.
# Usage: sh adni/setup.sh /path/to/download.zip
#   download.zip = LONI IDA "ADNIMERGE - Key ADNI tables merged into one Packages for R" download
#   (contains ADNIMERGE2.tar.gz, the methods PDF and DATADIC_*.csv).
set -eu
ZIP=$(cd "$(dirname "${1:?usage: sh adni/setup.sh /path/to/download.zip}")" && pwd)/$(basename "$1")
cd "$(dirname "$0")"
mkdir -p raw rlib-src output Rlib
unzip -o -q "$ZIP" -d raw
tar -xzf raw/ADNIMERGE2.tar.gz -C rlib-src
echo "R_LIBS_USER=$PWD/Rlib" > .Renviron
Rscript -e '
options(repos = "https://cloud.r-project.org", Ncpus = 8)
need <- c("assertr", "gtsummary", "labelled", "see", "consort", "marginaleffects", "performance", "lme4",
          "tidyverse", "rmarkdown", "knitr", "DT", "nlme")
miss <- setdiff(need, rownames(installed.packages()))
if (length(miss)) install.packages(miss, lib = .libPaths()[1])
install.packages("raw/ADNIMERGE2.tar.gz", repos = NULL, type = "source", lib = .libPaths()[1])
library(ADNIMERGE2); cat("ADNIMERGE2", as.character(packageVersion("ADNIMERGE2")), "ready\n")
'
