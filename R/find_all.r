#' @title Find locations of all regex matches
#' @description
#' Return the start and end offsets (in bytes)
#' of all regex matches within each element of `string`.
#' @param string Character vector.
#' @param pattern Pattern to look for. For more information
#' see [here][re_pattern].
#' @param start Byte offset at which to start searching (`1`-based).
#' Default is `1` (start at the beginning of each string). The regex
#' engine may look at bytes before the start position to determine
#' match information. For example, if the start position is greater
#' than `1`, then the `"\\A"` ("begin text") anchor can never match.
#' For more information see [here][re_start].
#' @details
#' `re_find_all()` returns the offset locations of all matches.
#'
#' `re_find_all_captures()` returns the offset locations of all matches
#' as well as the offset locations of any capture groups for each match.
#'
#' Patterns must be valid UTF-8 to work with Rust's regex engine.
#' Any non-UTF-8 patterns will result in an error. `string` may contain
#' arbitrary bytes but ASCII compatible text is more useful, and UTF-8
#' is more useful still. Other text encodings are not supported.
#' @inheritSection re_find Match positions
#' @return
#' For `re_find_all()`, a list the length of `string`. Each element is
#' an integer matrix with two columns, `start` and `end`, with one row
#' per match. See **Match positions** below for the convention used by
#' `start` and `end`. No match, `NA` elements, or elements shorter than
#' the `start` argument result in `NA` in both columns.
#'
#' For `re_find_all_captures()`, a list the length of `string`. Each
#' element is a two-element list: `matches`, an integer matrix with one
#' row per match (same structure as the output of `re_find_all()`); and
#' `captures`, a list with one element per capture group, each a matrix
#' of the same structure as `matches`.
#' @seealso
#' [re_find], [re_find_shortest], and [re_find_captures] for finding
#' locations of the first match.
#'
#' [re_detect] and [re_where] to return locations of vector element matches.
#'
#' [nbytes] to get the number of bytes in each string.
#' @examples
#' fruit <- c("apple", "banana", "pear", "pineapple")
#' re_find_all(fruit, "e|a")
#' re_find_all(fruit, "e|a", start = 5)
#'
#' # 'zero'-length matches can occur
#' re_find_all("bear", "a*")
#'
#' # Match positions: start is 1-based inclusive, end is exclusive
#' re_find_all("abc", "a") # start = 1, end = 1
#' re_find_all("abc", "ab") # start = 1, end = 2
#' re_find_all("abc", "b") # start = 2, end = 2
#' re_find_all("abc", "^") # start = 1, end = 0 (empty match)
#'
#' x <- c("a=1;b=2", "c=3;d=4")
#' re_find_all_captures(x, "(?<cg_one>\\w+)=(?<cg_two>\\w+)")
#' @export
re_find_all <- function(string, pattern, start = 1L) {
  .Call(r_rure_find_all, string, pattern, start)
}

#' @rdname re_find_all
#' @export
re_find_all_captures <- function(string, pattern, start = 1L) {
  .Call(r_rure_find_all_captures, string, pattern, start)
}
