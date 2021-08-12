library(pins)
library(dplyr)
library(ggplot2)

under <- "#CC79A7"
over <- "#0072B2"
at_level <- "#008b00"
hospital_color <- "#F0E442"

if(Sys.getenv("R_CONFIG_ACTIVE") == "rsconnect") {
  boardname <- "rsconnect"
  board_register_rsconnect(
    server = Sys.getenv("CONNECT_SERVER"),
    key = Sys.getenv("CONNECT_API_KEY")
  )
} else {
  boardname <- "local"
  board_register(boardname)  
}

states <- pin_get("atc-states", board = boardname) 

curr_state <- pull(states, state_id)

counties <- pin_get("atc-county-map", boardname) 

counties <- pin_get("atc-county-map", boardname)

base_map <- pin_get("atc-base-map", boardname) %>%
  filter(state != "HI")

full_map <- base_map %>%
  select(popup, color, county_id) %>%
  inner_join(counties, by = "county_id")

ggplot_map <- full_map %>%
  mutate(group = paste(county_id, shape_id)) %>%
  ggplot() +
  geom_polygon(
    aes(long, lat, group = group), 
    fill = full_map$color,
    alpha = 0.5,
    color = "#666666",
    size = 0.1
  ) +
  theme_minimal() +
  theme(
    axis.title = element_blank(), 
    axis.text = element_blank(), 
    panel.grid = element_blank(),
    panel.grid.major = element_blank()) 

ggsave(plot = ggplot_map, filename = here::here("plot/map.png"))
writeLines("<img src=map.png width = 1000>", con = here::here("plot/map.html"))

full_path <- here::here("plot")
rsconnect::writeManifest(
  appDir = full_path,
  appPrimaryDoc = "map.html",
  contentCategory = "plot"
)

