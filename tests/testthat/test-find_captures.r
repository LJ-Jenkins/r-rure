# ---------------------------------------------------------------------------
# re_find_captures: structure
# ---------------------------------------------------------------------------

test_that("re_find_captures returns a 2-element named list", {
  res <- re_find_captures("apple", "ap")
  expect_type(res, "list")
  expect_length(res, 2L)
  expect_identical(names(res), c("matches", "captures"))
})

test_that("re_find_captures match element has the same structure as re_find", {
  res <- re_find_captures("apple", "ap")
  m <- res$matches
  expect_true(is.matrix(m))
  expect_type(m, "integer")
  expect_identical(dim(m), c(1L, 2L))
  expect_identical(colnames(m), c("start", "end"))
  expect_null(rownames(m))
})

test_that("re_find_captures match element equals re_find output", {
  res <- re_find_captures("banana", "(an)")
  expect_identical(res$matches, re_find("banana", "(an)"))
})

test_that("re_find_captures has one capture-group matrix per group", {
  res <- re_find_captures("2024-01-15", "(\\d+)-(\\d+)-(\\d+)")
  expect_length(res$captures, 3L)
})

test_that("re_find_captures doesn't name unnamed groups", {
  res <- re_find_captures("2024-01-15", "(\\d+)-(\\d+)-(\\d+)")
  expect_identical(names(res$captures), c("", "", ""))
})

test_that("re_find_captures uses regex group names when present", {
  res <- re_find_captures(
    "2024-01-15",
    "(?P<year>\\d+)-(?P<month>\\d+)-(?P<day>\\d+)"
  )
  expect_identical(names(res$captures), c("year", "month", "day"))
})

test_that("re_find_captures mixes named and unnamed groups", {
  res <- re_find_captures(
    "2024-01-15",
    "(?P<year>\\d+)-(\\d+)-(?P<day>\\d+)"
  )
  expect_identical(names(res$captures), c("year", "", "day"))
})

test_that("re_find_captures group matrices have the match matrix structure", {
  res <- re_find_captures("2024-01-15", "(\\d+)-(\\d+)-(\\d+)")
  for (g in res$captures) {
    expect_true(is.matrix(g))
    expect_type(g, "integer")
    expect_identical(dim(g), c(1L, 2L))
    expect_identical(colnames(g), c("start", "end"))
    expect_null(rownames(g))
  }
})

test_that("re_find_captures group matrices are not the same object", {
  res <- re_find_captures("2024-01-15", "(\\d+)-(\\d+)-(\\d+)")
  expect_false(identical(res$captures[[1]], res$captures[[2]]))
})

# ---------------------------------------------------------------------------
# re_find_captures: no capture groups
# ---------------------------------------------------------------------------

test_that("re_find_captures returns empty captures when no groups", {
  res <- re_find_captures("apple", "ap")
  expect_type(res$captures, "list")
  expect_length(res$captures, 0L)
})

# ---------------------------------------------------------------------------
# re_find_captures: correct spans
# ---------------------------------------------------------------------------

test_that("re_find_captures returns correct group spans", {
  # "banana":  b a n a n a
  #            1 2 3 4 5 6
  res <- re_find_captures("banana", "(a)(n)")
  expect_identical(
    res,
    expected_captures(
      expected_mat(2L, 3L),
      expected_mat(2L, 2L),
      expected_mat(3L, 3L)
    )
  )
})

test_that("re_find_captures handles a single group equal to the whole match", {
  res <- re_find_captures("banana", "(an)")
  expect_identical(
    res,
    expected_captures(
      expected_mat(2L, 3L),
      expected_mat(2L, 3L)
    )
  )
})

test_that("re_find_captures handles three groups", {
  res <- re_find_captures("2024-01-15", "(\\d+)-(\\d+)-(\\d+)")
  expect_identical(
    res,
    expected_captures(
      expected_mat(1L, 10L),
      expected_mat(1L, 4L),
      expected_mat(6L, 7L),
      expected_mat(9L, 10L)
    )
  )
})

