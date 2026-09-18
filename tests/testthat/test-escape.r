test_that("NA input remains", {
  expect_no_error(re_escape(NA_character_))
  expect_identical(re_escape(c("a", NA)), c("a", NA))
})

test_that("empty string is returned unchanged", {
  expect_identical(re_escape(""), "")
  expect_identical(re_escape(c("", "a")), c("", "a"))
})

test_that("empty input gives empty output", {
  expect_identical(re_escape(character(0)), character(0))
})

test_that("non-character input errors", {
  expect_error(re_escape(1))
  expect_error(re_escape(TRUE))
  expect_error(re_escape(list("a")))
  expect_error(re_escape(NULL))
})

test_that("invalid UTF-8 errors", {
  bad <- rawToChar(as.raw(c(0xff, 0xfe)))
  Encoding(bad) <- "unknown"
  expect_error(re_escape(bad))
  expect_error(re_escape(c("ok", bad)))
})

test_that("return value is character, same length", {
  x <- c("a", "b.c", "", NA)
  out <- re_escape(x[1:3])
  expect_type(out, "character")
  expect_length(out, 3L)
})

# ---------------------------------------------------------------------------
# Individual metacharacters
# ---------------------------------------------------------------------------
# Every character that regex-syntax treats as meta must be escaped.

test_that("dot is escaped", {
  expect_identical(re_escape("."), "\\.")
})

test_that("quantifiers are escaped", {
  expect_identical(re_escape("+"), "\\+")
  expect_identical(re_escape("*"), "\\*")
  expect_identical(re_escape("?"), "\\?")
})

test_that("grouping characters are escaped", {
  expect_identical(re_escape("("), "\\(")
  expect_identical(re_escape(")"), "\\)")
  expect_identical(re_escape("["), "\\[")
  expect_identical(re_escape("]"), "\\]")
  expect_identical(re_escape("{"), "\\{")
  expect_identical(re_escape("}"), "\\}")
})

test_that("alternation is escaped", {
  expect_identical(re_escape("|"), "\\|")
})

test_that("anchors are escaped", {
  expect_identical(re_escape("^"), "\\^")
  expect_identical(re_escape("$"), "\\$")
})

test_that("backslash is escaped", {
  expect_identical(re_escape("\\"), "\\\\")
})

test_that("set-operation metacharacters are escaped", {
  # Inside [] these are set operators; the crate still escapes them
  # at the top level for safety, and they must round-trip.
  expect_identical(re_escape("&"), "\\&")
  expect_identical(re_escape("-"), "\\-")
  expect_identical(re_escape("~"), "\\~")
})

test_that("hash is escaped (verbose mode comment char)", {
  expect_identical(re_escape("#"), "\\#")
})

# ---------------------------------------------------------------------------
# Full metacharacter round-trip
# ---------------------------------------------------------------------------

test_that("all metacharacters are escaped individually and matched literally", {
  # The canonical set of regex metacharacters in regex-syntax:
  metas <- c(
    ".", "+", "*", "?", "(", ")", "[", "]", "{", "}",
    "|", "^", "$", "\\", "&", "-", "~", "#"
  )
  esc <- re_escape(metas)
  expect_identical(esc, paste0("\\", metas))

  # Each escaped char, used as a pattern, should match the literal char
  # and NOT match some other char that the unescaped form would match
  for (i in seq_along(metas)) {
    expect_true(re_detect(metas[i], esc[i]),
      info = paste("escaped", metas[i], "should match itself")
    )
  }
})

test_that("unescaped metacharacters do NOT match literally", {
  # "." matches any char, so re_detect("x", ".") is TRUE.
  # If we escaped it, "x" should NOT match.
  expect_true(re_detect("x", "."))
  expect_false(re_detect("x", re_escape(".")))

  # "^" as a pattern is an anchor; escaped it matches the literal caret
  expect_true(re_detect("^", re_escape("^")))
  expect_false(re_detect("x", re_escape("^")))
})

# ---------------------------------------------------------------------------
# Round-trip property
# ---------------------------------------------------------------------------

test_that("escaping any string makes it match itself literally", {
  strings <- c(
    "hello world",
    "a.b.c",
    "1+1=2",
    "(parens)",
    "[brackets]",
    "{braces}",
    "pipe|char",
    "caret^dollar$",
    "back\\slash",
    "star*plus+question?",
    "a-b-c",
    "a&b~c#d"
  )
  for (s in strings) {
    expect_true(re_detect(s, re_escape(s)),
      info = paste("escaped string should match itself:", s)
    )
  }
})

