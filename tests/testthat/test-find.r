expected_mat <- function(start, end) {
  m <- cbind(start = as.integer(start), end = as.integer(end))
  dimnames(m) <- list(NULL, c("start", "end"))
  m
}

test_that("re_find returns a 2-column integer matrix with correct dimnames", {
  res <- re_find("apple", "ap")
  expect_true(is.matrix(res))
  expect_type(res, "integer")
  expect_identical(dim(res), c(1L, 2L))
  expect_identical(colnames(res), c("start", "end"))
  expect_null(rownames(res))
})

test_that("re_find finds a match at the start of a string", {
  expect_identical(
    re_find("apple", "ap"),
    expected_mat(1L, 2L)
  )
})

test_that("re_find finds a match in the middle of a string", {
  # "banana":  b a n a n a
  #            1 2 3 4 5 6
  # "an" first matches at positions 2-3
  expect_identical(
    re_find("banana", "an"),
    expected_mat(2L, 3L)
  )
})

test_that("re_find finds a match at the end of a string", {
  expect_identical(
    re_find("apple", "le"),
    expected_mat(4L, 5L)
  )
})

test_that("re_find finds the full string when pattern matches everything", {
  expect_identical(
    re_find("apple", ".*"),
    expected_mat(1L, 5L)
  )
})

test_that("re_find returns leftmost match, not longest", {
  # "aaaa": leftmost match of "a+" is the whole run
  expect_identical(
    re_find("aaaa", "a+"),
    expected_mat(1L, 4L)
  )
  # "aXaa": leftmost is the single "a" at position 1
  expect_identical(
    re_find("aXaa", "a+"),
    expected_mat(1L, 1L)
  )
})

# ---------------------------------------------------------------------------
# No match
# ---------------------------------------------------------------------------

test_that("re_find returns NA for no match", {
  expect_identical(
    re_find("apple", "zzz"),
    expected_mat(NA_integer_, NA_integer_)
  )
})

test_that("re_find returns NA for empty input element with non-empty pattern", {
  expect_identical(
    re_find("", "a"),
    expected_mat(NA_integer_, NA_integer_)
  )
})

# ---------------------------------------------------------------------------
# NA handling
# ---------------------------------------------------------------------------

test_that("re_find returns NA for NA_STRING elements", {
  expect_identical(
    re_find(NA_character_, "a"),
    expected_mat(NA_integer_, NA_integer_)
  )
})

test_that("re_find mixes real matches and NA elements", {
  x <- c("apple", NA, "banana", NA)
  res <- re_find(x, "an")
  expect_identical(
    res,
    expected_mat(
      start = c(NA_integer_, NA_integer_, 2L, NA_integer_),
      end   = c(NA_integer_, NA_integer_, 3L, NA_integer_)
    )
  )
})

# ---------------------------------------------------------------------------
# Vectorization
# ---------------------------------------------------------------------------

test_that("re_find is vectorized over string", {
  fruit <- c("apple", "banana", "pear", "pineapple")
  res <- re_find(fruit, "ap")
  expect_identical(
    res,
    expected_mat(
      start = c(1L, NA_integer_, NA_integer_, 5L),
      end   = c(2L, NA_integer_, NA_integer_, 6L)
    )
  )
})

test_that("re_find preserves order and length of string", {
  x <- c("zzz", "aaa", "mmm", "aaa")
  res <- re_find(x, "a")
  expect_identical(nrow(res), length(x))
  expect_identical(res[, "start"], c(NA_integer_, 1L, NA_integer_, 1L))
})

# ---------------------------------------------------------------------------
# Zero-length input
# ---------------------------------------------------------------------------

test_that("re_find returns a 0x2 matrix for empty character vector", {
  res <- re_find(character(0), "a")
  expect_true(is.matrix(res))
  expect_type(res, "integer")
  expect_identical(dim(res), c(0L, 2L))
  expect_identical(colnames(res), c("start", "end"))
  expect_null(rownames(res))
})

# ---------------------------------------------------------------------------
# start argument
# ---------------------------------------------------------------------------

test_that("start = 1 is the default and equivalent to omitting it", {
  expect_identical(
    re_find("banana", "an"),
    re_find("banana", "an", start = 1L)
  )
})

test_that("start skips earlier matches", {
  # "banana": first "a" at 2, next "a" at 4, next at 6
  expect_identical(
    re_find("banana", "a", start = 3L),
    expected_mat(4L, 4L)
  )
})

