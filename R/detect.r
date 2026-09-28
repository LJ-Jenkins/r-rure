#' @title Detect regex matches
#' @description
#' Return logical values indicating where regex patterns match
#' the input strings.
#' @param string Character vector.
#' @param pattern Pattern to look for (single string).
#' @param patterns Patterns to look for (character vector).
#' @details
#' `re_detect()` returns a logical vector with `TRUE` for
#' each element of `string` that matches `pattern` and `FALSE`
#' otherwise.
#'
#' `re_set_detect()` does the same for a set of
#' patterns, returning `TRUE` if **any** of the patterns match.
#'
#' `re_set_detect_each()` returns a logical matrix with one
#' row per element of `string` and one column per pattern
#' in `patterns` - showing which patterns match each string.
#'
#' `NA` values in `string` will result in `NA` in the output.
#'
#' Patterns must be valid UTF-8 to work with Rust's regex engine.
#' Any non-UTF-8 patterns will result in an error. `string` may contain
#' arbitrary bytes but ASCII compatible text is more useful, and UTF-8
#' is more useful still. Other text encodings are not supported.
#' @return For `re_detect()` and `re_set_detect()`, a logical
#' vector the same length as `string`. For
#' `re_set_detect_each()`, a logical matrix with one row per
#' element of `string` and one column per pattern in `patterns`.
#' @seealso
#' [re_where] for index return values and [re_find] for match
#' locations.
#' @examples
#' fruit <- c("apple", "banana", "pear", "pineapple")
#' re_detect(fruit, "a")
#' re_detect(fruit, "^a")
#' re_detect(fruit, "a$")
#' re_detect(fruit, "b")
#' re_detect(fruit, "[aeiou]")
#'
#' re_set_detect(fruit, c("a", "e"))
#' re_set_detect_each(fruit, c("a", "e"))
#' @export
re_detect <- function(string, pattern) {
  .Call(r_rure_is_match, string, pattern)
}

#' @rdname re_detect
#' @export
re_set_detect <- function(string, patterns) {
  .Call(r_rure_set_is_match, string, patterns)
}

#' @rdname re_detect
#' @export
re_set_detect_each <- function(string, patterns) {
  .Call(r_rure_set_is_match_each, string, patterns)
}
