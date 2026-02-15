library(connectwidgets)
library(shinymaterial)
library(accesstocare)
library(stringr)
library(readr)
library(shiny)
library(dplyr)
library(fs)

rsc_content <- function() {
  connect_server <- Sys.getenv("CONNECT_SERVER")
  connect_key <- Sys.getenv("CONNECT_API_KEY")
  client <- connect(server = connect_server, api_key = connect_key)
  content(client)
}

if (Sys.getenv("R_CONFIG_ACTIVE") == "rsconnect") {
  all_content <- rsc_content()
} else {
  if (!file_exists("content.rds")) {
    all_content <- rsc_content()
    write_rds(all_content, "content.rds")
  } else {
    all_content <- read_rds("content.rds")
  }
}

choice_types <- c(
  "All", "Script", "Report", "Dashboard", "Data", "Model",
  "Notebook", "Plot", "Presentation", "Application", "API"
)

atc_content <- all_content |>
  by_tags("Access to Care")

if (nrow(atc_content) == 0) {
  atc_content <- all_content |>
    filter(grepl("access to care", tolower(title)))
}

atc_content <- atc_content |>
  mutate(
    title = str_remove(title, "Access to Care - "),
    type = case_when(
      str_detect(title, "RNotebook") ~ "Notebook",
      content_category == "pin" & str_detect(title, "Model") ~ "Model",
      content_category == "pin" ~ "Data",
      str_detect(title, " Prep") ~ "Script",
      str_detect(title, "Presentation|PowerPoint") ~ "Presentation",
      app_mode == "rmd-static" ~ "Report",
      app_mode %in% c("rmd-shiny", "python-dash", "quarto-shiny") ~ "Dashboard",
      app_mode == "static" ~ "Plot",
      app_mode == "shiny" ~ "Application",
      app_mode == "api" ~ "API",
      TRUE ~ "Other"
    ),
    language = case_when(
      str_detect(app_mode, "python") ~ "python",
      TRUE ~ "R"
    )
  )

ui <- material_page(
  title = "Access to Care",
  primary_theme_color = palette_atc$ok,
  secondary_theme_color = palette_atc$above,
  background_color = "white",
  material_parallax("hospital.jpeg"),
  fluidRow(
    absolutePanel(
      material_radio_button("type", "Content Type", choice_types),
      right = 80,
      top = 70
    )
  ),
  fluidRow(
    absolutePanel(
      material_radio_button("language", "Language", c("All", "R", "python")),
      right = 300,
      top = 70
    )
  ),
  fluidRow(
    absolutePanel(
      rsccardOutput("cards", width = "90%"),
      left = 200,
      width = "80%"
    )
  ),
  fluidRow(
    absolutePanel(
      rscgridOutput("grid", width = "90%"),
      left = 20,
      width = "80%"
    )
  ),
  fluidRow(
    absolutePanel(
      material_radio_button("view", "View:", c("Cards", "Grid")),
      right = 300,
      top = 420
    )
  )
)

server <- function(input, output, session) {
  filter_content <- reactive({
    f_content <- atc_content
    if (input$type != "All") {
      f_content <- filter(f_content, type == input$type)
    }
    if (input$language != "All") {
      f_content <- filter(f_content, language == input$language)
    }
    f_content
  })
  output$cards <- renderRsccard({
    if (input$view == "Grid") {
      return(NULL)
    }
    f_content <- filter_content()
    if (nrow(f_content) > 0) {
      rsc_card(f_content)
    } else {
      NULL
    }
  })
  output$grid <- renderRscgrid({
    if (input$view == "Cards") {
      return(NULL)
    }
    f_content <- filter_content()
    if (nrow(f_content) > 0) {
      rsc_grid(f_content)
    } else {
      NULL
    }
  })
}

shinyApp(ui = ui, server = server)
