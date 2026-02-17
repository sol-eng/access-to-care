library(shiny)
library(accesstocare)
library(leaflet)
library(dplyr)
library(gt)
library(bslib)

state_choices <- c("Model", "No. of Hospitals", "Population")

# Define custom theme matching Quarto dashboard
custom_theme <- bs_theme(
  version = 5,
  bg = "#ffffff",
  fg = "#2c3e50",
  primary = "#0357b8",
  secondary = "#5b9bd5",
  success = "#009E73",
  info = "#0072B2",
  warning = "#FFA500",
  danger = "#CC79A7",
  base_font = font_google("Open Sans"),
  heading_font = font_google("Open Sans", wght = "600")
)

# Custom CSS to match Quarto dashboard styling
custom_css <- tags$style(HTML("
  @import url('https://fonts.googleapis.com/css2?family=Open+Sans:wght@300;400;600;700&display=swap');

  .control-panel {
    background: #ffffff;
    border: 1px solid #d4e6f1;
    border-radius: 8px;
    box-shadow: 0 2px 6px rgba(0,0,0,0.1);
    padding: 0;
    overflow: hidden;
  }

  .control-panel-header {
    background: linear-gradient(135deg, #0357b8 0%, #5b9bd5 100%);
    color: white;
    padding: 1rem 1.5rem;
    border-bottom: 2px solid #0357b8;
  }

  .control-panel-header h3 {
    font-weight: 600;
    margin: 0;
    font-size: 1.25rem;
  }

  .control-panel-body {
    background: #e8f4fd;
    padding: 1.5rem;
  }

  .control-panel-body label {
    color: #2c3e50;
    font-weight: 600;
    margin-bottom: 0.5rem;
  }

  .radio-group .form-check {
    margin-bottom: 0.5rem;
  }

  .form-check-input:checked {
    background-color: #0357b8;
    border-color: #0357b8;
  }

  .form-check-input:focus {
    border-color: #0357b8;
    box-shadow: 0 0 0 0.2rem rgba(3, 87, 184, 0.15);
  }

  .source-panel {
    background: white;
    padding: 0.75rem 1rem;
    border-radius: 6px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    border: 1px solid #d4e6f1;
  }

  .source-panel p {
    margin: 0;
    font-size: 0.85em;
    color: #2c3e50;
  }

  .modal-content {
    border-radius: 8px;
    border: 2px solid #d4e6f1;
  }

  .modal-header {
    background: linear-gradient(135deg, #0357b8 0%, #5b9bd5 100%);
    color: white;
    border-bottom: none;
    border-radius: 8px 8px 0 0;
    padding: 1rem 1.5rem;
  }

  .modal-title {
    font-weight: 600;
    color: white;
  }

  .modal-header .btn-close {
    filter: brightness(0) invert(1);
  }

  .modal-body {
    padding: 1.5rem;
  }

  /* GT table styling */
  .gt_table {
    font-family: 'Open Sans', sans-serif;
  }

  .gt_col_heading {
    background-color: #e8f4fd;
    color: #2c3e50;
    font-weight: 600;
  }

  .gt_row {
    border-bottom: 1px solid #d4e6f1;
  }

  .leaflet-control {
    border-radius: 6px;
    border: 1px solid #d4e6f1;
  }
"))

ui <- page_fillable(
  theme = custom_theme,
  custom_css,
  leafletOutput("map", width = "100%", height = "100%"),
  absolutePanel(
    top = 10,
    right = 10,
    width = 300,
    height = "auto",
    div(
      class = "control-panel",
      div(
        class = "control-panel-header",
        h3("Access to Hospital Care")
      ),
      div(
        class = "control-panel-body",
        radioButtons(
          inputId = "view",
          label = "Select a view:",
          choices = state_choices,
          selected = state_choices[1]
        )
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
      class = "source-panel",
      p(
        em("Sources: Centers of Medicine & Medicaid services (2025), and US Census Bureau (2024).")
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
