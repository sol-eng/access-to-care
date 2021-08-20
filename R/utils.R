#' @export
format_number <- function(x, round_digits = 0) {
  res <- x
  
  res[x >= 1000] <- paste0(round(x[x >= 1000] / 1000, digits = round_digits), "K")
  res[x >= 1000000] <- paste0(round(x[x >= 1000000] / 1000000, digits = round_digits), "M")
  res[x >= 1000000000] <- paste0(round(x[x >= 1000000000] / 1000000000, digits = round_digits), "B")
  
  res
}

#' @export
format_currency <- function(x, round_digits = 0) {
  res <- format_number(
    x = x, 
    round_digits = round_digits
    )
  paste0("$", res)
}