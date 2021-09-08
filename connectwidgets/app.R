library(shiny)
library(connectwidgets)
library(shinymaterial)
library(dplyr)
library(stringr)
library(fs)
library(readr)
library(accesstocare)


if (Sys.getenv("R_CONFIG_ACTIVE") == "rsconnect") {
  connect_server <- Sys.getenv("CONNECT_SERVER")
  connect_key <- Sys.getenv("CONNECT_API_KEY")
  client <- connect(server = connect_server, api_key = connect_key)
  all_content <- content(client)
} else {
  if (!file_exists("content.rds")) {
    connect_server <- Sys.getenv("CONNECT_SERVER")
    connect_key <- Sys.getenv("CONNECT_API_KEY")
    client <- connect(server = connect_server, api_key = connect_key)
    all_content <- content(client)
    write_rds(all_content, "content.rds")
  } else {
    all_content <- read_rds("content.rds")
  }
}

choice_types <- c(
  "All", "Script", "Report", "Dashboard", "Data", "Model",
  "Notebook", "Plot", "Presentation"
)

atc_content <- all_content %>%
  by_tags("Access to Care") %>%
  mutate(
    title = str_remove(title, "Access to Care - "),
    type = case_when(
      str_detect(title, "Jupyter|RNotebook") ~ "Notebook",
      content_category == "pin" & str_detect(title, "Model") ~ "Model",
      content_category == "pin" ~ "Data",
      str_detect(title, " Prep") ~ "Script",
      str_detect(title, "Presentation|PowerPoint") ~ "Presentation",
      app_mode == "rmd-static" ~ "Report", 
      app_mode %in% c("rmd-shiny", "python-dash") ~ "Dashboard",
      app_mode == "static" ~ "Plot", 
      TRUE ~ "Other"
    ),
    language = case_when(
      str_detect(title, "Jupyter") ~ "python",
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
  )
)

server <- function(input, output, session) {
  output$cards <- renderRsccard({
    fa <- atc_content

    if (input$type != "All") fa <- filter(fa, type == input$type)

    if (input$language != "All") fa <- filter(fa, language == input$language)

    if (nrow(fa) > 0) {
      rsc_card(fa)
    } else {
      NULL
    }
  })
}
shinyApp(ui = ui, server = server)
