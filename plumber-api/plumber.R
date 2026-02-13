library(plumber2)
library(accesstocare)

#* Prediction of number of hospitals based on a provided population number
#* @get /model
#* @param population:numeric Number of people living in a given county
function(population = 70000) {
  pop <- data.frame(population = as.numeric(population))
  pred <- predict(us_atc_model, newdata = pop, interval = "prediction")
  as.data.frame(pred)
}

#* Get the state's plot
#* @get /plot
#* @param state Two letter abbreviation of the state
#* @serializer png
function(state = "MS") {
  if (state == "PR") {
    state_name <- "Puerto Rico"
  } else {
    state_name <- state.name[state.abb == state]
  }
  st_name <- toupper(state_name)
  print(atc_plot_state_map(state_name))
}

#* Prediction of number of hospitals based on population
#* @get /state
#* @param state Two letter abbreviation of the state
function(state = "MS") {
  st_name <- toupper(state)
  st_cols <- c("county_name", "state", "hospitals", "population", "pred_status")
  us_counties[us_counties$state == st_name, st_cols]
}

#* Get the state's summarized information
#* @get /summary
#* @param state Two letter abbreviation of the state
function(state = "MS") {
  st_name <- toupper(state)
  state_data <- us_states[us_states$state == st_name, ]
  state_data
}
