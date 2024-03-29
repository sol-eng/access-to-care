sub_folder <- "RMarkdown-html"
full_path <- here::here(sub_folder)
app_files <- dir(full_path)
app_files <- app_files[app_files != "config.yml"]
app_files <- app_files[!grepl(".html", app_files)]
app_files <- app_files[!grepl(".pptx", app_files)]
primary_id <- grepl(".Rmd", app_files)
primary_doc <- "access-to-care-rmarkdown.Rmd"
rsconnect::writeManifest(
  appDir = full_path,
  appFiles = app_files,
  appPrimaryDoc = primary_doc
)
