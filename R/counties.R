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
  state_rds@polygons %>%
    map(~ {
      map(
        .x@Polygons,
        ~ tibble(
          long = round(.x@coords[, 1], decimals),
          lat = round(.x@coords[, 2], decimals),
          rn = 1:length(.x@coords[, 1]))) %>% 
        set_names(paste0("s", seq_along(.x@Polygons))) %>%
        map_df(~.x, .id = "shape_id")}) %>%
    set_names(state_rds$NAME) %>%
    map_df(~.x, .id = "county") %>%
    group_by(county, shape_id, long, lat) %>%
    summarise(rn = max(rn)) %>%
    ungroup() %>% 
    arrange(county, shape_id, rn) %>%
    group_by(county, shape_id) %>%
    mutate(point_no = row_number()) %>%
    ungroup() %>%
    select(county, shape_id, long, lat, point_no) 
}

county_states <- map_dfr(
  all_paths,
  extract_coordinates,
  .id = "state"
) 

nested_states <- county_states %>%
  group_nest(state, county)

write_csv(county_states, "data/shapes.csv")
write_rds(nested_states, "data/shapes.rds", compress = "gz")

county_states %>%
  filter(state == "NY") %>%
  write_csv("data/ny-shapes.csv")