test_that("start at exactly the match position works", {
  expect_identical(
    re_find("banana", "a", start = 2L),
    expected_mat(2L, 2L)
  )
})

test_that("start beyond the only match returns NA", {
  expect_identical(
    re_find("apple", "ap", start = 2L),
    expected_mat(NA_integer_, NA_integer_)
  )
})

test_that("start equal to string length + 1 is allowed (empty tail)", {
  # "apple" is length 5; start = 6 means search the empty tail.
  # "a" cannot match the empty tail -> NA, no error/abort.
  expect_identical(
    re_find("apple", "a", start = 6L),
    expected_mat(NA_integer_, NA_integer_)
  )
})

test_that("start beyond string length returns NA, does not abort", {
  # This is the critical regression test for the rure panic.
  expect_identical(
    re_find("apple", "a", start = 100L),
    expected_mat(NA_integer_, NA_integer_)
  )
})

test_that("start applies uniformly across all elements of string", {
  x <- c("apple", "banana", "pear")
  res <- re_find(x, "a", start = 2L)
  expect_identical(
    res,
    expected_mat(
      start = c(NA_integer_, 2L, 3L),
      end   = c(NA_integer_, 2L, 3L)
    )
  )
})

test_that("start = 1 on empty string matches a pattern that can match empty", {
  expect_identical(
    re_find("", "a*", start = 1L),
    expected_mat(1L, 0L) # rure gives start=0,end=0 -> R start=1,end=0
  )
})

# ---------------------------------------------------------------------------
# Anchors and lookbehind interact with start
# ---------------------------------------------------------------------------

test_that("\\A does not match when start > 1", {
  expect_identical(
    re_find("abc", "\\Aabc"),
    expected_mat(1L, 3L)
  )
  expect_identical(
    re_find("abc", "\\Aabc", start = 2L),
    expected_mat(NA_integer_, NA_integer_)
  )
})

test_that("^ (multiline off) behaves like \\A with respect to start", {
  expect_identical(
    re_find("abc", "^abc", start = 2L),
    expected_mat(NA_integer_, NA_integer_)
  )
})

test_that("$ matches at end of string regardless of start", {
  expect_identical(
    re_find("abc", "c$", start = 3L),
    expected_mat(3L, 3L)
  )
})

# ---------------------------------------------------------------------------
# Empty-matching patterns
# ---------------------------------------------------------------------------

test_that("empty pattern errors", {
  expect_error(re_find("", ""))
})

test_that("pattern that can match empty returns leftmost empty match", {
  # "a*" on "bbb" matches empty at position 1
  expect_identical(
    re_find("bbb", "a*"),
    expected_mat(1L, 0L)
  )
})

# ---------------------------------------------------------------------------
# Byte offsets for UTF-8 (documented semantics: offsets are in bytes)
# ---------------------------------------------------------------------------

test_that("re_find reports byte offsets for multibyte UTF-8", {
  # "é" is 2 bytes in UTF-8; "café" is c(1) a(1) f(1) é(2) = 5 bytes
  s <- "caf\u00e9"
  # "é" starts at byte 4, ends at byte 5 (inclusive 1-based end = 5)
  expect_identical(
    re_find(s, "\u00e9"),
    expected_mat(4L, 5L)
  )
})

test_that("re_find offsets are byte-based even with leading multibyte chars", {
  # "\u00e9x" -> bytes: é(2) x(1)
  s <- "\u00e9x"
  expect_identical(
    re_find(s, "x"),
    expected_mat(3L, 3L)
  )
})

test_that("start is a byte offset for UTF-8", {
  # "aé b": a(1) é(2) space(1) b(1) -> bytes: a=1, é=2-3, space=4, b=5
  s <- "a\u00e9 b"
  # start = 5 (byte) should find "b" at byte 5
  expect_identical(
    re_find(s, "b", start = 5L),
    expected_mat(5L, 5L)
  )
  # start = 4 (byte, the space) should still find "b"
  expect_identical(
    re_find(s, "b", start = 4L),
    expected_mat(5L, 5L)
  )
})

# ---------------------------------------------------------------------------
# Error handling: pattern
# ---------------------------------------------------------------------------

test_that("re_find errors on non-string pattern", {
  expect_error(re_find("abc", 1L), "pattern")
  expect_error(re_find("abc", TRUE), "pattern")
})

test_that("re_find errors on length != 1 pattern", {
  expect_error(re_find("abc", c("a", "b")), "pattern")
  expect_error(re_find("abc", character(0)), "pattern")
})

test_that("re_find errors on NA pattern", {
  expect_error(re_find("abc", NA_character_), "pattern")
})

