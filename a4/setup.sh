#!/bin/sh
# Rebuild the A4 working tree: extract the A4LEARN vignettes (needed by render.R) and install the package.
# Usage: sh a4/setup.sh /path/to/A4LEARN_1.1.20250808.tar.gz
# The vignettes are ATRI files under the A4 terms of use, so they are extracted here, not committed.
set -eu
TAR=$(cd "$(dirname "${1:?usage: sh a4/setup.sh /path/to/A4LEARN_<version>.tar.gz}")" && pwd)/$(basename "$1")
cd "$(dirname "$0")"
mkdir -p output Rlib
# A4-Primary-Results.Rmd includes ../man/rmd/A4-Primary-Results-child.Rmd, so keep that layout
tar -xzf "$TAR" --strip-components=1 A4LEARN/vignettes A4LEARN/man/rmd
echo "R_LIBS_USER=$PWD/Rlib" > .Renviron
Rscript -e "
options(repos = 'https://cloud.r-project.org', Ncpus = 8)
need <- c('arsenal', 'kableExtra', 'clubSandwich', 'Hmisc', 'tidyverse', 'nlme', 'emmeans', 'rmarkdown', 'knitr')
miss <- setdiff(need, rownames(installed.packages()))
if (length(miss)) install.packages(miss, lib = .libPaths()[1])
install.packages('$TAR', repos = NULL, type = 'source', lib = .libPaths()[1])
library(A4LEARN); cat('A4LEARN', as.character(packageVersion('A4LEARN')), 'ready\n')
"
