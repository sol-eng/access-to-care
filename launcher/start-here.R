library(pins)
library(rstudioapi)
library(purrr)

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


states <- pin_get("atc-states", board = boardname)

state_names <- states[1:10, "full"][[1]]

launcherSubmitJob(
  command = "R",
  environment = list(RENDER_STATE = "Alabama"),
  stdin = "source(here::here('launcher/render-rmarkdown.R'))"
)
