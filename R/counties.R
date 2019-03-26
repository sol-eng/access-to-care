library(purrr)
library(tigris)
library(fs)
library(readr)
library(dplyr)
library(leaflet)


dir_create("shapes")
all_paths <- path("shapes", state.abb, ext = "rds") %>%
  set_names(state.abb)

exist <- file_exists(all_paths)

county_paths <- all_paths[!exist]

imap(
  county_paths,
  ~ counties(.y) %>%
    write_rds(.x)
)

extract_coordinates <- function(path, decimals = 2) {
  state_rds <- readRDS(path)
  state <- state_rds@polygons[[2]]@Polygons[[1]]@coords
  map(
    state_rds@polygons,
    ~.x@Polygons[[1]]@coords
  ) %>%
    set_names(state_rds$NAME) %>%
    imap_dfr(
      ~ tibble(
        county = .y,
        long = round(.x[, 1], decimals),
        lat = round(.x[, 2], decimals),
        rn = 1:length(.x[, 1])
      )
    ) %>%
    group_by(county, long, lat) %>%
    summarise(rn = max(rn)) %>%
    ungroup() %>% 
    arrange(county, rn) %>%
    group_by(county) %>%
    mutate(point_no = row_number()) %>%
    ungroup() %>%
    select(county, long, lat, point_no)
}

county_states <- map_dfr(
  all_paths,
  extract_coordinates,
  .id = "state"
) %>%
  group_nest(state, county)

write_rds(county_states, "data/shapes.rds", compress = "gz")
