#' List of US Counties 

#' @format A tibble with 9 rows and 3,142 variables:
#' \describe{
#' \item{fips}{County FIPS}
#' \item{state}{Two letter state abbriviation}
#' \item{county_name}{Name of the county}
#' \item{hospitals}{Number of hospitals inside the county}
#' \item{population}{Population count estimate for 2015}
#' \item{pred_fit}{Fit result from model}
#' \item{pred_lwr}{Lower end of prediction from model}
#' \item{pred_upr}{Top end of prediction from model}
#' \item{pred_status}{ok = If above lower end, and below upper end, above = Above upper end, bellow = Bellow lower end}
#' }

"us_counties"