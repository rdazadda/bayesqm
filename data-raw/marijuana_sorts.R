# Builds data/marijuana_sorts.rda from the marijuana legalization Q
# dataset of Akhtar-Danesh (2023), doi:10.1371/journal.pone.0290728.
# Source spreadsheet: the author's copy of the published dataset.

pkgload::load_all(".", quiet = TRUE)

marijuana_sorts <- read_qsort(
  "C:/Users/rdazadda/OneDrive - University of Alaska/Desktop/Marijuana legalization dataset.xlsx")

print(marijuana_sorts)

dir.create("data", showWarnings = FALSE)
save(marijuana_sorts, file = "data/marijuana_sorts.rda", compress = "xz")
cat("saved data/marijuana_sorts.rda\n")
