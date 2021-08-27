library(accesstocare)
library(ggplot2)
library(fs)

# Save ggplot into a variable
p <- atc_plot_state_map("All US", top_cities = 0)

content_folder <- here::here("plot")

# Save the map as a PNG file
ggsave(plot = p, filename = path(content_folder, "map.png"))

# Create a quick html file, with the PNG as its sole content
writeLines("<img src=map.png width = 1000>", con = path(content_folder, "map.html"))

# Write the manifest
atc_write_manifest(
  folder_location = content_folder,
  primary_document = "map.html"
  )