test_that("re_find_captures handles nested groups", {
  res <- re_find_captures("ab", "((a)(b))")
  expect_identical(
    res,
    expected_captures(
      expected_mat(1L, 2L),
      expected_mat(1L, 2L),
      expected_mat(1L, 1L),
      expected_mat(2L, 2L)
    )
  )
})

test_that("re_find_captures reports byte offsets for multibyte groups", {
  s <- "caf\u00e9"
  res <- re_find_captures(s, "(caf)(\u00e9)")
  expect_identical(
    res,
    expected_captures(
      expected_mat(1L, 5L),
      expected_mat(1L, 3L),
      expected_mat(4L, 5L)
    )
  )
})

# ---------------------------------------------------------------------------
# re_find_captures: non-participating groups
# ---------------------------------------------------------------------------

test_that("re_find_captures returns NA for a non-participating group", {
  res <- re_find_captures("b", "(a)|(b)")
  expect_identical(
    res,
    expected_captures(
      expected_mat(1L, 1L),
      expected_mat(NA_integer_, NA_integer_),
      expected_mat(1L, 1L)
    )
  )
})

test_that("re_find_captures returns NA for optional group that didn't match", {
  res <- re_find_captures("b", "(a)?b")
  expect_identical(
    res,
    expected_captures(
      expected_mat(1L, 1L),
      expected_mat(NA_integer_, NA_integer_)
    )
  )
})

test_that("re_find_captures returns NA for all groups on no match", {
  res <- re_find_captures("apple", "(z)(z)")
  expect_identical(
    res,
    expected_captures(
      expected_mat(NA_integer_, NA_integer_),
      expected_mat(NA_integer_, NA_integer_),
      expected_mat(NA_integer_, NA_integer_)
    )
  )
})

# ---------------------------------------------------------------------------
# re_find_captures: NA handling
# ---------------------------------------------------------------------------

test_that("re_find_captures returns NA for NA_STRING elements", {
  res <- re_find_captures(NA_character_, "(a)(b)")
  expect_identical(
    res,
    expected_captures(
      expected_mat(NA_integer_, NA_integer_),
      expected_mat(NA_integer_, NA_integer_),
      expected_mat(NA_integer_, NA_integer_)
    )
  )
})

test_that("re_find_captures mixes real matches and NA elements", {
  x <- c("ab", NA, "ab", NA)
  res <- re_find_captures(x, "(a)(b)")
  expect_identical(
    res,
    expected_captures(
      expected_mat(
        c(1L, NA_integer_, 1L, NA_integer_),
        c(2L, NA_integer_, 2L, NA_integer_)
      ),
      expected_mat(
        c(1L, NA_integer_, 1L, NA_integer_),
        c(1L, NA_integer_, 1L, NA_integer_)
      ),
      expected_mat(
        c(2L, NA_integer_, 2L, NA_integer_),
        c(2L, NA_integer_, 2L, NA_integer_)
      )
    )
  )
})

test_that("re_find_captures handles NA when no groups", {
  res <- re_find_captures(NA_character_, "a")
  expect_identical(
    res,
    expected_captures(expected_mat(NA_integer_, NA_integer_))
  )
})

# ---------------------------------------------------------------------------
# re_find_captures: vectorization
# ---------------------------------------------------------------------------

test_that("re_find_captures is vectorized over string", {
  x <- c("2024-01-15", "1999-12-31", "not a date")
  res <- re_find_captures(x, "(\\d+)-(\\d+)-(\\d+)")
  expect_identical(nrow(res$matches), 3L)
  expect_identical(
    res$captures[[1]][, "start"],
    c(1L, 1L, NA_integer_)
  )
  expect_identical(
    res$captures[[1]][, "end"],
    c(4L, 4L, NA_integer_)
  )
  expect_identical(
    res$captures[[2]][, "start"],
    c(6L, 6L, NA_integer_)
  )
  expect_identical(
    res$captures[[3]][, "start"],
    c(9L, 9L, NA_integer_)
  )
})

