#' @export
atc_plot_us_map <- function(variable = c("population", "hospitals", "above", "below"),
                            colors = list(high = palette_atc$high, low = palette_atc$low)
                            ) {
  low_color <- colors$low
  high_color <- colors$high
  x_width <- 20
  font <- "Helvetica"
  
  if(variable[[1]] == "above") {
    vr <- "pred_above"
    fill_lab <- "Counties"
    high_color <- palette_atc$above
  } 
  if(variable[[1]] == "below") {
    vr <- "pred_below"
    fill_lab <- "Counties"
    high_color <- palette_atc$below
  } 
  if(variable[[1]] == "population") {
    vr <- "population"
    fill_lab <- "Population"
  } 
  if(variable[[1]] == "hospitals") {
    vr <- "hospitals"
    fill_lab <- "Hospitals"
  } 
  prep_us <- us_atc_state_polygons
  prep_us$tooltip <- paste0(
    prep_us$state_name, 
    "\nPopulation: ", format_number(prep_us$population), 
    "\nHospitals: ", format_number(prep_us$hospitals)
    )
  prep_us$fill <- prep_us[, vr][[1]]
  
  min_fill <- min(prep_us$fill)
  max_fill <- max(prep_us$fill)
  
  ggplot(data = prep_us) +
    geom_polygon_interactive(
      aes(x, y, group = state, data_id = state_name, fill = fill), 
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
      legend.position = "bottom", 
      legend.text = element_text(family = font),
      legend.title = element_text(family = font)
    )
  
}

#' @export
atc_plot_state_map <- function(state = "Florida", 
                               variable = c("model", "population", "hospitals"),
                               colors = list(high = palette_atc$high, 
                                             low = palette_atc$low
                                             ),
                               model_colors = list(above = palette_atc$above, 
                                                   below = palette_atc$below, 
                                                   ok = palette_atc$ok
                                                   ),
                               top_cities = 3
                               ) {
  
  low_color <- colors$low
  high_color <- colors$high
  x_width <- 20
  font <- "Helvetica"
  
  if(variable[[1]] == "model") {
    vr <- "pred_status"
    fill_lab <- "Model results"
  }  
  if(variable[[1]] == "population") {
    vr <- "population"
    fill_lab <- "Population"
  } 
  if(variable[[1]] == "hospitals") {
    vr <- "hospitals"
    fill_lab <- "Hospitals"
  } 
  if(state == "All US") {
    prep_us <- us_atc_county_polygons
    prep_cities <- us_large_cities
  } else {
    prep_us <- us_atc_county_polygons[us_atc_county_polygons$state_name == state, ]  
    prep_cities <- us_large_cities[us_large_cities$state == prep_us$state[[1]], ]
  }
  
  prep_cities <- prep_cities[prep_cities$position <= top_cities, ]
  
  prep_us$tooltip <- paste0(
    prep_us$county_name, 
    "\nPopulation: ", format_number(prep_us$population), 
    "\nHospitals: ", format_number(prep_us$hospitals)
  )
  prep_us$fill <- prep_us[, vr][[1]]
  
  gp <- ggplot(data = prep_us) +
    geom_text(aes(x, y, label = city_name), 
              data = prep_cities, 
              hjust = 1.1,
              family = font
              ) +
    geom_point(aes(x, y), data = prep_cities) +
    geom_polygon_interactive(
      aes(x, y, group = group, fill = fill, data_id = fips, tooltip = tooltip),
      color = "#cccccc", 
      size = 0.3,
      alpha = 0.6
    ) +
    labs(fill = fill_lab) +
    theme_void() +
    theme(
      legend.position = "bottom", 
      legend.text = element_text(family = font),
      legend.title = element_text(family = font)
      )
  
  if(is.numeric(prep_us$fill)) {
    min_fill <- min(prep_us$fill)
    max_fill <- max(prep_us$fill)
    gp +
      scale_fill_gradient(
        low = low_color, 
        high = high_color,
        breaks = c(min_fill, max_fill),
        labels = c(format_number(min_fill), format_number(max_fill))
      ) 
  } else {
    gp +
      scale_fill_manual(
        labels = c("Above", "Below", "At Level"),
        values = c(model_colors$above, model_colors$below, model_colors$ok),
        breaks = c("above", "below", "ok")
      ) 
  }
}
