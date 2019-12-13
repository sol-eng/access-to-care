library(pins)
library(dplyr)
library(htmlwidgets)
library(leaflet)

under <- "#CC79A7"
over <- "#0072B2"
at_level <- "#008b00"
hospital_color <- "#F0E442"

if(Sys.getenv("R_CONFIG_ACTIVE") == "rsconnect") {
  boardname <- "rsconnect"
  board_register_rsconnect(
    server = Sys.getenv("connect_url"),
    key = Sys.getenv("connect_key")
  )
} else {
  boardname <- "local"
  board_register(boardname)  
}

hospitals <- pin_get("atc-hospitals", boardname)

hospital_maps <- hospitals %>%
  leaflet() %>%
  addTiles() %>%
  addMarkers(~longitude, ~latitude, clusterOptions = markerClusterOptions())

saveWidget(hospital_maps, here::here("htmlwidgets/map.html"))

full_path <- here::here("htmlwidgets")
rsconnect::writeManifest(
  appDir = full_path,
  appPrimaryDoc = "map.html",
  contentCategory = "plot"
)