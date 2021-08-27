library(accesstocare)
library(ggiraph)
library(dplyr)
library(gt)

state_choices <- c( "Model", "No. of Hospitals", "Population")

ui <- fillPage(
  fillCol(
    girafeOutput("map")
  ),
  fixedPanel(
    top = 50, 
    right = 50, 
    width = 300,
    height = 300,
    div(
      style="background: #ffffcc; opacity: 0.7;",
      radioButtons(
        inputId = "view",
        label = "Select a view:",
        choices = state_choices
      )
    ),
    draggable = TRUE
  )
)

server <- function(input, output, session) {
  output$map <- renderGirafe({
    
    if(input$view == "Population") vr <- "population"
    if(input$view == "No. of Hospitals") vr <- "hospitals"
    if(input$view == "Model") vr <- "model"
    
    gp <- atc_plot_state_map(
      "All US", 
      variable = vr, 
      top_cities = 0
      )   
    girafe(
      ggobj = gp,
      width = 10, 
      height = 5,
      options = list(
        opts_selection(type = "single", only_shiny = FALSE),
        opts_tooltip(opacity = 0.7)
      )
    )  
  })
  
  observeEvent(input$map_selected, {
    sel_county <- us_hospitals %>% 
      filter(fips == input$map_selected) 
    
    showModal(modalDialog(
      title = paste0(sel_county$county_name[1], ", ", sel_county$state[1]),
      sel_county %>% 
        arrange(city, facility_name) %>%
        mutate(nbr = row_number()) %>% 
        select(nbr, facility_name, city) %>% 
        gt() %>% 
        cols_label(
          nbr = "",
          facility_name = "Hospital Name",
          city = "City"
          ) %>% 
        tab_options(table.font.size = 8),
      easyClose = TRUE, 
      fade = TRUE
    ))
  })  
}

shinyApp(ui, server)