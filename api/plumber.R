library(plumber)
library(readr)

model <- read_rds("model.rds")
hospitals <- read_rds("hospitals.rds")
hospital_list <- read_rds("hospital_list.rds")

#' Prediction of number of hospitals based on population
#' @get /model
#' @param population:numeric Number of people living in a given county
function(population = 70000) {
  pop <- as.numeric(population)
  predict(model, data.frame(population = pop))
}

#' Prediction of number of hospitals based on population
#' @get /state
#' @param state Two letter abbriviation of the state
function(state = "MS") {
  st_name <- toupper(state)
  hospitals[hospitals$state == st_name, ]
}

#' Coordinates of hospitals for a given state
#' @get /hospitals
#' @param state Two letter abbriviation of the state
function(state = "MS") {
  st_name <- toupper(state)
  hospital_list[hospital_list$state == st_name, 2:3]
}

import_files <- function() {
  source_files <- fs::dir_ls("data", glob = "*.rds")
  fs::file_copy(source_files, new_path = "./api", overwrite = TRUE)
}
# myapi <- plumber::plumb("plumber.R")
# myapi$run()
