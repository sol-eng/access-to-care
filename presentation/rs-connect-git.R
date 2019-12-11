sub_folder <- "presentation"
full_path <- here::here(sub_folder)
file.copy("RMarkdown-DataPrep/local.sqlite", full_path, overwrite = TRUE)
app_files <- dir(full_path)
app_files <- app_files[app_files != "config.yml"]
app_files <- app_files[!grepl(".html", app_files)]
app_files <- app_files[!grepl(".pptx", app_files)]
primary_id <- grepl(".Rmd", app_files)
if(sum(primary_id) > 1) stop("There are more then one Rmd document, please identify the proper primary doc")
primary_doc <- app_files[primary_id]
rsconnect::writeManifest(
  appDir = full_path,
  appFiles = app_files,
  appPrimaryDoc = primary_doc
)
