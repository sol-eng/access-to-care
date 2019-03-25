library(purrr)
library(tigris)
library(fs)
library(readr)
library(dplyr)
library(leaflet)

all_paths <- path("shapes", state.abb, ext = "rds") 

exist <- file_exists(all_paths)

county_paths <- all_paths[!exist] %>%
  set_names(state.abb[!exist])


imap(
  county_paths,
  ~ counties(.y) %>%
    write_rds(.x)
)

#leaflet() %>%
#  addPolygons(data = AL, fillOpacity =  as.numeric(AL$COUNTYFP) / 100)
