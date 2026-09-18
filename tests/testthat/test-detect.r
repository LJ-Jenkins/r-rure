test_that("NA pattern is rejected", {
  expect_error(re_detect("abc", NA_character_))
  expect_error(re_set_detect("abc", NA_character_))
  expect_error(re_set_detect_each("abc", NA_character_))
  expect_error(re_set_detect("abc", c("a", NA)))
  expect_error(re_set_detect_each("abc", c("a", NA)))
})

test_that("empty pattern is rejected", {
  expect_error(re_detect("abc", ""))
  expect_error(re_set_detect("abc", ""))
  expect_error(re_set_detect_each("abc", ""))
  expect_error(re_set_detect("abc", c("a", "")))
  expect_error(re_set_detect_each("abc", c("a", "")))
})

test_that("NA in string yields NA in output", {
  x <- c("abc", NA, "def")
  expect_identical(re_detect(x, "a"), c(TRUE, NA, FALSE))
  expect_identical(re_set_detect(x, c("a", "z")), c(TRUE, NA, FALSE))
  expect_identical(
    re_set_detect_each(x, c("a", "z")),
    matrix(
      c(
        TRUE, NA, FALSE,
        FALSE, NA, FALSE
      ),
      nrow = 3
    )
  )
})

test_that("empty input gives empty output", {
  expect_identical(re_detect(character(0), "a"), logical(0))
  expect_identical(re_set_detect(character(0), "a"), logical(0))
  expect_identical(
    re_set_detect_each(character(0), c("a", "b")),
    matrix(logical(0),
      nrow = 0, ncol = 2
    )
  )
})

test_that("non-character string errors", {
  expect_error(re_detect(1:3, "a"))
  expect_error(re_detect(TRUE, "a"))
  expect_error(re_detect(list("a"), "a"))
  expect_error(re_set_detect(1:3, "a"))
  expect_error(re_set_detect_each(1:3, "a"))
})

test_that("non-character pattern errors", {
  expect_error(re_detect("a", 1))
  expect_error(re_detect("a", TRUE))
  expect_error(re_set_detect("a", 1))
  expect_error(re_set_detect_each("a", 1))
})

test_that("pattern must be length 1 for re_detect", {
  expect_error(re_detect("abc", c("a", "b")))
  expect_error(re_detect("abc", character(0)))
})

test_that("patterns can be any length for set functions", {
  expect_silent(re_set_detect("abc", c("a", "b", "c")))
  expect_silent(re_set_detect("abc", "a"))
  expect_silent(re_set_detect_each("abc", c("a", "b", "c")))
  # length-0 patterns should error (no meaningful output)
  expect_error(re_set_detect("abc", character(0)))
  expect_error(re_set_detect_each("abc", character(0)))
})

test_that("invalid UTF-8 in string does not error", {
  bad <- rawToChar(as.raw(c(0xff, 0xfe)))
  Encoding(bad) <- "unknown"
  expect_no_error(re_detect(bad, "a"))
  expect_no_error(re_set_detect(bad, "a"))
  expect_no_error(re_set_detect_each(bad, "a"))
  expect_false(re_detect(bad, "\\xfe"))
  expect_true(re_detect(bad, "(?-u)\\xfe"))
  expect_true(re_set_detect(bad, "(?-u)\\xfe"))
  expect_true(re_set_detect_each(bad, "(?-u)\\xfe"))
})

test_that("invalid UTF-8 in pattern errors", {
  bad <- rawToChar(as.raw(c(0xff, 0xfe)))
  Encoding(bad) <- "unknown"
  expect_error(re_detect("abc", bad))
  expect_error(re_set_detect("abc", bad))
  expect_error(re_set_detect_each("abc", bad))
})

