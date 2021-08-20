sub_folder <- "plumber-api"
full_path <- here::here(sub_folder)
app_files <- dir(full_path)
primary_id <- grepl("plumber.R", app_files)
if(sum(primary_id) > 1) stop("There are more then one Rmd document, please identify the proper primary doc")
primary_doc <- app_files[primary_id]
rsconnect::writeManifest(
  appDir = full_path,
  appFiles = app_files,
  appPrimaryDoc = primary_doc
)
