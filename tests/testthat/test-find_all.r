test_that("re_find_all returns a list the length of string", {
  fruit <- c("apple", "banana", "pear", "pineapple")
  res <- re_find_all(fruit, "ap")
  expect_type(res, "list")
  expect_length(res, length(fruit))
})

test_that("re_find_all elements are 2-column integer matrices", {
  res <- re_find_all(c("apple", "banana"), "a")
  for (m in res) {
    expect_true(is.matrix(m))
    expect_type(m, "integer")
    expect_identical(ncol(m), 2L)
    expect_identical(colnames(m), c("start", "end"))
    expect_null(rownames(m))
  }
})

# ---------------------------------------------------------------------------
# re_find_all: correct spans
# ---------------------------------------------------------------------------

test_that("re_find_all returns all matches within an element", {
  # "banana": a at 2, 4, 6
  res <- re_find_all("banana", "a")
  expect_identical(
    res[[1]],
    expected_mat(c(2L, 4L, 6L), c(2L, 4L, 6L))
  )
})

test_that("re_find_all returns all matches of a multi-char pattern", {
  # "an" in "banana": at 2-3 and 4-5
  res <- re_find_all("banana", "an")
  expect_identical(
    res[[1]],
    expected_mat(c(2L, 4L), c(3L, 5L))
  )
})

test_that("re_find_all returns a single-row matrix for one match", {
  res <- re_find_all("apple", "ap")
  expect_identical(res[[1]], expected_mat(1L, 2L))
})

test_that("re_find_all includes the trailing empty match for '.*'", {
  res <- re_find_all("apple", ".*")
  expect_identical(
    res[[1]],
    expected_mat(c(1L, 6L), c(5L, 5L))
  )
})

test_that("re_find_all is vectorized over string", {
  fruit <- c("apple", "banana", "pear", "pineapple")
  res <- re_find_all(fruit, "ap")
  expect_identical(res[[1]], expected_mat(1L, 2L))
  expect_identical(res[[2]], expected_mat(NA_integer_, NA_integer_))
  expect_identical(res[[3]], expected_mat(NA_integer_, NA_integer_))
  expect_identical(res[[4]], expected_mat(5L, 6L))
})

test_that("re_find_all reports byte offsets for multibyte matches", {
  # c, a, f, space, c, a, f = 7 single-byte ASCII characters
  # é = 2 bytes in UTF-8 (bytes 0xC3 0xA9)
  # Total byte length: 7 + 4 = 11 bytes; nchar(s,"bytes") == 11

  # c(1, 1) a(1, 2) f(1, 3) é(2, 5)
  # " "(1, 6)
  # c(1, 7) a(1, 8) f(1, 9) é(2, 11)
  s <- "caf\u00e9 caf\u00e9"
  res <- re_find_all(s, "caf\u00e9")
  expect_identical(
    res[[1]],
    expected_mat(c(1L, 7L), c(5L, 11L))
  )
})

# ---------------------------------------------------------------------------
# re_find_all: no match
# ---------------------------------------------------------------------------

test_that("re_find_all returns an NA-row matrix for no match", {
  res <- re_find_all("apple", "zzz")
  expect_identical(res[[1]], expected_mat(NA_integer_, NA_integer_))
})

test_that("re_find_all returns NA-row matrix for empty string non-empty pattern", {
  res <- re_find_all("", "a")
  expect_identical(res[[1]], expected_mat(NA_integer_, NA_integer_))
})

test_that("re_find_all no-match matrix still has correct dimnames", {
  res <- re_find_all("apple", "zzz")
  expect_identical(colnames(res[[1]]), c("start", "end"))
  expect_null(rownames(res[[1]]))
})

# ---------------------------------------------------------------------------
# re_find_all: NA handling
# ---------------------------------------------------------------------------

test_that("re_find_all returns NA-row matrix for NA_STRING elements", {
  res <- re_find_all(NA_character_, "a")
  expect_identical(res[[1]], expected_mat(NA_integer_, NA_integer_))
})