test_that("matching is locale-independent (Turkish i example)", {
  # In a Turkish locale, toupper("i") == "İ" (dotted capital I).
  old <- Sys.getlocale("LC_CTYPE")
  on.exit(Sys.setlocale("LC_CTYPE", old), add = TRUE)
  try(Sys.setlocale("LC_CTYPE", "tr_TR.UTF-8"), silent = TRUE)

  expect_true(re_detect("i", "(?i)i"))
  expect_true(re_detect("I", "(?i)i")) # Unicode default fold
  expect_false(re_detect("İ", "(?i)i")) # only matches under Turkish tailoring
  expect_false(re_detect("ı", "(?i)i")) # only matches under Turkish tailoring

  # The Turkish tailoring would also make 'I' match 'ı' and 'İ' match 'i'.
  # Under Unicode default folding, neither holds.
  expect_false(re_detect("ı", "(?i)I")) # Turkish: would be TRUE; Unicode default: FALSE
  expect_true(re_detect("i", "(?i)I")) # Unicode default fold: TRUE
})

# ---------------------------------------------------------------------------
# Core detect semantics
# ---------------------------------------------------------------------------

test_that("re_detect returns logical vector of same length", {
  x <- c("apple", "banana", "pear", "pineapple")
  out <- re_detect(x, "a")
  expect_type(out, "logical")
  expect_length(out, length(x))
})

test_that("re_detect basic matching works", {
  fruit <- c("apple", "banana", "pear", "pineapple")
  expect_identical(re_detect(fruit, "a"), c(TRUE, TRUE, TRUE, TRUE))
  expect_identical(re_detect(fruit, "^a"), c(TRUE, FALSE, FALSE, FALSE))
  expect_identical(re_detect(fruit, "a$"), c(FALSE, TRUE, FALSE, FALSE))
  expect_identical(re_detect(fruit, "b"), c(FALSE, TRUE, FALSE, FALSE))
  expect_identical(re_detect(fruit, "[aeiou]"), c(TRUE, TRUE, TRUE, TRUE))
})

test_that("re_set_detect returns TRUE if any pattern matches", {
  fruit <- c("apple", "banana", "pear", "pineapple")
  expect_identical(re_set_detect(fruit, c("a", "e")), c(TRUE, TRUE, TRUE, TRUE))
  expect_identical(re_set_detect(fruit, c("z", "q")), c(FALSE, FALSE, FALSE, FALSE))
  expect_identical(re_set_detect(fruit, "z"), c(FALSE, FALSE, FALSE, FALSE))
})

test_that("re_set_detect_each returns matrix with one column per pattern", {
  fruit <- c("apple", "banana", "pear", "pineapple")
  m <- re_set_detect_each(fruit, c("a", "^b"))
  expect_true(is.matrix(m))
  expect_type(m, "logical")
  expect_identical(dim(m), c(length(fruit), 2L))
  expect_identical(m[, 1], re_detect(fruit, "a"))
  expect_identical(m[, 2], re_detect(fruit, "^b"))
})

test_that("re_set_detect agrees with rowSums of re_set_detect_each", {
  fruit <- c("apple", "banana", "pear", "pineapple")
  pats <- c("a", "e", "z")
  expect_identical(
    re_set_detect(fruit, pats),
    apply(re_set_detect_each(fruit, pats), 1, any)
  )
})

# ---------------------------------------------------------------------------
# Crate syntax: matching one character
# ---------------------------------------------------------------------------

test_that("dot matches any char except newline", {
  expect_true(re_detect("a", "."))
  expect_true(re_detect("1", "."))
  expect_false(re_detect("\n", "."))
})

test_that("dot matches newline with s flag", {
  expect_true(re_detect("\n", "(?s)."))
})

test_that("digit classes", {
  expect_true(re_detect("5", "\\d"))
  expect_false(re_detect("a", "\\d"))
  expect_true(re_detect("a", "\\D"))
  expect_true(re_detect("٥", "\\d")) # Arabic-Indic digit (Nd)
})

test_that("Unicode property classes", {
  expect_true(re_detect("α", "\\p{Greek}"))
  expect_false(re_detect("a", "\\p{Greek}"))
  expect_false(re_detect("α", "\\P{Greek}"))
  expect_true(re_detect("a", "\\P{Greek}"))
})

# ---------------------------------------------------------------------------
# Character classes
# ---------------------------------------------------------------------------

