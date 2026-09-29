# ---------------------------------------------------------------------------
# `start` argument: byte offsets
#
# Contract:
#   * `start` is a 1-based *byte* offset.
#   * `start == 1` means "begin at the first byte".
#   * `start == nchar(x, "bytes") + 1` means "begin at the end of the string";
#     patterns that can match empty (e.g. `.*`, `a*`) still match there.
#   * `start >  nchar(x, "bytes") + 1` is past the end -> FALSE, never a crash.
#   * `NA` in the input string yields NA in the output, regardless of `start`.
# ---------------------------------------------------------------------------

test_that("start = 1 is the default (1-based byte offset)", {
  expect_identical(re_detect("abc", "b", start = 1), re_detect("abc", "b"))
  expect_true(re_detect("abc", "b", start = 1))
})

test_that("start skips matches before the offset", {
  # "abcabc": first "a" at byte 1, second at byte 4.
  expect_true(re_detect("abcabc", "a", start = 1))
  expect_true(re_detect("abcabc", "a", start = 2))
  expect_true(re_detect("abcabc", "a", start = 4))
  # No "a" at or after byte 5.
  expect_false(re_detect("abcabc", "a", start = 5))
})

test_that("start past the end returns FALSE, does not crash", {
  # Single-byte haystack, start strictly greater than len + 1.
  expect_false(re_detect("a", "a", start = 3))
  expect_false(re_detect("a", "a", start = 100))
  expect_false(re_detect("abc", "a", start = 100))
})

test_that("start == len + 1 is a legal zero-width position", {
  # `.*` matches the empty string at the end of the haystack.
  expect_true(re_detect("a", ".*", start = 2)) # byte 2 == end of "a"
  expect_true(re_detect("abc", ".*", start = 4)) # byte 4 == end of "abc"
  expect_true(re_detect("abc", "a*", start = 4))
  # A pattern that cannot match empty must not match at the end.
  expect_false(re_detect("abc", "a", start = 4))
})

test_that("start is a byte offset, not a character offset", {
  # "é" is 2 bytes in UTF-8.
  expect_true(re_detect("é", ".*", start = 1)) # byte 1 = start of é
  expect_true(re_detect("é", ".*", start = 2)) # byte 2 = second byte of é
  expect_true(re_detect("é", ".*", start = 3)) # byte 3 = end of é
  expect_false(re_detect("é", ".*", start = 4)) # past end

  # A pattern that only matches the full 2-byte character.
  expect_true(re_detect("é", "é", start = 1))
  expect_false(re_detect("é", "é", start = 2))
  expect_true(re_detect("é", "é*", start = 2)) # still matches: engine starts
  # at byte 2 but can look left
  expect_false(re_detect("é", "é", start = 3))
})

test_that("start applies uniformly across all elements", {
  x <- c("abc", "xabc", "xxabc")
  expect_identical(re_detect(x, "a", start = 2), c(FALSE, TRUE, TRUE))
  expect_identical(re_detect(x, "a", start = 3), c(FALSE, FALSE, TRUE))
  expect_identical(re_detect(x, "a", start = 4), c(FALSE, FALSE, FALSE))
})

test_that("start handles strings shorter than the offset", {
  x <- c("a", "abc", "abcdef")
  # start = 5 is past "a" and "abc", within "abcdef".
  expect_identical(re_detect(x, ".*", start = 5), c(FALSE, FALSE, TRUE))
  # start = 2 is past nothing for "a" (2 == len+1) -> empty match.
  expect_identical(re_detect(x, ".*", start = 2), c(TRUE, TRUE, TRUE))
})

test_that("NA in string propagates to NA regardless of start", {
  x <- c("abc", NA_character_, "def")
  expect_identical(re_detect(x, "a", start = 1), c(TRUE, NA, FALSE))
  expect_identical(re_detect(x, "a", start = 2), c(FALSE, NA, FALSE))
  expect_identical(re_detect(x, "a", start = 100), c(FALSE, NA, FALSE))
})

test_that("empty input with start gives empty output", {
  expect_identical(re_detect(character(0), "a", start = 1), logical(0))
  expect_identical(re_detect(character(0), "a", start = 5), logical(0))
})

test_that("start must be a single non-NA positive integer", {
  expect_error(re_detect("abc", "a", start = NA))
  expect_error(re_detect("abc", "a", start = 0))
  expect_error(re_detect("abc", "a", start = -1))
  expect_error(re_detect("abc", "a", start = c(1, 2)))
  expect_error(re_detect("abc", "a", start = character(0)))
  expect_no_error(re_detect("abc", "a", start = "1")) # coerces
  expect_error(re_detect("abc", "a", start = NULL))
})

test_that("start interacts with anchors as documented by rure", {
  # `\A` only matches when start == 0 (i.e. R start == 1).
  expect_true(re_detect("abc", "\\Aabc", start = 1))
  expect_false(re_detect("abc", "\\Aabc", start = 2))
  # `^` under default flags is like \A here.
  expect_true(re_detect("abc", "^abc", start = 1))
  expect_false(re_detect("abc", "^abc", start = 2))
  # `$` and `\z` still see the true end of the haystack.
  expect_true(re_detect("abc", "abc\\z", start = 1))
  expect_true(re_detect("abc", "abc$", start = 1))
})

test_that("start + NA in string for re_set_detect_each", {
  x <- c("abc", NA_character_, "adef")
  m <- re_set_detect_each(x, c("a", "d"), start = 2)
  expect_identical(
    m,
    matrix(
      c(
        FALSE, NA, FALSE,
        FALSE, NA, TRUE
      ),
      nrow = 3
    )
  )
})

test_that("re_find_all skips matches before start", {
  x <- "abcabc"
  expect_identical(re_find_all(x, "a", start = 1)[[1L]], expected_mat(c(1L, 4L), c(1L, 4L)))
  expect_identical(re_find_all(x, "a", start = 2)[[1L]], expected_mat(4L, 4L))
  expect_identical(re_find_all(x, "a", start = 5)[[1L]], expected_mat(NA_integer_, NA_integer_))
})
