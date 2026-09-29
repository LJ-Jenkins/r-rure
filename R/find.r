#' @title Find locations of the first regex match
#' @description
#' Return the start and end offsets (in bytes)
#' of the first regex match within each element of `string`.
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
#' `re_find()` returns the offset locations of the first match.
#'
#' `re_find_shortest()` returns the end offset location of the first match.
#' The end location is the place at which the regex engine
#' determined that a match exists, but may occur before the end of the proper
#' leftmost-first match.
#'
#' `re_find_captures()` returns the offset locations of the first match
#' as well as the offset locations of any capture groups for that match.
#'
#' Patterns must be valid UTF-8 to work with Rust's regex engine.
#' Any non-UTF-8 patterns will result in an error. `string` may contain
#' arbitrary bytes but ASCII compatible text is more useful, and UTF-8
#' is more useful still. Other text encodings are not supported.
#' @section Match positions:
#'
#' Match positions use the following convention:
#'
#' * `start` is the **1-based** byte position of the first byte of the
#'   match.
#' * `end` is the **exclusive** end offset (0-based), i.e. the position
#'   just past the last byte of the match.
#'
#' So a match on the first byte of `"abc"` has `start = 1, end = 1`; a
#' match on the first two bytes has `start = 1, end = 2`. `end - start + 1`
#' gives the byte length of the match, and `substr(string, start, end)`
#' extracts the matched substring (for ASCII input).
#'
#' An empty match has `end == start - 1`. For example,
#' `re_find("abc", "^")` returns `start = 1, end = 0`.
#'
#' These are **byte** offsets, not character offsets. For strings
#' containing multi-byte UTF-8 characters, `start` and `end` do not
#' correspond to character positions, and **R**'s character-based string
#' functions (`substr()`, `substring()`) will not correctly extract the
#' match. See [here][re_pattern] for details.
#' @return
#' For `re_find()`, an integer matrix with two columns, `start` and
#' `end`, with one row per element of `string`. No match, `NA`
#' elements, or elements shorter than the `start` argument result in
#' `NA` in both columns. See **Match positions** below for the
#' convention used by `start` and `end`.
#'
#' For `re_find_shortest()`, an integer vector containing the end
#' offset of the first match for each element of `string`. No match
#' or `NA` elements result in `NA`.
#'
#' For `re_find_captures()`, a two-element list: `matches`, the same
#' structure as the output of `re_find()`; and `captures`, a list with
#' one element per capture group, each a matrix of the same structure
#' as `matches`.
#' @seealso
#' [re_find_all] and [re_find_all_captures] for finding locations of all
#' matches.
#'
#' [re_detect] and [re_where] to return locations of vector element matches.
#'
#' [nbytes] to get the number of bytes in each string.
#' @examples
#' fruit <- c("apple", "banana", "pear", "pineapple")
#' re_find(fruit, "e|a")
#' re_find(fruit, "e|a", start = 4)
#'
#' # 'zero'-length matches can occur
#' re_find("bear", "a*")
#'
#' # Match positions: start is 1-based inclusive, end is exclusive
#' re_find("abc", "a") # start = 1, end = 1
#' re_find("abc", "ab") # start = 1, end = 2
#' re_find("abc", "b") # start = 2, end = 2
#' re_find("abc", "^") # start = 1, end = 0 (empty match)
#'
#' x <- c("a=1;b=2", "c=3;d=4")
#' re_find_captures(x, "(?<cg_one>\\w+)=(?<cg_two>\\w+)")
#' @export
re_find <- function(string, pattern, start = 1L) {
  .Call(r_rure_find, string, pattern, start)
}

#' @rdname re_find
#' @export
re_find_shortest <- function(string, pattern, start = 1L) {
  .Call(r_rure_shortest_match_offset, string, pattern, start)
}

#' @rdname re_find
#' @export
re_find_captures <- function(string, pattern, start = 1L) {
  .Call(r_rure_find_captures, string, pattern, start)
}