test_that("simple character classes", {
  expect_true(re_detect("x", "[xyz]"))
  expect_false(re_detect("w", "[xyz]"))
  expect_false(re_detect("x", "[^xyz]"))
  expect_true(re_detect("a", "[a-z]"))
})

test_that("ASCII character classes", {
  expect_true(re_detect("a", "[[:alpha:]]"))
  expect_false(re_detect("1", "[[:alpha:]]"))
  expect_false(re_detect("a", "[[:^alpha:]]"))
  expect_true(re_detect("1", "[[:digit:]]"))
  expect_true(re_detect(" ", "[[:space:]]"))
})

test_that("nested and set operations in character classes", {
  expect_true(re_detect("x", "[a-y&&xyz]"))
  expect_false(re_detect("a", "[a-y&&xyz]"))
  expect_false(re_detect("4", "[0-9&&[^4]]"))
  expect_true(re_detect("5", "[0-9&&[^4]]"))
  expect_false(re_detect("4", "[0-9--4]"))
  expect_true(re_detect("a", "[a-g~~b-h]"))
  expect_true(re_detect("h", "[a-g~~b-h]"))
  expect_false(re_detect("b", "[a-g~~b-h]"))
})

test_that("named classes inside brackets", {
  expect_true(re_detect("5", "[\\p{Greek}[:digit:]]"))
  expect_true(re_detect("α", "[\\p{Greek}[:digit:]]"))
  expect_true(re_detect("Ω", "[\\p{Greek}&&\\pL]"))
  expect_false(re_detect("5", "[\\p{Greek}&&\\pL]"))
})

test_that("empty character class matches nothing", {
  expect_false(re_detect("a", "[a&&b]"))
  expect_false(re_detect("b", "[a&&b]"))
})

# ---------------------------------------------------------------------------
# Composites: concatenation and alternation
# ---------------------------------------------------------------------------

test_that("concatenation", {
  expect_true(re_detect("ab", "ab"))
  expect_false(re_detect("ba", "ab"))
})

test_that("alternation prefers first branch", {
  # "samwise" should match, not just "sam"
  expect_true(re_detect("samwise", "samwise|sam"))
  expect_true(re_detect("samwise", "sam|samwise"))
})

# ---------------------------------------------------------------------------
# Repetitions
# ---------------------------------------------------------------------------

test_that("greedy repetitions", {
  expect_true(re_detect("", "a*"))
  expect_true(re_detect("aaa", "a*"))
  expect_false(re_detect("", "a+"))
  expect_true(re_detect("a", "a+"))
  expect_true(re_detect("", "a?"))
  expect_true(re_detect("a", "a?"))
})

test_that("bounded repetitions", {
  expect_true(re_detect("aa", "a{2}"))
  expect_false(re_detect("a", "a{2}"))
  expect_true(re_detect("aaa", "a{1,3}"))
  expect_true(re_detect("aaaa", "a{1,3}"))
  expect_true(re_detect("a", "a{1,}"))
})

test_that("lazy repetitions still detect", {
  expect_true(re_detect("aaa", "a*?"))
  expect_true(re_detect("aaa", "a+?"))
  expect_true(re_detect("a", "a??"))
})

# ---------------------------------------------------------------------------
# Empty matches and anchors
# ---------------------------------------------------------------------------

test_that("empty pattern matches empty string", {
  expect_true(re_detect("", "a*"))
  expect_true(re_detect("abc", "a*"))
})

test_that("anchors", {
  expect_true(re_detect("abc", "^abc"))
  expect_false(re_detect("xabc", "^abc"))
  expect_true(re_detect("abc", "abc$"))
  expect_false(re_detect("abcx", "abc$"))
  expect_true(re_detect("abc", "\\Aabc"))
  expect_true(re_detect("abc", "abc\\z"))
})

test_that("word boundaries", {
  expect_true(re_detect("abc", "\\babc\\b"))
  expect_true(re_detect("abc def", "\\bdef\\b"))
  expect_false(re_detect("abcdef", "\\babc\\b"))
})

