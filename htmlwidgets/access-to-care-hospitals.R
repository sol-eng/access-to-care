library(pins)
library(dplyr)
library(htmlwidgets)
library(leaflet)

hospitals <- pin_get("atc-hospital-list", "local")

hospital_maps <- hospitals %>%
  leaflet() %>%
  addProviderTiles(providers$CartoDB) %>%
  addMarkers(
    ~longitude, 
    ~latitude, 
    popup = ~ paste(paste0("<b>", hospital_name, "</b>"), address, sep = "<br/>"), 
    clusterOptions = markerClusterOptions()
    )

saveWidget(hospital_maps, here::here("htmlwidgets/map.html"))

full_path <- here::here("htmlwidgets")
rsconnect::writeManifest(
  appDir = full_path,
  appPrimaryDoc = "map.html",
  contentCategory = "plot"
)