library(rstudioapi)
library(purrr)
library(pins)

## -- Makes sure that all of the needed pins are available locally
needed_pins <- c("atc-states", "atc-county-map","atc-county-table", "atc-base-map", "atc-hospitals", "atc-hospitals") 
find_pins <- map(needed_pins, pin_find, board = "local") 
matched_pins <- map_int(find_pins, nrow)
if(any(matched_pins == 0)) rmarkdown::render("RMarkdown-DataPrep/access-to-care-dataprep.Rmd")

states <- c("Alabama","Arizona","California","Colorado","Mississippi", "Texas", "Utah", "New York")

## -- Creates a folder to process each state individually, and avoid file collisions 
working_folder <- here::here("launcher-programatic")
inter_folder <- file.path(working_folder, "intermediates")
if(dir.exists(inter_folder)) unlink(inter_folder, force = TRUE, recursive = TRUE)
dir.create(inter_folder)
state_folders <- file.path(inter_folder, states)
walk(state_folders, dir.create)

## -- Creates a Launcher job per state to create the RMarkdown report
map(
  states,  
  ~ {
    launcherSubmitJob(
      ## -- Job name, no default, it must be assigned
      name = .x,
      ## -- The type of job, in this case: R
      command = "R",
      ## -- Required args
      args = c("--slave", "--no-save", "--no-restore"), 
      ## -- Setting the job's working directory to 
      ## -- the "launcher-programatic" sub-foler
      workingDirectory = working_folder,
      ## -- Copies the local environment (required)
      environment = c(Sys.getenv()),
      ## -- The code that the job will run
      stdin = paste0("
        st <- '", .x , "'
        inter_folder <- '", inter_folder , "'
        if(!dir.exists('reports')) dir.create('reports')
        rmarkdown::render(
          here::here('launcher-programatic/access-to-care-rmarkdown.Rmd'), 
          params = list(state = st),
          output_dir = here::here('launcher-programatic/reports'),
          output_file = tolower(st),
          intermediates_dir = file.path(inter_folder, st)
        )")
  )})