test_that("start-of-word and end-of-word boundaries", {
  expect_true(re_detect("abc", "\\b{start}abc"))
  expect_true(re_detect("abc", "abc\\b{end}"))
  expect_true(re_detect("abc", "\\b{start-half}abc"))
  expect_true(re_detect("abc", "abc\\b{end-half}"))
})

# ---------------------------------------------------------------------------
# Grouping and flags
# ---------------------------------------------------------------------------

test_that("non-capturing groups", {
  expect_true(re_detect("abc", "(?:abc)"))
  expect_true(re_detect("abcabc", "(?:abc)+"))
})

test_that("case-insensitive flag", {
  expect_true(re_detect("ABC", "(?i)abc"))
  expect_true(re_detect("abc", "(?i)ABC"))
  expect_false(re_detect("ABC", "abc"))
})

test_that("multi-line flag", {
  x <- "line one\nline 2\n"
  expect_true(re_detect(x, "(?m)^line \\d+"))
  expect_false(re_detect(x, "^line \\d+"))
})

test_that("dot-matches-newline flag", {
  expect_true(re_detect("a\nb", "(?s)a.b"))
  expect_false(re_detect("a\nb", "a.b"))
})

test_that("verbose flag", {
  expect_true(re_detect("abc", "(?x) a b c"))
  expect_true(re_detect("abc", "(?x) a  # comment\n b c"))
})

test_that("flags can toggle mid-pattern", {
  expect_true(re_detect("AaAaAbb", "(?i)a+(?-i)b+"))
})

test_that("unicode can be selectively disabled", {
  expect_true(re_detect("$$abc$$", "(?-u:\\b).+(?-u:\\b)"))
})

# ---------------------------------------------------------------------------
# Escape sequences
# ---------------------------------------------------------------------------

test_that("literal escapes", {
  expect_true(re_detect("*", "\\*"))
  expect_true(re_detect(".", "\\."))
  expect_true(re_detect("a", "\\x61"))
  expect_true(re_detect("a", "\\u0061"))
  expect_true(re_detect("a", "\\x{61}"))
  expect_true(re_detect("a", "\\u{61}"))
})

test_that("control escapes", {
  expect_true(re_detect("\t", "\\t"))
  expect_true(re_detect("\n", "\\n"))
  expect_true(re_detect("\r", "\\r"))
  expect_true(re_detect("\a", "\\a"))
  expect_true(re_detect("\f", "\\f"))
  expect_true(re_detect("\v", "\\v"))
})

test_that("Perl character classes", {
  expect_true(re_detect("_", "\\w"))
  expect_true(re_detect("a", "\\w"))
  expect_true(re_detect("5", "\\w"))
  expect_false(re_detect("!", "\\w"))
  expect_true(re_detect(" ", "\\s"))
  expect_true(re_detect("!", "\\S"))
})

# ---------------------------------------------------------------------------
# Edge cases
# ---------------------------------------------------------------------------

test_that("patterns that never match return FALSE for all", {
  expect_identical(re_detect(c("a", "b"), "[a&&b]"), c(FALSE, FALSE))
})

test_that("all-NA string still returns NA-filled output", {
  x <- c(NA_character_, NA_character_)
  expect_identical(re_detect(x, "a"), c(NA, NA))
  expect_identical(re_set_detect(x, c("a", "b")), c(NA, NA))
  expect_identical(
    re_set_detect_each(x, c("a", "b")),
    matrix(c(NA, NA, NA, NA),
      nrow = 2
    )
  )
})

test_that("single-pattern character classes vs alternation are equivalent", {
  x <- c("a", "b", "c", "d")
  expect_identical(re_detect(x, "[abc]"), re_set_detect(x, c("a", "b", "c")))
})

test_that("unicode input is handled correctly", {
  expect_true(re_detect("café", "é"))
  expect_true(re_detect("café", "\\p{L}"))
  expect_true(re_detect("💩", "."))
  # \d is Unicode-aware, so this will match
  expect_true(re_detect("٣", "\\d")) # Arabic-Indic digit
})

test_that("anchors with unicode word boundaries", {
  # \b is Unicode-aware by default
  expect_true(re_detect("café", "\\bcafé\\b"))
})