test_that("re_find_captures group matrices have one row per string element", {
  x <- c("ab", "cd", "ef")
  res <- re_find_captures(x, "(a)(b)")
  for (g in res$captures) {
    expect_identical(nrow(g), 3L)
  }
})

test_that("re_find_captures preserves order of string", {
  x <- c("zzz", "ab", "mmm", "ab")
  res <- re_find_captures(x, "(a)(b)")
  expect_identical(
    res$captures[[1]][, "start"],
    c(NA_integer_, 1L, NA_integer_, 1L)
  )
})

# ---------------------------------------------------------------------------
# re_find_captures: zero-length input
# ---------------------------------------------------------------------------

test_that("re_find_captures returns 0-row matrices for empty character vector", {
  res <- re_find_captures(character(0), "(a)(b)")
  expect_identical(dim(res$matches), c(0L, 2L))
  expect_length(res$captures, 2L)
  expect_identical(dim(res$captures[[1]]), c(0L, 2L))
  expect_identical(dim(res$captures[[2]]), c(0L, 2L))
})

# ---------------------------------------------------------------------------
# re_find_captures: start argument
# ---------------------------------------------------------------------------

test_that("re_find_captures start skips earlier matches", {
  res <- re_find_captures("banana", "(a)", start = 3L)
  expect_identical(
    res,
    expected_captures(
      expected_mat(4L, 4L),
      expected_mat(4L, 4L)
    )
  )
})

test_that("re_find_captures start at exactly the match position works", {
  res <- re_find_captures("banana", "(a)", start = 2L)
  expect_identical(
    res,
    expected_captures(
      expected_mat(2L, 2L),
      expected_mat(2L, 2L)
    )
  )
})

test_that("re_find_captures start beyond match returns NA for all groups", {
  res <- re_find_captures("apple", "(ap)", start = 2L)
  expect_identical(
    res,
    expected_captures(
      expected_mat(NA_integer_, NA_integer_),
      expected_mat(NA_integer_, NA_integer_)
    )
  )
})

test_that("re_find_captures start beyond string length does not abort", {
  res <- re_find_captures("apple", "(a)", start = 100L)
  expect_identical(
    res,
    expected_captures(
      expected_mat(NA_integer_, NA_integer_),
      expected_mat(NA_integer_, NA_integer_)
    )
  )
})

test_that("re_find_captures start applies uniformly across elements", {
  x <- c("apple", "banana", "pear")
  res <- re_find_captures(x, "(a)", start = 2L)
  expect_identical(
    res,
    expected_captures(
      expected_mat(
        c(NA_integer_, 2L, 3L),
        c(NA_integer_, 2L, 3L)
      ),
      expected_mat(
        c(NA_integer_, 2L, 3L),
        c(NA_integer_, 2L, 3L)
      )
    )
  )
})

# ---------------------------------------------------------------------------
# re_find_captures: error handling
# ---------------------------------------------------------------------------

test_that("re_find_captures errors on non-string pattern", {
  expect_error(re_find_captures("abc", 1L), "pattern")
})

test_that("re_find_captures errors on length != 1 pattern", {
  expect_error(re_find_captures("abc", c("a", "b")), "pattern")
})

test_that("re_find_captures errors on NA pattern", {
  expect_error(re_find_captures("abc", NA_character_), "pattern")
})

test_that("re_find_captures errors on empty pattern", {
  expect_error(re_find_captures("abc", ""), "pattern")
})

test_that("re_find_captures errors on non-character string", {
  expect_error(re_find_captures(1:3, "(a)"), "string")
})

test_that("re_find_captures errors on non-integer start", {
  expect_error(re_find_captures("abc", "(a)", start = list(1)), "start")
})

test_that("re_find_captures errors on start < 1", {
  expect_error(re_find_captures("abc", "(a)", start = 0L), "start")
})
