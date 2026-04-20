test_that("bayesqm_colors returns a complete palette", {
  p <- bayesqm_colors()
  expect_type(p, "list")
  for (slot in c("light", "mid", "dark", "accent",
                 "grey", "gridgrey", "fill"))
    expect_true(slot %in% names(p), info = paste0("missing: ", slot))
})

test_that("bayesqm_set_colors switches between built-in schemes", {
  old <- bayesqm_set_colors("teal")
  on.exit(bayesqm_set_colors(old), add = TRUE)

  p <- bayesqm_colors()
  expect_equal(p$mid, "#66c2a5")

  bayesqm_set_colors("red")
  expect_equal(bayesqm_colors()$mid, "#d6604d")
})

test_that("bayesqm_set_colors accepts a custom list", {
  old <- bayesqm_set_colors(list(
    light    = "#ffffff",
    mid      = "#888888",
    dark     = "#000000",
    accent   = "#ff0000",
    grey     = "#aaaaaa",
    gridgrey = "#cccccc",
    fill     = "#dddddd"
  ))
  on.exit(bayesqm_set_colors(old), add = TRUE)

  expect_equal(bayesqm_colors()$mid,  "#888888")
  expect_equal(bayesqm_colors()$dark, "#000000")
})

test_that("bayesqm_set_colors rejects unknown schemes and incomplete lists", {
  expect_error(bayesqm_set_colors("nonexistent"), "Unknown scheme")
  expect_error(bayesqm_set_colors(list(light = "#fff", mid = "#000")),
               "missing slot")
  expect_error(bayesqm_set_colors(42), "character name or a named list")
})

test_that("plots use the active scheme", {
  old <- bayesqm_set_colors("red")
  on.exit(bayesqm_set_colors(old), add = TRUE)

  fit <- make_fake_fit(N = 4, J = 8, K = 2)
  pdf(file = tempfile(fileext = ".pdf"))
  on.exit(dev.off(), add = TRUE)

  # Just verify it runs end-to-end under a non-default scheme.
  expect_silent(plot(fit))
  expect_silent(plot_loading_posterior(fit))
})