test_that("escaped string does not match a different string", {
  # "a.b" as a raw pattern matches "axb"; escaped, it should not
  expect_true(re_detect("axb", "a.b"))
  expect_false(re_detect("axb", re_escape("a.b")))

  # "[abc]" as a raw pattern matches "a"; escaped, it should not
  expect_true(re_detect("a", "[abc]"))
  expect_false(re_detect("a", re_escape("[abc]")))
})

# ---------------------------------------------------------------------------
# Characters that are NOT metacharacters
# ---------------------------------------------------------------------------

test_that("ASCII letters are not escaped", {
  expect_identical(re_escape("abcXYZ"), "abcXYZ")
})

test_that("ASCII digits are not escaped", {
  expect_identical(re_escape("0123456789"), "0123456789")
})

test_that("angle brackets are not escaped (crate-specific rule)", {
  # Per the docs: '\* literal *, applies to all ASCII except [0-9A-Za-z<>]'
  # So < and > are legal but unnecessary escapes; regex::escape leaves them
  # alone. Verify.
  expect_identical(re_escape("<"), "<")
  expect_identical(re_escape(">"), ">")
  expect_identical(re_escape("<>"), "<>")
})

test_that("whitespace is not escaped", {
  expect_identical(re_escape(" "), " ")
  expect_identical(re_escape("\t"), "\t")
  expect_identical(re_escape("\n"), "\n")
})

test_that("non-ASCII punctuation is not escaped", {
  # These aren't ASCII metacharacters and shouldn't be touched
  expect_identical(re_escape("!"), "!")
  expect_identical(re_escape("@"), "@")
  expect_identical(re_escape("%"), "%")
  expect_identical(re_escape(","), ",")
  expect_identical(re_escape(";"), ";")
  expect_identical(re_escape(":"), ":")
  expect_identical(re_escape("="), "=")
  expect_identical(re_escape("'"), "'")
  expect_identical(re_escape("\""), "\"")
  expect_identical(re_escape("`"), "`")
  expect_identical(re_escape("/"), "/")
  expect_identical(re_escape("_"), "_")
})

# ---------------------------------------------------------------------------
# Unicode
# ---------------------------------------------------------------------------

test_that("non-ASCII unicode characters are not escaped", {
  expect_identical(re_escape("é"), "é")
  expect_identical(re_escape("α"), "α")
  expect_identical(re_escape("💩"), "💩")
  expect_identical(re_escape("日本語"), "日本語")
})

test_that("unicode chars mixed with metacharacters round-trip", {
  expect_true(re_detect("café.", re_escape("café.")))
  expect_true(re_detect("α+β", re_escape("α+β")))
  expect_false(re_detect("αxβ", re_escape("α+β")))
})

# ---------------------------------------------------------------------------
# Vectorised behaviour
# ---------------------------------------------------------------------------

test_that("escape is vectorised elementwise", {
  x <- c(".", "+", "a", "", "a.b")
  expect_identical(
    re_escape(x),
    c("\\.", "\\+", "a", "", "a\\.b")
  )
})

test_that("multiple metacharacters in one string", {
  expect_identical(re_escape("a.b*c+d?"), "a\\.b\\*c\\+d\\?")
  expect_identical(re_escape("(a|b)"), "\\(a\\|b\\)")
  expect_identical(re_escape("[a-z]"), "\\[a\\-z\\]")
  expect_identical(re_escape("a{2,3}"), "a\\{2,3\\}")
})

# ---------------------------------------------------------------------------
# Edge cases
# ---------------------------------------------------------------------------

test_that("all-metacharacter string escapes every char", {
  metas <- ".*+?()[]{}|^$\\&-~#"
  esc <- re_escape(metas)
  # Should be twice as long as original (each char prefixed by backslash)
  expect_identical(nchar(esc), 2L * nchar(metas))
  expect_identical(re_detect(metas, esc), TRUE)
})

test_that("escaping does not double-escape already-escaped input", {
  # Note: re_escape("\\.") escapes the backslash AND the dot:
  #   \  -> \\
  #   .  -> \.
  # Result: \\.  (a literal backslash followed by a literal dot)
  expect_identical(re_escape("\\."), "\\\\\\.")
  # And that escaped form matches the literal two-character string "\."
  expect_true(re_detect("\\.", re_escape("\\.")))
})
