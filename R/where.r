#' @title Find elements where regex match occurs
#' @description
#' Return the indices of elements in `string` that match
#' regex patterns.
#' @param string Character vector.
#' @param pattern Pattern to look for (single string).
#' @param patterns Patterns to look for (character vector).
#' @details
#' `re_where()` returns the indices of elements in `string`
#' that match `pattern`.
#'
#' `re_set_where()` does the same for a set of patterns,
#' returning indices of elements in `string` where
#' **any** of the patterns match.
#'
#' `re_set_where_each()` returns a list of integer vectors,
#' where each list element corresponds to a pattern in `patterns`
#' and is filled with the indices of elements in `string`
#' that match the corresponding pattern.
#'
#' No matches will result in an empty integer vector. For
#' `re_set_where_each()`, this will result in a list of empty
#' integer vectors.
#'
#' Patterns must be valid UTF-8 to work with Rust's regex engine.
#' Any non-UTF-8 patterns will result in an error.
#' @return For `re_set_where()` and `re_set_where_each()`, an
#' integer vector. For `re_set_where_each()`, a list the length
#' of `patterns` with each element containing an integer vector.
#' @seealso [re_detect] for logical return values.
#' @examples
#' fruit <- c("apple", "banana", "pear", "pineapple")
#' re_where(fruit, "a")
#' re_where(fruit, "^a")
#' re_where(fruit, "a$")
#' re_where(fruit, "b")
#' re_where(fruit, "[aeiou]")
#'
#' re_set_where(fruit, c("a", "e"))
#' re_set_where_each(fruit, c("a", "e"))
#' @export
re_where <- function(string, pattern) {
  .Call(ffi_is_match_inds, string, pattern)
}

#' @rdname re_where
#' @export
re_set_where <- function(string, patterns) {
  .Call(ffi_set_is_match_inds, string, patterns)
}

#' @rdname re_where
#' @export
re_set_where_each <- function(string, patterns) {
  .Call(ffi_set_is_match_inds_each, string, patterns)
}
