#' @title Escape regex special characters
#' @description
#' `re_escape()` returns a character vector with all regex
#' special characters escaped.
#' @param string Character vector.
#' @return A character vector the same length as `string`.
#' @details
#' Inputs must be valid UTF-8 to work with Rust's regex engine.
#' Any non-UTF-8 elements will result in an error.
#'
#' `NA` values are preserved and returned as `NA` in the
#' output - but note `NA` is not a valid pattern for rure.
#' @examples
#' re_escape(".")
#' @export
re_escape <- function(string) {
  .Call(ffi_escape, string)
}
