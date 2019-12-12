state <- Sys.getenv("RENDER_STATE")
rmarkdown::render(
  here::here("launcher/access-to-care-rmarkdown.Rmd"), 
  params = list(state = state),
  output_dir = here::here("launcher"),
  output_file = tolower(state)
)
