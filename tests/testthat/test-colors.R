test_that("bayesqm_colors returns a complete palette", {
  p <- bayesqm_colors()
  expect_type(p, "list")
  for (slot in c("dark", "accent", "grey", "gridgrey", "fill", "qual"))
    expect_true(slot %in% names(p), info = paste0("missing: ", slot))
})

test_that("bayesqm_set_colors switches between built-in schemes", {
  old <- bayesqm_set_colors("teal")
  on.exit(bayesqm_set_colors(old), add = TRUE)

  p <- bayesqm_colors()
  expect_equal(p$dark, "#00441b")

  bayesqm_set_colors("red")
  expect_equal(bayesqm_colors()$dark, "#67001f")
})

test_that("bayesqm_set_colors accepts a custom list", {
  old <- bayesqm_set_colors(list(
    dark     = "#000000",
    accent   = "#ff0000",
    grey     = "#aaaaaa",
    gridgrey = "#cccccc",
    fill     = "#dddddd"
  ))
  on.exit(bayesqm_set_colors(old), add = TRUE)

  expect_equal(bayesqm_colors()$dark,   "#000000")
  expect_equal(bayesqm_colors()$accent, "#ff0000")
})

test_that("bayesqm_set_colors rejects unknown schemes and incomplete lists", {
  expect_error(bayesqm_set_colors("nonexistent"), "Unknown scheme")
  expect_error(bayesqm_set_colors(list(dark = "#fff", accent = "#000")),
               "missing slot")
  expect_error(bayesqm_set_colors(42), "character name or a named list")
})

test_that("the active scheme is what bayesqm_colors() serves", {
  old <- bayesqm_set_colors("red")
  on.exit(bayesqm_set_colors(old), add = TRUE)
  active <- bayesqm_colors()
  expect_true(all(c("dark", "accent", "grey", "gridgrey", "fill")
                  %in% names(active)))
  bayesqm_set_colors("blue")
  expect_false(identical(bayesqm_colors()$dark, active$dark))
})
