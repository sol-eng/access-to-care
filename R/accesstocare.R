#' @importFrom rsconnect writeManifest
#' @importFrom purrr map keep walk
#' @importFrom here here
#' @import crayon
#' @import fs

#' @export
write_manifest <- function(content_folder, 
                           base_folder = here("inst/content/"),
                           ignore_files = list("config.yml", ".gitignore", "manifest.json")
                           ) {
  
  full_path <- path(base_folder, content_folder)
  
  app_files <- dir(full_path)
  
  for(i in seq_along(ignore_files)) {
    app_files <- app_files[app_files != ignore_files[i]]
  }

  primary_docs <- map(
    c("*.Rmd", "*.py", "*.R", "*.ipynb"),
    ~{
      dl <- dir_ls(full_path, glob = .x)
      path_file(dl)
      }
    )
  
  primary_match <- keep(
    primary_docs, 
    ~ length(.x) > 0
    )
    
  primary_doc <-  ifelse(length(primary_match) > 0, primary_match[[1]], NA) 
  
  if(is.na(primary_doc)) stop("No identifies primary doc")
  if(length(primary_match) > 1) stop("There are more then one primary doc")
  
  cat(green("Full path: ", full_path, "\n"))
  cat(red("Application files\n"))
  walk(
    app_files,
    ~ cat(cyan("--- ", .x, "\n"))
  )
  cat(paste0(red("Primary file: "), cyan(primary_doc, "\n")))
  cat(magenta("Compiling manifest...\n"))
  rsconnect::writeManifest(
    appDir = full_path,
    appFiles = app_files,
    appPrimaryDoc = primary_doc
  )
  cat(magenta("Manifest complete\n\n"))
}


