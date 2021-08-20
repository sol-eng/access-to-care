sub_folder <- "jupyter"
full_path <- here::here(sub_folder)
app_files <- dir(full_path)
primary_id <- grepl("access-to-care.html", app_files)
primary_doc <- app_files[primary_id]
rsconnect::writeManifest(
  appDir = full_path,
  appFiles = primary_doc,
  appPrimaryDoc = primary_doc
)
