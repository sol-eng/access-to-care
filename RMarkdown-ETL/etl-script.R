library(tidyverse)
library(rlang)
library(leaflet)
library(purrr)
library(tigris)
library(fs)
library(haven)
library(usmap)
library(pins)
library(config)

hospitals_raw <- haven::read_sas("data/Structural_Measures_-_Hospital.sas7bdat") 

hospitals <- hospitals_raw %>%
  rename_all(str_to_lower) %>%
  rename_all(str_replace_all, " ", "_") %>%
  select(provider_id, hospital_name, state, county_name, location) %>%
  group_by_all() %>%
  summarise() %>%
  ungroup() %>%
  separate(location, into = c("address", "location"), sep = "\\(") %>%
  mutate(location = str_remove(location, "\\)")) %>%
  separate(location, into = c("latitude", "longitude"), sep = ",") %>%
  mutate(
    longitude = as.numeric(longitude), latitude = as.numeric(latitude),
    county_key = str_remove_all(county_name, " County"),
    county_key = str_remove_all(county_key, " Parish"),
    county_key = str_remove_all(county_key, " city"),
    county_key = str_to_lower(county_key),
    county_key = str_remove_all(county_key, " "),
    county_key = str_replace_all(county_key, "st. ", "saint"))  


hospital_locations <- hospitals  %>%
  filter(!is.na(longitude)) %>%
  select(state, longitude, latitude)

write_rds(hospital_locations, "data/hospital_locations.rds")


population <- usmap::countypop %>%
  mutate(
    county_key = str_remove_all(county, " County"),
    county_key = str_remove_all(county_key, " Parish"),
    county_key = str_remove_all(county_key, " city"),
    county_key = str_to_lower(county_key),
    county_key = str_remove_all(county_key, " "),
    county_key = str_replace_all(county_key, "st. ", "saint")) %>%
  rename(
    population = pop_2015,
    state = abbr
  )

hospital_count <- hospitals %>%
  count(state, county_name) %>%
  filter(!is.na(county_name)) %>%
  mutate(
    county_key = str_remove_all(county_name, " County"),
    county_key = str_remove_all(county_key, " Parish"),
    county_key = str_remove_all(county_key, " city"),
    county_key = str_to_lower(county_key),
    county_key = str_remove_all(county_key, " "),
    county_key = str_replace_all(county_key, "st.", "saint")) %>%
  rename(hospitals = n)


state_hospitals <- population %>%
  left_join(hospital_count, by = c("state" = "state", "county_key" = "county_key")) %>%
  replace_na(list(hospitals = 0)) 


set.seed(100)

hospital_sample <- state_hospitals %>%
  sample_frac(0.3)

hospital_sample

model <- lm(hospitals ~ population, data = hospital_sample)
write_rds(model, "data/model.rds")
summary(model)

predictions <- predict(model, 
                       newdata = state_hospitals, 
                       interval = "prediction") %>%
  as_tibble() %>%
  mutate_all(round)

hospital_results <- state_hospitals %>%
  bind_cols(predictions) %>%
  mutate(result = case_when(
    hospitals < lwr ~ -1,
    hospitals > upr ~ 1,
    TRUE ~ 0))

write_rds(hospital_results, "data/hospitals.rds")

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

select_row <- function(x, y) x %% y == 0

extract_coordinates <- function(path, decimals = 2) {
  state_rds <- readRDS(path)
  state_rds@polygons %>%
    map(~ {
      map(
        .x@Polygons,
        ~ tibble(
          long = .x@coords[, 1],
          lat = .x@coords[, 2],
          rn = 1:length(.x@coords[, 1]),
          sel = select_row(rn, 8)
        )) %>% 
        set_names(paste0("s", seq_along(.x@Polygons))) %>%
        map_df(~.x, .id = "shape_id")}) %>%
    set_names(state_rds$NAME) %>%
    map_df(~.x, .id = "county") %>%
    filter(sel) %>%
    select(-rn, -sel)
}

county_states <- map_dfr(
  all_paths,
  extract_coordinates,
  .id = "state"
) 

nested_states <- county_states %>%
  group_nest(state, county, shape_id) %>%
  group_nest(state, county)

write_rds(nested_states, "data/shapes.rds", compress = "gz")

shapes <- county_states %>%
  mutate(
    county_key = str_to_lower(county),
    county_key = str_remove_all(county_key, " "),
    county_key = str_replace_all(county_key, "st. ", "saint")
  ) 

county_hospitals_nested <- hospital_results  %>%
  select(- county) %>%
  left_join(shapes, by = c("state", "county_key")) %>%
  filter(!is.na(county))

write_rds(county_hospitals_nested, "data/county_hospitals.rds", compress = "gz")

county_hospitals <- hospital_results  %>%
  select(- county) %>%
  left_join(shapes, by = c("state", "county_key")) %>%
  filter(!is.na(county))

## Output - Register PINs inside RStudio Connect

board_register("rsconnect", 
               server = "https://colorado.rstudio.com/rsc",
               key = config::get("rsckey")
               ) 

pin(county_hospitals, 
    name = "atc-county_hospitals", 
    board = "rsconnect"
    )

pin(model, 
    name = "atc-model", 
    board = "rsconnect"
    )
pin(hospital_locations, 
    "atc-hospital-locations", 
    board = "rsconnect")

pin(hospitals, 
    "atc-hospitals", 
    board = "rsconnect"
    )
pint(county_states, 
     name = "atc_shapes", 
     board = "rsconnect"
     )

## Copy config file

library(fs)

map(
  c("../flexdashboard", "../presentation", 
    "../RMarkdown-html", "../RMarkdown-pdf", 
    "../plumber-api", "../powerpoint", 
    "../powerpoint-state"
    ),
  ~ file_copy("config.yml", .x, overwrite = TRUE)
)

# map(
#   c("../flexdashboard", "../presentation", 
#     "../RMarkdown-html", "../RMarkdown-pdf", 
#     "../plumber-api", "../powerpoint", 
#     "../powerpoint-state"
#   ),
#   ~ writeLines("config.yml", file.path(.x, ".gitignore"))
# )
