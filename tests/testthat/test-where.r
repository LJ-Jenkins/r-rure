test_that("NA pattern is rejected", {
  expect_error(re_where("abc", NA_character_))
  expect_error(re_set_where("abc", NA_character_))
  expect_error(re_set_where_each("abc", NA_character_))
  expect_error(re_set_where("abc", c("a", NA)))
  expect_error(re_set_where_each("abc", c("a", NA)))
})

test_that("empty pattern is rejected", {
  expect_error(re_where("abc", ""))
  expect_error(re_set_where("abc", ""))
  expect_error(re_set_where_each("abc", ""))
  expect_error(re_set_where("abc", c("a", "")))
  expect_error(re_set_where_each("abc", c("a", "")))
})

test_that("NA in string is not matched", {
  x <- c("abc", NA, "def")
  expect_identical(re_where(x, "a"), 1L)
  expect_identical(re_where(x, "e"), 3L)
  expect_identical(re_set_where(x, c("a", "e")), c(1L, 3L))
  expect_identical(
    re_set_where_each(x, c("a", "e")),
    list(1L, 3L)
  )
})

test_that("empty input gives empty output", {
  expect_identical(re_where(character(0), "a"), integer(0))
  expect_identical(re_set_where(character(0), "a"), integer(0))
  expect_identical(
    re_set_where_each(character(0), c("a", "b")),
    list(integer(0), integer(0))
  )
})

test_that("non-character string errors", {
  expect_error(re_where(1:3, "a"))
  expect_error(re_where(TRUE, "a"))
  expect_error(re_where(list("a"), "a"))
  expect_error(re_set_where(1:3, "a"))
  expect_error(re_set_where_each(1:3, "a"))
})

test_that("non-character pattern errors", {
  expect_error(re_where("a", 1))
  expect_error(re_where("a", TRUE))
  expect_error(re_set_where("a", 1))
  expect_error(re_set_where_each("a", 1))
})

test_that("pattern must be length 1 for re_where", {
  expect_error(re_where("abc", c("a", "b")))
  expect_error(re_where("abc", character(0)))
})

test_that("patterns can be any length for set functions", {
  expect_silent(re_set_where("abc", c("a", "b", "c")))
  expect_silent(re_set_where("abc", "a"))
  expect_silent(re_set_where_each("abc", c("a", "b", "c")))
  # length-0 patterns should error (no meaningful output)
  expect_error(re_set_where("abc", character(0)))
  expect_error(re_set_where_each("abc", character(0)))
})

test_that("invalid UTF-8 in string does not error", {
  bad <- rawToChar(as.raw(c(0xff, 0xfe)))
  Encoding(bad) <- "unknown"
  expect_no_error(re_where(bad, "a"))
  expect_no_error(re_set_where(bad, "a"))
  expect_no_error(re_set_where_each(bad, "a"))
  expect_identical(re_where(bad, "\\xfe"), integer(0))
  expect_identical(re_where(bad, "(?-u)\\xfe"), 1L)
  expect_identical(re_set_where(bad, "(?-u)\\xfe"), 1L)
  expect_identical(re_set_where_each(bad, "(?-u)\\xfe"), list(1L))
})

test_that("invalid UTF-8 in pattern errors", {
  bad <- rawToChar(as.raw(c(0xff, 0xfe)))
  Encoding(bad) <- "unknown"
  expect_error(re_where("abc", bad))
  expect_error(re_set_where("abc", bad))
  expect_error(re_set_where_each("abc", bad))
})

test_that("matching is locale-independent (Turkish i example)", {
  # In a Turkish locale, toupper('i') == 'İ' and tolower('I') == 'ı'.
  # Unicode *default* case folding:
  # pairs i<->I and leaves İ (U+0130) and ı (U+0131) alone.
  old <- Sys.getlocale("LC_CTYPE")
  on.exit(Sys.setlocale("LC_CTYPE", old), add = TRUE)
  try(Sys.setlocale("LC_CTYPE", "tr_TR.UTF-8"), silent = TRUE)

  # Unicode default fold: i and I are equivalent under (?i)
  expect_identical(re_where(c("i", "I"), "(?i)i"), c(1L, 2L))
  expect_identical(re_where(c("i", "I"), "(?i)I"), c(1L, 2L))

  # Turkish-specific pairings must NOT hold
  expect_identical(re_where(c("İ", "ı"), "(?i)i"), integer(0))
  expect_identical(re_where(c("İ", "ı"), "(?i)I"), integer(0))
})

