#' Get the number of bytes.
#' @description
#' Get the number of bytes in each string of a character vector.
#' @details
#' Simple wrapper around `nchar(x, type = "bytes")`.
#'
#' `NA` values are preserved in the output.
#' @param x A character vector.
#' @return An integer vector giving the number of bytes in each string.
#' @examples
#' nbytes(c("a", "ab", "abc"))
#' nbytes("caf\u00e9")
#' @export
nbytes <- function(x) {
  nchar(x, type = "bytes", allowNA = FALSE, keepNA = NA)
}
