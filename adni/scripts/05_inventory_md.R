x <- read.csv("output/dataset_inventory.csv")
x <- x[order(x$name), ]
fmt <- function(v) ifelse(is.na(v), "", formatC(v, format = "d", big.mark = ","))
t <- gsub("\\|", "/", substr(gsub("\\s+", " ", x$title), 1, 95))
lines <- c("| Dataset | Rows | Cols | Participants | Description |", "|---|---:|---:|---:|---|",
           sprintf("| %s | %s | %s | %s | %s |", x$name, ifelse(is.na(x$rows), "(not a data frame)", fmt(x$rows)),
                   fmt(x$cols), fmt(x$n_participants), t))
writeLines(lines, "output/inventory_table.md")