test_that("re_find errors on empty pattern", {
  expect_error(re_find("abc", ""), "pattern")
})

test_that("re_find errors on invalid UTF-8 pattern", {
  bad <- rawToChar(as.raw(c(0xff, 0xfe)))
  expect_error(re_find("abc", bad))
})

test_that("re_find errors on syntactically invalid regex", {
  expect_error(re_find("abc", "("))
  expect_error(re_find("abc", "[a-"))
})

# ---------------------------------------------------------------------------
# Error handling: string
# ---------------------------------------------------------------------------

test_that("re_find errors on non-character string", {
  expect_error(re_find(1:3, "a"), "string")
  expect_error(re_find(list("a"), "a"), "string")
})

# ---------------------------------------------------------------------------
# Error handling: start
# ---------------------------------------------------------------------------

test_that("re_find errors on non-integer start", {
  expect_error(re_find("abc", "a", start = list(1)), "start")
})

test_that("re_find coerces start", {
  expect_no_error(re_find("abc", "a", start = "1"))
})

test_that("re_find errors on length != 1 start", {
  expect_error(re_find("abc", "a", start = c(1L, 2L)), "start")
})

test_that("re_find errors on NA start", {
  expect_error(re_find("abc", "a", start = NA_integer_), "start")
})

test_that("re_find errors on start < 1", {
  expect_error(re_find("abc", "a", start = 0L), "start")
  expect_error(re_find("abc", "a", start = -1L), "start")
})

# ---------------------------------------------------------------------------
# Attributes and structure
# ---------------------------------------------------------------------------

test_that("re_find result has no extra attributes beyond dim/dimnames", {
  res <- re_find("apple", "ap")
  expect_identical(
    sort(names(attributes(res))),
    c("dim", "dimnames")
  )
})

test_that("re_find can be subset like a normal matrix", {
  res <- re_find(c("apple", "banana"), "an")
  expect_identical(res[, "start"], c(NA_integer_, 2L))
  expect_identical(res[, "end"], c(NA_integer_, 3L))
  expect_identical(res[1, ], c(start = NA_integer_, end = NA_integer_))
})

test_that("re_find result can be coerced to data.frame", {
  res <- re_find(c("apple", "banana"), "an")
  df <- as.data.frame(res)
  expect_identical(names(df), c("start", "end"))
  expect_identical(nrow(df), 2L)
})

# ---------------------------------------------------------------------------
# Capturing groups do not change output (only whole-match span is returned)
# ---------------------------------------------------------------------------

test_that("capturing groups do not affect re_find output", {
  expect_identical(
    re_find("banana", "(an)"),
    re_find("banana", "an")
  )
  expect_identical(
    re_find("2024-01-15", "(\\d+)-(\\d+)-(\\d+)"),
    expected_mat(1L, 10L)
  )
})

# ---------------------------------------------------------------------------
# Alternation, character classes, quantifiers
# ---------------------------------------------------------------------------

test_that("alternation returns leftmost of any alternative", {
  # "cat" vs "dog" in "a dog and a cat": dog starts at 3
  expect_identical(
    re_find("a dog and a cat", "dog|cat"),
    expected_mat(3L, 5L)
  )
})

test_that("character classes work", {
  expect_identical(
    re_find("abc123", "[0-9]+"),
    expected_mat(4L, 6L)
  )
})

test_that("greedy quantifier spans as much as possible from leftmost start", {
  expect_identical(
    re_find("aaabbb", "a+b+"),
    expected_mat(1L, 6L)
  )
})

# ---------------------------------------------------------------------------
# Start at exact boundary of each element
# ---------------------------------------------------------------------------

test_that("start equal to byte length + 1 of each element never aborts", {
  x <- c("a", "bb", "ccc")
  expect_identical(
    re_find(x, "a", start = 4L),
    expected_mat(
      start = c(NA_integer_, NA_integer_, NA_integer_),
      end   = c(NA_integer_, NA_integer_, NA_integer_)
    )
  )
})

test_that("start valid for some elements, invalid for others", {
  x <- c("a", "bb", "ccc")
  # start = 3 -> valid for "ccc" (len 3), invalid for "a" (len 1), "bb" (len 2)
  # searching from byte 3 of "ccc" means the tail "c"
  expect_identical(
    re_find(x, "c", start = 3L),
    expected_mat(
      start = c(NA_integer_, NA_integer_, 3L),
      end   = c(NA_integer_, NA_integer_, 3L)
    )
  )
})