# ---------------------------------------------------------------------------
# Core where semantics
# ---------------------------------------------------------------------------

test_that("re_where returns integer vector of indices", {
  x <- c("apple", "banana", "pear", "pineapple")
  out <- re_where(x, "a")
  expect_type(out, "integer")
  expect_length(out, 4L)
  expect_identical(out, 1:4)
})

test_that("re_where basic matching works", {
  fruit <- c("apple", "banana", "pear", "pineapple")
  expect_identical(re_where(fruit, "a"), 1:4)
  expect_identical(re_where(fruit, "^a"), 1L)
  expect_identical(re_where(fruit, "a$"), 2L)
  expect_identical(re_where(fruit, "b"), 2L)
  expect_identical(re_where(fruit, "[aeiou]"), 1:4)
})

test_that("re_where returns integer(0) when nothing matches", {
  fruit <- c("apple", "banana", "pear", "pineapple")
  expect_identical(re_where(fruit, "z"), integer(0))
  expect_identical(re_where(fruit, "^z"), integer(0))
})

test_that("re_set_where returns union of indices across patterns", {
  fruit <- c("apple", "banana", "pear", "pineapple")
  expect_identical(re_set_where(fruit, c("a", "e")), 1:4)
  expect_identical(re_set_where(fruit, c("z", "q")), integer(0))
  expect_identical(re_set_where(fruit, "z"), integer(0))
  # Overlapping patterns shouldn't produce duplicated indices
  expect_identical(re_set_where(fruit, c("a", "^a")), 1:4)
  expect_identical(re_set_where(fruit, c("apple", "pear")), c(1L, 3L, 4L))
})

test_that("re_set_where_each returns list of integer vectors, one per pattern", {
  fruit <- c("apple", "banana", "pear", "pineapple")
  out <- re_set_where_each(fruit, c("a", "^b"))
  expect_type(out, "list")
  expect_length(out, 2L)
  expect_identical(out[[1]], 1:4)
  expect_identical(out[[2]], 2L)
})

test_that("re_set_where_each preserves order of patterns", {
  fruit <- c("apple", "banana", "pear", "pineapple")
  out <- re_set_where_each(fruit, c("z", "a", "b"))
  expect_identical(out[[1]], integer(0))
  expect_identical(out[[2]], 1:4)
  expect_identical(out[[3]], 2L)
})

test_that("re_set_where agrees with union of re_set_where_each", {
  fruit <- c("apple", "banana", "pear", "pineapple")
  pats <- c("a", "e", "z")
  expect_identical(
    re_set_where(fruit, pats),
    sort(unique(unlist(re_set_where_each(fruit, pats))))
  )
})

test_that("re_set_where_each elements are subsets of re_set_where", {
  fruit <- c("apple", "banana", "pear", "pineapple")
  pats <- c("a", "e", "z", "^a", "e$")
  each <- re_set_where_each(fruit, pats)
  union_idx <- re_set_where(fruit, pats)
  for (idx in each) {
    expect_true(all(idx %in% union_idx))
  }
})

# ---------------------------------------------------------------------------
# Crate syntax: matching one character
# ---------------------------------------------------------------------------

test_that("dot matches any char except newline", {
  expect_identical(re_where(c("a", "1", "\n"), "."), c(1L, 2L))
})

test_that("dot matches newline with s flag", {
  expect_identical(re_where(c("\n", "a"), "(?s)."), c(1L, 2L))
})