test_that("re_find_all mixes matches and NA elements", {
  x <- c("banana", NA, "apple", NA)
  res <- re_find_all(x, "a")
  expect_identical(
    res[[1]],
    expected_mat(c(2L, 4L, 6L), c(2L, 4L, 6L))
  )
  expect_identical(res[[2]], expected_mat(NA_integer_, NA_integer_))
  expect_identical(res[[3]], expected_mat(1L, 1L))
  expect_identical(res[[4]], expected_mat(NA_integer_, NA_integer_))
})

# ---------------------------------------------------------------------------
# re_find_all: zero-length input
# ---------------------------------------------------------------------------

test_that("re_find_all returns an empty list for empty character vector", {
  res <- re_find_all(character(0), "a")
  expect_type(res, "list")
  expect_length(res, 0L)
})

# ---------------------------------------------------------------------------
# re_find_all: start argument
# ---------------------------------------------------------------------------

test_that("re_find_all start skips earlier matches", {
  # "banana": a at 2, 4, 6; start = 3 skips the one at 2
  res <- re_find_all("banana", "a", start = 3L)
  expect_identical(
    res[[1]],
    expected_mat(c(4L, 6L), c(4L, 6L))
  )
})

test_that("re_find_all start at exactly a match position includes it", {
  res <- re_find_all("banana", "a", start = 2L)
  expect_identical(
    res[[1]],
    expected_mat(c(2L, 4L, 6L), c(2L, 4L, 6L))
  )
})

test_that("re_find_all start beyond all matches returns NA-row matrix", {
  res <- re_find_all("apple", "a", start = 2L)
  expect_identical(res[[1]], expected_mat(NA_integer_, NA_integer_))
})

test_that("re_find_all start beyond string length does not abort", {
  res <- re_find_all("apple", "a", start = 100L)
  expect_identical(res[[1]], expected_mat(NA_integer_, NA_integer_))
})

test_that("re_find_all start applies uniformly across elements", {
  x <- c("apple", "banana", "pear")
  res <- re_find_all(x, "a", start = 2L)
  expect_identical(res[[1]], expected_mat(NA_integer_, NA_integer_))
  expect_identical(
    res[[2]],
    expected_mat(c(2L, 4L, 6L), c(2L, 4L, 6L))
  )
  expect_identical(res[[3]], expected_mat(3L, 3L))
})

# ---------------------------------------------------------------------------
# re_find_all: overlapping and adjacent matches
# ---------------------------------------------------------------------------

test_that("re_find_all does not return overlapping matches", {
  # "aaaa" with "aa": non-overlapping -> at 1-2 and 3-4
  res <- re_find_all("aaaa", "aa")
  expect_identical(
    res[[1]],
    expected_mat(c(1L, 3L), c(2L, 4L))
  )
})

test_that("re_find_all returns adjacent matches", {
  # "abab" with "ab": at 1-2 and 3-4
  res <- re_find_all("abab", "ab")
  expect_identical(
    res[[1]],
    expected_mat(c(1L, 3L), c(2L, 4L))
  )
})

# ---------------------------------------------------------------------------
# re_find_all: error handling
# ---------------------------------------------------------------------------

test_that("re_find_all errors on non-string pattern", {
  expect_error(re_find_all("abc", 1L), "pattern")
})

test_that("re_find_all errors on length != 1 pattern", {
  expect_error(re_find_all("abc", c("a", "b")), "pattern")
})

test_that("re_find_all errors on NA pattern", {
  expect_error(re_find_all("abc", NA_character_), "pattern")
})

test_that("re_find_all errors on empty pattern", {
  expect_error(re_find_all("abc", ""), "pattern")
})

test_that("re_find_all errors on non-character string", {
  expect_error(re_find_all(1:3, "a"), "string")
})

test_that("re_find_all errors on non-integer start", {
  expect_error(re_find_all("abc", "a", start = list(1)), "start")
})

test_that("re_find_all errors on start < 1", {
  expect_error(re_find_all("abc", "a", start = 0L), "start")
})

# ---------------------------------------------------------------------------
# re_find_all: capturing groups do not change output
# ---------------------------------------------------------------------------

test_that("re_find_all capturing groups do not affect output", {
  expect_identical(
    re_find_all("banana", "(an)"),
    re_find_all("banana", "an")
  )
})
