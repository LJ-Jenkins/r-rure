#' @title Find elements where a regex match occurs
#' @description
#' Return the indices of elements in `string` that match
#' regex patterns.
#' @param string Character vector.
#' @param pattern,patterns Pattern/s to look for. For more information
#' see [here][re_pattern].
#' @param start Byte offset at which to start searching (`1`-based).
#' Default is `1` (start at the beginning of each string). The regex
#' engine may look at bytes before the start position to determine
#' match information. For example, if the start position is greater
#' than `1`, then the `"\\A"` ("begin text") anchor can never match.
#' For more information see [here][re_start].
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
#' Any non-UTF-8 patterns will result in an error. `string` may contain
#' arbitrary bytes but ASCII compatible text is more useful, and UTF-8
#' is more useful still. Other text encodings are not supported.
#'
#' `re_where()` uses `rure_shortest_match` internally, which is faster
#' on short strings than `rure_is_match`. The two return identical results.
#' The set functions (`re_set_where()`, and `re_set_where_each()`) use
#' `rure_set_is_match`, because `rure` does not expose a
#' shortest-match variant for sets.
#' @return For `re_set_where()` and `re_set_where_each()`, an
#' integer vector. For `re_set_where_each()`, a list the length
#' of `patterns` with each element containing an integer vector.
#' @note
#' Patterns that can match the empty string (such as `"a*"`) return
#' the index for every element of `string`, since a zero-length match
#' occurs at the start of every string. Zero-length matches are
#' treated as valid matches.
#' @seealso
#' [re_detect] for logical return values and [re_find] for match
#' locations.
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
#'
#' # Zero-length matches count as matches
#' re_where(c("bear", "cat", ""), "a*") # all indexes
#'
#' # Out-of-range start yields FALSE, even for patterns that match empty
#' # strings. Here start = 5 lands on the empty suffix for "bear" (4 bytes),
#' # but is out of range for "cat" (3 bytes) and "" (0 bytes).
#' re_where(c("bear", "cat", ""), "a*", start = 5L) # only 1L
#' @export
re_where <- function(string, pattern, start = 1L) {
  .Call(r_rure_shortest_match_inds, string, pattern, start)
}

#' @rdname re_where
#' @export
re_set_where <- function(string, patterns, start = 1L) {
  .Call(r_rure_set_is_match_inds, string, patterns, start)
}

#' @rdname re_where
#' @export
re_set_where_each <- function(string, patterns, start = 1L) {
  .Call(r_rure_set_is_match_inds_each, string, patterns, start)
}