test_that("digit classes", {
  expect_identical(re_where(c("5", "a"), "\\d"), 1L)
  expect_identical(re_where(c("5", "a"), "\\D"), 2L)
  expect_identical(re_where(c("٥", "a"), "\\d"), 1L)
})

test_that("Unicode property classes", {
  expect_identical(re_where(c("α", "a"), "\\p{Greek}"), 1L)
  expect_identical(re_where(c("α", "a"), "\\P{Greek}"), 2L)
})

# ---------------------------------------------------------------------------
# Character classes
# ---------------------------------------------------------------------------

test_that("simple character classes", {
  expect_identical(re_where(c("x", "w"), "[xyz]"), 1L)
  expect_identical(re_where(c("x", "w"), "[^xyz]"), 2L)
  expect_identical(re_where(c("a", "1"), "[a-z]"), 1L)
})

test_that("ASCII character classes", {
  expect_identical(re_where(c("a", "1"), "[[:alpha:]]"), 1L)
  expect_identical(re_where(c("a", "1"), "[[:^alpha:]]"), 2L)
  expect_identical(re_where(c("a", "1"), "[[:digit:]]"), 2L)
  expect_identical(re_where(c("a", " "), "[[:space:]]"), 2L)
})

test_that("nested and set operations in character classes", {
  expect_identical(re_where(c("x", "a"), "[a-y&&xyz]"), 1L)
  expect_identical(re_where(c("5", "4"), "[0-9&&[^4]]"), 1L)
  expect_identical(re_where(c("5", "4"), "[0-9--4]"), 1L)
  expect_identical(re_where(c("a", "h", "b"), "[a-g~~b-h]"), c(1L, 2L))
})

test_that("named classes inside brackets", {
  expect_identical(re_where(c("5", "a"), "[\\p{Greek}[:digit:]]"), 1L)
  expect_identical(re_where(c("α", "5"), "[\\p{Greek}&&\\pL]"), 1L)
})

test_that("empty character class matches nothing", {
  expect_identical(re_where(c("a", "b"), "[a&&b]"), integer(0))
})

# ---------------------------------------------------------------------------
# Composites: concatenation and alternation
# ---------------------------------------------------------------------------

test_that("concatenation", {
  expect_identical(re_where(c("ab", "ba"), "ab"), 1L)
})

test_that("alternation prefers first branch (both match, so both found)", {
  expect_identical(re_where(c("samwise", "sam"), "samwise|sam"), c(1L, 2L))
  expect_identical(re_where(c("samwise", "sam"), "sam|samwise"), c(1L, 2L))
})

# ---------------------------------------------------------------------------
# Repetitions
# ---------------------------------------------------------------------------

test_that("greedy repetitions", {
  expect_identical(re_where(c("", "aaa"), "a*"), c(1L, 2L))
  expect_identical(re_where(c("", "aaa"), "a+"), 2L)
  expect_identical(re_where(c("", "a"), "a?"), c(1L, 2L))
})

test_that("bounded repetitions", {
  expect_identical(re_where(c("aa", "a"), "a{2}"), 1L)
  expect_identical(re_where(c("aaa", "aaaa"), "a{1,3}"), c(1L, 2L))
  expect_identical(re_where(c("a", ""), "a{1,}"), 1L)
})

test_that("lazy repetitions still where", {
  # a*?, a?? can all match a non-empty string
  expect_identical(re_where(c("aaa", "b"), "a*?"), c(1L, 2L))
  expect_identical(re_where(c("aaa", "b"), "a+?"), 1L) # a+? requires >=1 'a'
  expect_identical(re_where(c("a", "b"), "a??"), c(1L, 2L))
})

# ---------------------------------------------------------------------------
# Empty matches and anchors
# ---------------------------------------------------------------------------

test_that("patterns that can match empty match all strings", {
  expect_identical(re_where(c("", "abc"), "a*"), c(1L, 2L))
})

