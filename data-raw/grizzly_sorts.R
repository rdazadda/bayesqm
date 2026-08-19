# Builds data/grizzly_sorts.rda from the grizzly bear reintroduction Q
# dataset of Easter et al. (2025), doi:10.1002/pan3.10748, distributed
# under CC0 on Dryad, doi:10.5061/dryad.73n5tb369.
# Source spreadsheet: the author's cleaned copy of the Dryad data.

pkgload::load_all(".", quiet = TRUE)

grizzly_sorts <- read_qsort(
  paste0("C:/Users/rdazadda/OneDrive - University of Alaska/Desktop/",
         "smr-migration/rank-revision/Real Data Analysis/data/",
         "Grizzly bear dataset.xlsx"))

print(grizzly_sorts)

dir.create("data", showWarnings = FALSE)
save(grizzly_sorts, file = "data/grizzly_sorts.rda", compress = "xz")
cat("saved data/grizzly_sorts.rda\n")
