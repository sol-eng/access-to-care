library(plumber)
library(pins)
library(usmap)

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

hospitals <- pin_get("atc-county_hospitals", board = boardname) %>%
  mutate(state = as.character(state)) %>%
  inner_join(statepop, by = c("state" = "abbr")) 

#* Get the state's summarized information
#* @get /summary
#* @param state Two letter abbriviation of the state
function(state = "MS") {
  st_name <- toupper(state)
  state_data <- hospitals[hospitals$state == st_name, ]
  data.frame(
    population = sum(state_data$population),
    hospitals = sum(state_data$hospitals),
    counties = nrow(state_data),
    underserved = nrow(state_data[state_data$result == -1, ])
  )
}

#* Prediction of number of hospitals based on population
#* @get /model
#* @param population:numeric Number of people living in a given county
function(population = 70000) {
  model <- pin_get("atc-model", board = boardname) 
  pop <- as.numeric(population)
  predict(model, data.frame(population = pop))
}

#* Prediction of number of hospitals based on population
#* @get /state
#* @param state Two letter abbriviation of the state
function(state = "MS") {
  st_name <- toupper(state)
  hospitals[hospitals$state == st_name, ]
}

#* Coordinates of hospitals for a given state
#* @get /hospitals
#* @param state Two letter abbriviation of the state
function(state = "MS") {
  hospital_list <- pin_get("atc-hospital-locations", board = boardname) 
  st_name <- toupper(state)
  hospital_list[hospital_list$state == st_name, 2:3]
}
