library(accesstocare)
library(leaflet)
library(dplyr)
library(gt)

state_choices <- c("Model", "No. of Hospitals", "Population")

ui <- fillPage(
  leafletOutput("map", width = "100%", height = "100%"),
  absolutePanel(
    top = 10,
    right = 10,
    width = 250,
    height = "auto",
    div(
      style = "background: white; padding: 15px; border-radius: 5px; box-shadow: 0 0 15px rgba(0,0,0,0.2);",
      h3("Access to Care", style = "margin-top: 0; margin-bottom: 15px;"),
      hr(),
      radioButtons(
        inputId = "view",
        label = "Select a view:",
        choices = state_choices
      )
    ),
    draggable = TRUE
  ),
  absolutePanel(
    bottom = 10,
    left = 10,
    width = "auto",
    height = "auto",
    div(
      style = "background: white; padding: 10px; border-radius: 5px; box-shadow: 0 0 15px rgba(0,0,0,0.2);",
      p(
        em(
          "Sources: Centers of Medicine & Medicaid services (2025), and US Census Bureau (2024)."
        ),
        style = "margin: 0; font-size: 0.85em;"
      )
    )
  )
)

server <- function(input, output, session) {
  # Prepare county data once
  county_data <- reactive({
    # Get unique county information
    us_atc_county_polygons |>
      group_by(fips) |>
      slice(1) |>
      ungroup() |>
      select(fips, state, county_name, hospitals, population, pred_status)
  })

  # Prepare polygon coordinates grouped by county
  county_polygons <- reactive({
    us_atc_county_polygons |>
      filter(!is.na(long), !is.na(lat)) |>
      arrange(fips, group, piece) |>
      group_by(fips, group) |>
      summarise(
        longs = list(long),
        lats = list(lat),
        .groups = "drop"
      ) |>
      group_by(fips) |>
      summarise(
        longs = list(longs),
        lats = list(lats),
        .groups = "drop"
      )
  })

  output$map <- renderLeaflet({
    # Base map - adjusted to show all US including Alaska and Hawaii
    leaflet() |>
      addProviderTiles(providers$CartoDB.Positron) |>
      fitBounds(lng1 = -180, lat1 = 15, lng2 = -65, lat2 = 72)
  })

  observe({
    req(county_data(), county_polygons())

    counties <- county_data()
    polys <- county_polygons()

    # Join data with polygons
    counties <- counties |>
      left_join(polys, by = "fips")

    # Determine variable and colors
    if (input$view == "Population") {
      fill_var <- counties$population
      pal <- colorNumeric("YlOrRd", domain = fill_var, na.color = "#808080")
      legend_title <- "Population"
      legend_values <- fill_var
    } else if (input$view == "No. of Hospitals") {
      fill_var <- counties$hospitals
      pal <- colorNumeric("YlGnBu", domain = fill_var, na.color = "#808080")
      legend_title <- "Hospitals"
      legend_values <- fill_var
    } else {
      # Model view
      fill_var <- counties$pred_status
      pal <- colorFactor(
        palette = c("above" = "#0072B2", "below" = "#CC79A7", "ok" = "#009E73"),
        domain = c("above", "below", "ok"),
        na.color = "#808080"
      )
      legend_title <- "Model Status"
      legend_values <- c("above", "below", "ok")
    }

    # Start with clearing existing shapes
    map_proxy <- leafletProxy("map") |>
      clearShapes() |>
      clearControls()

    # Add polygons for each county
    for (i in seq_len(nrow(counties))) {
      county <- counties[i, ]

      if (!is.null(county$longs[[1]]) && length(county$longs[[1]]) > 0) {
        # Create label
        label <- sprintf(
          "<strong>%s, %s</strong><br/>Population: %s<br/>Hospitals: %s",
          county$county_name,
          county$state,
          format(county$population, big.mark = ","),
          county$hospitals
        ) |>
          htmltools::HTML()

        # Get color for this county
        if (input$view == "Model") {
          color <- pal(county$pred_status)
        } else {
          color <- pal(fill_var[i])
        }

        # Add each polygon piece for this county
        for (j in seq_along(county$longs[[1]])) {
          lng_vec <- unlist(county$longs[[1]][[j]])
          lat_vec <- unlist(county$lats[[1]][[j]])

          if (length(lng_vec) > 0 && length(lat_vec) > 0) {
            map_proxy <- map_proxy |>
              addPolygons(
                lng = lng_vec,
                lat = lat_vec,
                fillColor = color,
                fillOpacity = 0.5,
                weight = 1,
                color = "white",
                opacity = 1,
                highlightOptions = highlightOptions(
                  weight = 2,
                  color = "#666",
                  fillOpacity = 0.9,
                  bringToFront = TRUE
                ),
                label = label,
                layerId = paste0(county$fips, "_", j),
                group = county$fips
              )
          }
        }
      }
    }

    # Add legend
    map_proxy |>
      addLegend(
        position = "bottomright",
        pal = pal,
        values = legend_values,
        title = legend_title,
        opacity = 0.7
      )
  })

  observeEvent(input$map_shape_click, {
    click <- input$map_shape_click

    if (!is.null(click$id)) {
      # Extract FIPS code from layerId (which may have "_1", "_2" suffix)
      fips_code <- sub("_\\d+$", "", click$id)

      sel_county <- us_hospitals |>
        filter(fips == fips_code)

      if (nrow(sel_county) > 0) {
        showModal(modalDialog(
          title = paste0(sel_county$county_name[1], ", ", sel_county$state[1]),
          sel_county |>
            arrange(city, facility_name) |>
            mutate(nbr = row_number()) |>
            select(nbr, facility_name, city) |>
            gt() |>
            cols_label(
              nbr = "",
              facility_name = "Hospital Name",
              city = "City"
            ) |>
            tab_options(table.font.size = 8),
          easyClose = TRUE,
          fade = TRUE
        ))
      }
    }
  })
}

shinyApp(ui, server)