test_that("anchors", {
  expect_identical(re_where(c("abc", "xabc"), "^abc"), 1L)
  expect_identical(re_where(c("abc", "abcx"), "abc$"), 1L)
  expect_identical(re_where(c("abc", "xabc"), "\\Aabc"), 1L)
  expect_identical(re_where(c("abc", "abcx"), "abc\\z"), 1L)
})

test_that("word boundaries", {
  expect_identical(re_where(c("abc", "abcdef"), "\\babc\\b"), 1L)
  expect_identical(re_where(c("abc def", "abcdef"), "\\bdef\\b"), 1L)
})

test_that("start-of-word and end-of-word boundaries", {
  expect_identical(re_where(c("abc", "xabc"), "\\b{start}abc"), 1L)
  expect_identical(re_where(c("abc", "abcx"), "abc\\b{end}"), 1L)
  expect_identical(re_where(c("abc", "xabc"), "\\b{start-half}abc"), 1L)
  expect_identical(re_where(c("abc", "abcx"), "abc\\b{end-half}"), 1L)
})

# ---------------------------------------------------------------------------
# Grouping and flags
# ---------------------------------------------------------------------------

test_that("non-capturing groups", {
  expect_identical(re_where(c("abc", "xyz"), "(?:abc)"), 1L)
  expect_identical(re_where(c("abcabc", "abc"), "(?:abc)+"), 1:2)
})

test_that("case-insensitive flag", {
  expect_identical(re_where(c("ABC", "abc", "xyz"), "(?i)abc"), 1:2)
  expect_identical(re_where(c("ABC", "abc"), "abc"), 2L)
})

test_that("multi-line flag", {
  x <- c("line one\nline 2\n", "no match")
  expect_identical(re_where(x, "(?m)^line \\d+"), 1L)
  expect_identical(re_where(x, "^line \\d+"), integer(0))
})

test_that("dot-matches-newline flag", {
  x <- c("a\nb", "axb", "ab")
  # With s flag: dot matches newline, so both "a\nb" and "axb" match
  expect_identical(re_where(x, "(?s)a.b"), c(1L, 2L))
  # Without s flag: dot does not match newline, so only "axb" matches
  expect_identical(re_where(x, "a.b"), 2L)
})

test_that("verbose flag", {
  expect_identical(re_where(c("abc", "x"), "(?x) a b c"), 1L)
  expect_identical(re_where(c("abc", "x"), "(?x) a  # comment\n b c"), 1L)
})

test_that("flags can toggle mid-pattern", {
  expect_identical(re_where(c("AaAaAbb", "AaAaBbb"), "(?i)a+(?-i)b+"), 1L)
})

test_that("(?-u:...) makes \\b ASCII-only", {
  # Unicode \b treats é as a word character, so there is NO boundary
  # between f (word) and é (word) in "café"
  expect_identical(re_where("café", "\\bé\\b"), integer(0))

  # But a plain Unicode letter boundary works:
  expect_identical(re_where("café", "\\b\\p{L}+\\b"), 1L)
})

test_that("(?-u:.) matches a single byte (bytes-mode regex)", {
  # (?-u:.) is legal matches one byte. On "é" (C3 A9) it matches the first byte.
  expect_identical(re_where("é", "(?-u:.)"), 1L)

  # In Unicode mode, . matches the whole codepoint
  expect_identical(re_where("é", "."), 1L)

  # On an emoji (4 bytes), (?-u:.) still matches, and . also
  # matches (one codepoint). Both are "does it match anywhere?".
  expect_identical(re_where("💩", "(?-u:.)"), 1L)
  expect_identical(re_where("💩", "."), 1L)
})

test_that("(?-u:...) affects boundaries, not Unicode letter classes", {
  # ASCII \b at $/a is a boundary; \p{L}+ can match just "a"; the
  # trailing ASCII \b between a and é (C3 = non-word) holds.
  expect_identical(
    re_where("$$aéé$$", "(?-u:\\b)\\p{L}+(?-u:\\b)"),
    1L
  )

  # Same pattern on pure-ASCII "$$abc$$" matches too
  expect_identical(
    re_where("$$abc$$", "(?-u:\\b)\\p{L}+(?-u:\\b)"),
    1L
  )
})

