# Render the Q-sort grid figure used in the JOSS paper.
# Run from the package root: Rscript paper/generate_figures.R

suppressPackageStartupMessages(library(ggplot2))

dir.create("paper/figures", showWarnings = FALSE, recursive = TRUE)

# 36-statement Q-sort on a nine-category forced distribution.
scores       <- c(-4, -3, -2, -1, 0, 1, 2, 3, 4)
distribution <- c( 2,  3,  4,  5, 8, 5, 4, 3, 2)

# One row per (score, slot) pair so geom_tile draws a stack of boxes.
grid_df <- do.call(rbind, Map(function(s, n) {
  data.frame(score = s, row = seq_len(n))
}, scores, distribution))

arrow_inch <- grid::unit(0.07, "inches")

p <- ggplot(grid_df, aes(x = score, y = row)) +
  geom_tile(width = 0.82, height = 0.82,
            fill = "white", colour = "black", linewidth = 0.45) +
  scale_x_continuous(breaks = scores,
                     labels = c("-4", "-3", "-2", "-1", "0",
                                "+1", "+2", "+3", "+4")) +
  scale_y_continuous(expand = expansion(mult = c(0.04, 0.04))) +
  annotate("text", x = -4, y = -0.55, label = "Most disagree", size = 3.4) +
  annotate("text", x =  0, y = -0.55, label = "Neutral",       size = 3.4) +
  annotate("text", x =  4, y = -0.55, label = "Most agree",    size = 3.4) +
  annotate("segment", x = -3.3, xend = -0.7, y = -0.55, yend = -0.55,
           arrow = arrow(length = arrow_inch, ends = "both"), linewidth = 0.4) +
  annotate("segment", x =  0.7, xend =  3.3, y = -0.55, yend = -0.55,
           arrow = arrow(length = arrow_inch, ends = "both"), linewidth = 0.4) +
  labs(x = NULL, y = NULL) +
  theme_void(base_size = 11) +
  theme(axis.text.x = element_text(margin = margin(t = 6)),
        plot.margin = margin(6, 6, 14, 6)) +
  coord_cartesian(clip = "off")

ggsave("paper/figures/qsort-grid.pdf",
       plot = p, width = 5.6, height = 3.0, device = cairo_pdf)
