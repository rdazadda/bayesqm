# Builds data/obesity_sorts.rda from the childhood obesity Q dataset of
# Akhtar-Danesh (2023), doi:10.1371/journal.pone.0290728.
# Source spreadsheet: the author's copy of the published dataset.

pkgload::load_all(".", quiet = TRUE)

obesity_sorts <- read_qsort(
  "C:/Users/rdazadda/OneDrive - University of Alaska/Desktop/Childhood obesity dataset.xlsx")

print(obesity_sorts)

dir.create("data", showWarnings = FALSE)
save(obesity_sorts, file = "data/obesity_sorts.rda", compress = "xz")
cat("saved data/obesity_sorts.rda\n")
