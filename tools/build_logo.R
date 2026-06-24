# Build the bayesqm hex logo (man/figures/logo.png).
# Run from the package root:  Rscript tools/build_logo.R

library(ggplot2)
library(showtext)
library(sysfonts)

font_add_google("Nunito", "nunito")
showtext_auto()
showtext_opts(dpi = 600)

navy <- "#1E3A5F"
band <- "#FFFFFF"
rank_palette <- grDevices::colorRampPalette(
  c("#6C3483", "#2E86C1", "#17A589", "#F4D03F",
    "#E67E22", "#E74C3C", "#922B21")
)

hexagon <- function(scale = 1) {
  data.frame(
    x = scale * c(0, -sqrt(3) / 2, -sqrt(3) / 2, 0, sqrt(3) / 2, sqrt(3) / 2),
    y = scale * c(1, 0.5, -0.5, -1, -0.5, 0.5)
  )
}

heights  <- c(1, 2, 3, 4, 5, 4, 3, 2, 1)   # forced-distribution column heights
n_rank   <- length(heights)
rank_col <- rank_palette(n_rank)
spacing  <- 0.158
tile     <- 0.124
base_y   <- -0.06
col_x    <- (seq_len(n_rank) - (n_rank + 1) / 2) * spacing

tiles <- do.call(rbind, lapply(seq_len(n_rank), function(j) {
  data.frame(
    x    = col_x[j],
    y    = base_y + (seq_len(heights[j]) - 1) * spacing,
    fill = rank_col[j]
  )
}))

logo <- ggplot() +
  geom_polygon(data = hexagon(1.00), aes(x, y), fill = navy) +
  geom_polygon(data = hexagon(0.95), aes(x, y), fill = band) +
  geom_polygon(data = hexagon(0.88), aes(x, y), fill = navy) +
  annotate(
    "segment",
    x = min(col_x) - spacing * 0.6, xend = max(col_x) + spacing * 0.6,
    y = base_y - spacing * 0.62,    yend = base_y - spacing * 0.62,
    colour = "white", alpha = 0.30, linewidth = 0.5
  ) +
  geom_tile(data = tiles, aes(x, y, fill = fill), width = tile, height = tile) +
  scale_fill_identity() +
  annotate(
    "text", x = 0, y = -0.57, label = "bayesqm",
    colour = "white", family = "nunito", fontface = "bold",
    size = 6, hjust = 0.5
  ) +
  coord_fixed(xlim = c(-1, 1), ylim = c(-1.05, 1.05), expand = FALSE, clip = "off") +
  theme_void() +
  theme(legend.position = "none", plot.margin = margin(0, 0, 0, 0))

ggsave(
  "man/figures/logo.png", logo,
  width = 5.08, height = 5.86, units = "cm", dpi = 600, bg = "transparent"
)
