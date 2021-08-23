#' @importFrom rsconnect writeManifest
#' @importFrom purrr map keep walk
#' @importFrom here here
#' @importFrom dplyr mutate select filter inner_join right_join
#' @importFrom crayon cyan black blue red green magenta
#' @importFrom magrittr `%>%`
#' @import ggplot2
#' @import ggiraph
#' @import rlang
#' @import fs

#' @export
write_manifest <- function(content_folder, 
                           base_folder = here("inst/content/"),
                           ignore_files = list("config.yml", ".gitignore", 
                                               "manifest.json", ".DS_Store",
                                               ".gitignore"
                                               )
                           ) {
  
  full_path <- path(base_folder, content_folder)
  
  app_files <- dir_ls(full_path, all = TRUE)
  
  app_file_names <- path_file(app_files)
  
  git_ignore <- app_files[app_file_names == ".gitignore"]
  if(length(git_ignore) > 0) {
    git_files <- readLines(git_ignore)
  } else {
    git_files <- ""
  }
  ig <- c(ignore_files, git_files)
  for(i in seq_along(ig)) {
    app_file_names <- app_file_names[app_file_names != ig[i]]
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
    app_file_names,
    ~ cat(cyan("--- ", .x, "\n"))
  )
  cat(paste0(red("Primary file: "), cyan(primary_doc, "\n")))
  cat(magenta("Compiling manifest...\n"))
  rsconnect::writeManifest(
    appDir = full_path,
    appFiles = app_file_names,
    appPrimaryDoc = primary_doc
  )
  cat(magenta("Manifest complete\n\n"))
}


