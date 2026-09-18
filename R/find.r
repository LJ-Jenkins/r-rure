#' @title Find regex matches
#' @description
#' Return the indices of elements in `string` that match
#' regex patterns.
#' @param string Character vector.
#' @param pattern Pattern to look for (single string).
#' @param patterns Patterns to look for (character vector).
#' @details
#' `re_find()` returns the indices of elements in `string`
#' that match `pattern`.
#'
#' `re_set_find()` does the same for a set of patterns,
#' returning indices of elements in `string` where
#' **any** of the patterns match.
#'
#' `re_set_find_each()` returns a list of integer vectors,
#' where each list element corresponds to a pattern in `patterns`
#' and is filled with the indices of elements in `string`
#' that match the corresponding pattern.
#'
#' No matches will result in an empty integer vector. For
#' `re_set_find_each()`, this will result in a list of empty
#' integer vectors.
#' @return For `re_set_find()` and `re_set_find_each()`, an
#' integer vector. For `re_set_find_each()`, a list the length
#' of `patterns` with each element containing an integer vector.
#' @seealso [re_detect] for logical return values.
#' @examples
#' fruit <- c("apple", "banana", "pear", "pineapple")
#' re_find(fruit, "a")
#' re_find(fruit, "^a")
#' re_find(fruit, "a$")
#' re_find(fruit, "b")
#' re_find(fruit, "[aeiou]")
#'
#' re_set_find(fruit, c("a", "e"))
#' re_set_find_each(fruit, c("a", "e"))
#' @export
re_find <- function(string, pattern) {
  .Call(ffi_re_find, string, pattern)
}

#' @rdname re_find
#' @export
re_set_find <- function(string, patterns) {
  .Call(ffi_re_set_find, string, patterns)
}

#' @rdname re_find
#' @export
re_set_find_each <- function(string, patterns) {
  .Call(ffi_re_set_find_each, string, patterns)
}
