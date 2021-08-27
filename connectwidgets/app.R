library(shiny)
library(shinymaterial)
library(connectwidgets)
library(dplyr)
library(stringr)

connect_server <- Sys.getenv("CONNECT_SERVER")
connect_key <- Sys.getenv("CONNECT_API_KEY")

client <- connect(server  = connect_server, api_key = connect_key)

# Pull data from RStudio Connect
all_content <- content(client) 

atc_content <- all_content %>% 
  by_tags("Access to Care") %>% 
  mutate(title = str_remove(title, "Access to Care - ")) 

# Wrap shinymaterial apps in material_page
ui <- material_page(
  title = "Basic Page",
  tags$h1("Page Content"),
  rsccardOutput("content")
)

server <- function(input, output) {
  output$content <- renderRsccard(rsc_card(atc_content))
}
shinyApp(ui = ui, server = server)