#' @export
format_number <- function(x, round_digits = 0) {
  res <- x
  if(x >= 1000) {
    res <- round(x / 1000, digits = round_digits)
    res <- paste0(res, "K")
  }
  if(x >= 1000000) {
    res <- round(x / 1000000, digits = round_digits)
    res <- paste0(res, "M")
  }
  res
  if(x >= 1000000000) {
    res <- round(x / 1000000000, digits = round_digits)
    res <- paste0(res, "B")
  }
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