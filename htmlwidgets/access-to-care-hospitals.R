library(accesstocare)
library(htmlwidgets)
library(ggiraph)
library(fs)

p <- atc_plot_state_map("All US", top_cities = 0)

gp <- girafe(ggobj = p)

content_folder <- here::here("htmlwidgets")

# Save the map as an HTMLWidget
saveWidget(gp, path(content_folder, "map.html"))

# Write the manifest
atc_write_manifest(
  folder_location  = content_folder,
  primary_document = "map.html"
)