test_that("(?-u:...) affects only its group", {
  # At position 0, both ASCII \b (start-of-string) and Unicode \b
  # (start-of-string) hold, so the conjunction matches.
  expect_identical(re_where("xé", "(?-u:\\b)\\b"), 1L)

  # But they disagree at position 1:
  #   ASCII \b sees x (word) -> C3 (non-word): boundary
  #   Unicode \b sees x (word) -> é (word): no boundary
  # So a pattern requiring both at position 1 fails there.
  # The pattern still matches at position 0, hence 1L.
  expect_identical(re_where("xé", "(?-u:\\b)\\b"), 1L)
})

test_that("(?-u:...) interacts correctly with other flags", {
  # ASCII case folding
  expect_identical(re_where("ABC", "(?i)(?-u:[a-z])"), 1L)

  # É (U+00C9) folds to é (U+00E9), which is NOT in [a-z].
  # So even with (?i), É does not match [a-z].
  expect_identical(re_where("É", "(?i)[a-z]"), integer(0))
  expect_identical(re_where("É", "(?i)(?-u:[a-z])"), integer(0))
})

# ---------------------------------------------------------------------------
# Escape sequences
# ---------------------------------------------------------------------------

test_that("literal escapes", {
  expect_identical(re_where(c("*", "x"), "\\*"), 1L)
  expect_identical(re_where(c(".", "x"), "\\."), 1L)
  expect_identical(re_where(c("a", "b"), "\\x61"), 1L)
  expect_identical(re_where(c("a", "b"), "\\u0061"), 1L)
  expect_identical(re_where(c("a", "b"), "\\x{61}"), 1L)
  expect_identical(re_where(c("a", "b"), "\\u{61}"), 1L)
})

test_that("control escapes", {
  expect_identical(re_where(c("\t", "x"), "\\t"), 1L)
  expect_identical(re_where(c("\n", "x"), "\\n"), 1L)
  expect_identical(re_where(c("\r", "x"), "\\r"), 1L)
  expect_identical(re_where(c("\a", "x"), "\\a"), 1L)
  expect_identical(re_where(c("\f", "x"), "\\f"), 1L)
  expect_identical(re_where(c("\v", "x"), "\\v"), 1L)
})

test_that("Perl character classes", {
  expect_identical(re_where(c("_", "!", "5"), "\\w"), c(1L, 3L))
  expect_identical(re_where(c(" ", "!"), "\\s"), 1L)
  expect_identical(re_where(c(" ", "!"), "\\S"), 2L)
})

# ---------------------------------------------------------------------------
# Edge cases
# ---------------------------------------------------------------------------

test_that("patterns that never match return integer(0)", {
  expect_identical(re_where(c("a", "b"), "[a&&b]"), integer(0))
})

test_that("all-NA string returns integer(0)", {
  x <- c(NA_character_, NA_character_)
  expect_identical(re_where(x, "a"), integer(0))
  expect_identical(re_set_where(x, c("a", "b")), integer(0))
  expect_identical(
    re_set_where_each(x, c("a", "b")),
    list(integer(0), integer(0))
  )
})

test_that("single-pattern character classes vs alternation are equivalent", {
  x <- c("a", "b", "c", "d")
  expect_identical(re_where(x, "[abc]"), re_set_where(x, c("a", "b", "c")))
})

test_that("unicode input is handled correctly", {
  expect_identical(re_where("café", "é"), 1L)
  expect_identical(re_where("café", "\\p{L}"), 1L)
  # 💩 is one codepoint; "." will match it
  expect_identical(re_where("💩", "."), 1L)
  # "." also matches a plain ASCII char
  expect_identical(re_where("x", "."), 1L)
  # \d is Unicode-aware
  expect_identical(re_where("٣", "\\d"), 1L)
})

test_that("anchors with unicode word boundaries", {
  expect_identical(re_where(c("café", "xcafé"), "\\bcafé\\b"), 1L)
})
