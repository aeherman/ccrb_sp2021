library(tidyverse)
final_project_theme <- function() {
  ggplot2::theme(
    panel.background = element_blank(),
    legend.background = element_blank(),
    strip.background = element_blank(),
    axis.ticks = element_blank(),
    plot.title = element_text(hjust = 0.5, size = 15),
    legend.position = "bottom",
    legend.key = element_blank(),
    text = element_text(family = "serif"),
    strip.text.y.right = element_text(angle = 0),
    strip.text.y.left = element_text(angle = 0)
    )
}

theme_set(final_project_theme())

facet_theme <- theme(panel.grid = element_blank(),
                     panel.background = element_rect(fill = "grey90", color = "white"),
                     axis.text.y = element_blank())

pal_disposition <- c("#6666FF", "#CCCCFF", "red")