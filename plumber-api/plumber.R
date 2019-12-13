library(plumber)
library(pins)
library(usmap)
library(dplyr)
library(tidypredict)

if(Sys.getenv("R_CONFIG_ACTIVE") == "rsconnect") {
  boardname <- "rsconnect"
  board_register_rsconnect(
    server = Sys.getenv("connect_url"),
    key = Sys.getenv("connect_key")
  )
} else {
  boardname <- "local"
  board_register(boardname)  
}

states <-pin_get("atc-states", board = boardname)  
counties <- pin_get("atc-base-map", boardname)
model <- pin_get("atc-parsed-model", board = boardname) %>%
  as_parsed_model()

#* Get the state's summarized information
#* @get /summary
#* @param state Two letter abbreviation of the state
function(state = "MS") {
  st_name <- toupper(state)
  state_data <- states[states$state == st_name, ]
  state_data
}

#* Prediction of number of hospitals based on a provided population number
#* @get /model
#* @param population:numeric Number of people living in a given county
function(population = 70000) {
  pop <- as.numeric(population)
  data.frame(population = 70000) %>%
    tidypredict_to_column(model, add_interval = TRUE)
}

#* Prediction of number of hospitals based on population
#* @get /state
#* @param state Two letter abbreviation of the state
function(state = "MS") {
  st_name <- toupper(state)
  counties[counties$state == st_name, ]
}
