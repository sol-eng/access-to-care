#' @export
atc_plot_us_map <- function(variable = c("population", "hospitals", "per-capita"),
                            colors = list(high = palette_atc$high, low = palette_atc$low)
                            ) {
  low_color <- colors$low
  high_color <- colors$high
  x_width <- 20
  font <- "Helvetica"
  
  if(variable[[1]] == "per-capita") {
    vr <- "per_person"
    fill_lab <- "1 Hospital per # people"
    low_color <- colors$high
    high_color <- colors$low
  }  
  if(variable[[1]] == "population") {
    vr <- "population"
    fill_lab <- "Population"
  } 
  if(variable[[1]] == "hospitals") {
    vr <- "hospitals"
    fill_lab <- "Hospitals"
  } 
  prep_us <- us_states %>% 
    mutate(
      tooltip = paste0(
        state_name, 
        "\nPopulation: ", format_number(population), 
        "\nHospitals: ", format_number(hospitals)
        ),
      fill = !! sym(vr)
    ) %>% 
    select(state, state_name, fill, tooltip) 
  
  min_fill <- min(prep_us$fill)
  max_fill <- max(prep_us$fill)
  
  prep_us %>% 
    inner_join(us_hex_polygons, by = "state") %>% 
    ggplot() +
    geom_polygon_interactive(
      aes(x, y, group = state, fill = fill, data_id = state_name, tooltip = tooltip), 
      color = "#cccccc"
    ) +
    geom_text_interactive(
      aes(x, y, label = state, data_id = state_name), size = 4, 
      data = us_hex_positions, family = font
    ) +
    scale_fill_gradient(
      low = low_color, 
      high = high_color,
      breaks = c(min_fill, max_fill),
      labels = c(format_number(min_fill), format_number(max_fill))
      ) +
    labs(fill = fill_lab) +
    theme_void() +
    theme(
      legend.position = "bottom"
      )
}

#' @export
atc_plot_state_map <- function(state = "Florida", 
                               variable = c("population", "hospitals", "model"),
                               colors = list(high = palette_atc$high, low = palette_atc$low),
                               model_colors = list(above = palette_atc$above, 
                                                   below = palette_atc$below, 
                                                   ok = palette_atc$ok
                                                   )
                               ) {
  
  county_map <- usmap::us_map("county")
  
  state_polygons <- county_map %>% 
    filter(full == !! state)
  
  us_counties %>% 
    filter(state_name == !! state) %>% 
    mutate(
      tooltip = paste0(
        county_name, 
        "\nPopulation: ", format_number(population), 
        "\nHospitals: ", format_number(hospitals)
      )
    ) %>% 
    select(tooltip, fips, pred_status) %>% 
    right_join(state_polygons, by = "fips") %>% 
    ggplot() +
    geom_polygon_interactive(
      aes(x, y, group = group, fill = pred_status, data_id = fips, tooltip = tooltip),
      color = "#cccccc", alpha = 0.7
    ) +
    scale_fill_manual(
      labels = c("Above", "Below", "At Level"),
      values = c(model_colors$above, model_colors$below, model_colors$ok),
      breaks = c("above", "below", "ok")
    ) +
    labs(fill = "Model results") +
    theme_void() +
    theme(legend.position = "bottom")
}
