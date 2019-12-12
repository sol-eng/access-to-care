library(rstudioapi)
library(purrr)
library(pins)

## Makes sure that all of the needed pins are available locally
needed_pins <- c("atc-states", "atc-county-map","atc-county-table", "atc-base-map", "atc-hospitals", "atc-hospitals") 
find_pins <- map(needed_pins, pin_find, board = "local") 
matched_pins <- map_int(find_pins, nrow)
if(any(matched_pins == 0)) rmarkdown::render("RMarkdown-DataPrep/access-to-care-dataprep.Rmd")



states <- c("Alabama","Arizona","California","Colorado","Mississippi", "Texas", "Utah", "New York")
map(
  states,  
  ~ {
    launcherSubmitJob(
    name = .x,
    command = "R",
    args = c("--slave", "--no-save", "--no-restore"), 
    workingDirectory = here::here("launcher-programatic"),
    environment = c(Sys.getenv()),
    stdin = paste0("
    st <- '", .x , "'
    if(!dir.exists('reports')) dir.create('reports')
    rmarkdown::render(
      here::here('launcher-programatic/access-to-care-rmarkdown.Rmd'), 
      params = list(state = st),
      output_dir = here::here('launcher-programatic/reports'),
      output_file = tolower(st)
    )")
  )})
