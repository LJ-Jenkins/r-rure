# Tests for the pattern semantics of the wrapped Rust regex::bytes crate.
# Organised to mirror the syntax tables in ?re_pattern.

# ============================================================================
# Matching one character
# ============================================================================

test_that(". matches any character except newline", {
  expect_true(re_detect("a", "."))
  expect_true(re_detect(" ", "."))
  expect_false(re_detect("\n", "."))
  expect_true(re_detect("\n", "(?s)."))
})

test_that("[0-9] matches ASCII digits", {
  expect_true(re_detect("5", "[0-9]"))
  expect_false(re_detect("a", "[0-9]"))
  # ASCII-only: does not match non-ASCII digits
  expect_false(re_detect("\u0660", "[0-9]")) # Arabic-Indic digit zero
})

test_that("\\d matches Unicode digits by default", {
  expect_true(re_detect("5", "\\d"))
  expect_true(re_detect("\u0660", "\\d")) # Arabic-Indic digit
  expect_false(re_detect("a", "\\d"))
})

test_that("\\D matches non-digits", {
  expect_true(re_detect("a", "\\D"))
  expect_false(re_detect("5", "\\D"))
})

test_that("\\pX and \\p{...} match Unicode classes", {
  expect_true(re_detect("a", "\\pL"))
  expect_true(re_detect("\u03b1", "\\p{Greek}")) # Greek alpha
  expect_false(re_detect("5", "\\p{Letter}"))
})

test_that("\\P{...} matches negated Unicode classes", {
  expect_true(re_detect("5", "\\P{Letter}"))
  expect_false(re_detect("a", "\\P{Letter}"))
})

# ============================================================================
# Character classes
# ============================================================================

test_that("[xyz] is a union", {
  expect_true(re_detect("x", "[xyz]"))
  expect_true(re_detect("y", "[xyz]"))
  expect_true(re_detect("z", "[xyz]"))
  expect_false(re_detect("w", "[xyz]"))
})

test_that("[^xyz] is a negation", {
  expect_true(re_detect("w", "[^xyz]"))
  expect_false(re_detect("x", "[^xyz]"))
})

test_that("[a-z] is a range", {
  expect_true(re_detect("m", "[a-z]"))
  expect_false(re_detect("M", "[a-z]"))
})

test_that("[[:alpha:]] is an ASCII class", {
  expect_true(re_detect("a", "[[:alpha:]]"))
  expect_false(re_detect("\u00e9", "[[:alpha:]]")) # e-acute is not ASCII
})

test_that("[[:^alpha:]] is a negated ASCII class", {
  expect_true(re_detect("1", "[[:^alpha:]]"))
  expect_false(re_detect("a", "[[:^alpha:]]"))
})

test_that("nested classes work: [x[^xyz]]", {
  # matches x, or anything except y and z
  expect_true(re_detect("x", "[x[^xyz]]"))
  expect_true(re_detect("w", "[x[^xyz]]"))
  expect_false(re_detect("y", "[x[^xyz]]"))
  expect_false(re_detect("z", "[x[^xyz]]"))
})

test_that("intersection works: [a-y&&xyz]", {
  # intersection of a-y and {x,y,z} = {x,y}
  expect_true(re_detect("x", "[a-y&&xyz]"))
  expect_true(re_detect("y", "[a-y&&xyz]"))
  expect_false(re_detect("a", "[a-y&&xyz]"))
})

test_that("subtraction via intersection works: [0-9&&[^4]]", {
  expect_true(re_detect("5", "[0-9&&[^4]]"))
  expect_false(re_detect("4", "[0-9&&[^4]]"))
})

test_that("direct subtraction works: [0-9--4]", {
  expect_true(re_detect("5", "[0-9--4]"))
  expect_false(re_detect("4", "[0-9--4]"))
})

test_that("symmetric difference works: [a-g~~b-h]", {
  # {a..g} symmetric difference {b..h} = {a, h}
  expect_true(re_detect("a", "[a-g~~b-h]"))
  expect_true(re_detect("h", "[a-g~~b-h]"))
  expect_false(re_detect("b", "[a-g~~b-h]"))
  expect_false(re_detect("g", "[a-g~~b-h]"))
})

test_that("escapes inside classes work: [\\[\\]]", {
  expect_true(re_detect("[", "[\\[\\]]"))
  expect_true(re_detect("]", "[\\[\\]]"))
  expect_false(re_detect("a", "[\\[\\]]"))
})

test_that("empty class [a&&b] matches nothing", {
  expect_false(re_detect("a", "[a&&b]"))
  expect_false(re_detect("b", "[a&&b]"))
  expect_false(re_detect("", "[a&&b]"))
})

# ============================================================================
# Composites
# ============================================================================

test_that("concatenation works: xy", {
  expect_true(re_detect("abc", "ab"))
  expect_false(re_detect("acb", "ab"))
})

test_that("alternation is leftmost-first, not longest", {
  # "sam|samwise" matches "sam" in "samwise"
  m <- re_find("samwise", "sam|samwise")
  expect_equal(m[1, "end"][[1]], 3)
  # "samwise|sam" matches "samwise"
  m <- re_find("samwise", "samwise|sam")
  expect_equal(m[1, "end"][[1]], 7)
})

# ============================================================================
# Repetitions
# ============================================================================

test_that("greedy repetition works", {
  m <- re_find("aaab", "a+")
  expect_equal(m[1, "end"][[1]], 3) # matches "aaa"
  m <- re_find("aaab", "a*")
  expect_equal(m[1, "end"][[1]], 3)
  m <- re_find("aaab", "a?")
  expect_equal(m[1, "end"][[1]], 1)
})

test_that("lazy repetition works", {
  m <- re_find("aaab", "a+?")
  expect_equal(m[1, "end"][[1]], 1) # matches just "a"
})

test_that("bounded repetition works", {
  expect_true(re_detect("aa", "a{2}"))
  expect_false(re_detect("a", "a{2}"))
  expect_true(re_detect("aaa", "a{2,3}"))
  expect_true(re_detect("aa", "a{2,}"))
  expect_false(re_detect("a", "a{2,}"))
})

test_that("lazy bounded repetition works", {
  m <- re_find("aaaa", "a{2,3}?")
  expect_equal(m[1, "end"][[1]], 2) # lazy prefers 2
})

# ============================================================================
# Anchors and empty matches
# ============================================================================

test_that("^ anchors to start (without m)", {
  expect_true(re_detect("abc", "^a"))
  expect_false(re_detect("bac", "^a"))
})

test_that("$ anchors to end (without m)", {
  expect_true(re_detect("abc", "c$"))
  expect_false(re_detect("abc", "b$"))
})

test_that("\\A anchors to start always", {
  expect_true(re_detect("abc", "\\Aa"))
  expect_false(re_detect("abc", "\\Ab"))
})

test_that("\\z anchors to end always", {
  expect_true(re_detect("abc", "c\\z"))
  expect_false(re_detect("abc", "b\\z"))
})

test_that("\\b matches Unicode word boundaries", {
  expect_true(re_detect("foo bar", "\\bfoo\\b"))
  expect_false(re_detect("foobar", "\\bfoo\\b"))
})

test_that("\\B is the negation", {
  # "barfoo": "foo" starts at byte 3, preceded by 'r' (word char)
  # Position 3 is between two word chars -> \B matches
  expect_true(re_detect("barfoo", "\\Bfoo"))
  expect_false(re_detect("foo bar", "\\Bfoo")) # "foo" at boundary
})

test_that("\\b{start} matches start-of-word", {
  expect_true(re_detect("foo bar", "\\b{start}foo"))
  expect_false(re_detect("barfoo", "\\b{start}foo"))
})

test_that("\\b{end} matches end-of-word", {
  expect_true(re_detect("foo bar", "foo\\b{end}"))
  expect_false(re_detect("foobar", "foo\\b{end}"))
})

# ============================================================================
# Grouping and flags
# ============================================================================

test_that("numbered capture groups work", {
  m <- re_find_captures("abc", "(a)(b)")
  expect_true("captures" %in% names(m))
  expect_equal(length(m$captures), 2)
})

test_that("named capture groups work: (?P<name>exp)", {
  m <- re_find_captures("2024-01", "(?P<year>\\d{4})-(?P<month>\\d{2})")
  expect_true(!is.null(m$captures$year))
})

test_that("named capture groups work: (?<name>exp)", {
  m <- re_find_captures("2024-01", "(?<year>\\d{4})-(?<month>\\d{2})")
  expect_true(!is.null(m$captures$year))
})

test_that("non-capturing groups work", {
  m <- re_find_captures("abc", "(?:a)(b)")
  expect_equal(length(m$captures), 1)
})

test_that("i flag: case-insensitive", {
  expect_true(re_detect("ABC", "(?i)abc"))
  expect_false(re_detect("ABC", "abc"))
})

test_that("m flag: multi-line anchors", {
  expect_true(re_detect("a\nb\nc", "(?m)^b"))
  expect_false(re_detect("a\nb\nc", "^b"))
})

test_that("s flag: . matches newline", {
  expect_true(re_detect("a\nb", "(?s)a.b"))
  expect_false(re_detect("a\nb", "a.b"))
})

test_that("U flag: swaps greedy and lazy", {
  # With U, a+ is lazy and a+? is greedy
  m <- re_find("aaab", "(?U)a+")
  expect_equal(m[1, "end"][[1]], 1)
})

test_that("x flag: verbose mode ignores whitespace", {
  expect_true(re_detect("abc", "(?x) a b c"))
  expect_true(re_detect("abc", "(?x)a b c"))
})

test_that("flags can be toggled inline", {
  expect_true(re_detect("AaAaAbb", "(?i)a+(?-i)b+"))
  m <- re_find("AaAaAbb", "(?i)a+(?-i)b+")
  expect_equal(m[1, "end"][[1]], 7) # "AaAaAbb" -- a+ matches AaAaA, b+ matches bb
})

# ============================================================================
# Escape sequences
# ============================================================================

test_that("literal escapes work: \\*", {
  expect_true(re_detect("*", "\\*"))
  expect_false(re_detect("a", "\\*"))
})

test_that("control character escapes work", {
  expect_true(re_detect("\t", "\\t"))
  expect_true(re_detect("\n", "\\n"))
  expect_true(re_detect("\r", "\\r"))
  expect_true(re_detect("\a", "\\a"))
  expect_true(re_detect("\f", "\\f"))
  expect_true(re_detect("\v", "\\v"))
})

test_that("hex escapes work: \\x7F", {
  expect_true(re_detect("\x7F", "\\x7F"))
  expect_false(re_detect("a", "\\x7F"))
})

test_that("codepoint escapes work: \\x{10FFFF}", {
  expect_true(re_detect("\U0010FFFF", "\\x{10FFFF}"))
})

test_that("codepoint escapes work: \\u{7F}", {
  expect_true(re_detect("\x7F", "\\u{7F}"))
})

test_that("codepoint escapes work: \\U{7F}", {
  expect_true(re_detect("\x7F", "\\U{7F}"))
})

test_that("Unicode class escapes work: \\p{Letter}", {
  expect_true(re_detect("a", "\\p{Letter}"))
  expect_false(re_detect("1", "\\p{Letter}"))
})

# ============================================================================
# Perl character classes (Unicode friendly)
# ============================================================================

test_that("\\s matches Unicode whitespace", {
  expect_true(re_detect(" ", "\\s"))
  expect_true(re_detect("\t", "\\s"))
  expect_true(re_detect("\u00a0", "\\s")) # non-breaking space
})

test_that("\\S is the negation", {
  expect_true(re_detect("a", "\\S"))
  expect_false(re_detect(" ", "\\S"))
})

test_that("\\w matches Unicode word characters", {
  expect_true(re_detect("a", "\\w"))
  expect_true(re_detect("_", "\\w"))
  expect_true(re_detect("5", "\\w"))
  expect_true(re_detect("\u00e9", "\\w")) # e-acute is alphabetic
})

test_that("\\W is the negation", {
  expect_true(re_detect(" ", "\\W"))
  expect_false(re_detect("a", "\\W"))
})

# ============================================================================
# ASCII character classes
# ============================================================================

test_that("ASCII classes behave as documented", {
  expect_true(re_detect("a", "[[:alnum:]]"))
  expect_true(re_detect("5", "[[:alnum:]]"))
  expect_false(re_detect("!", "[[:alnum:]]"))

  expect_true(re_detect("a", "[[:alpha:]]"))
  expect_false(re_detect("5", "[[:alpha:]]"))

  expect_true(re_detect(" ", "[[:blank:]]"))
  expect_true(re_detect("\t", "[[:blank:]]"))

  expect_true(re_detect("\x01", "[[:cntrl:]]"))

  expect_true(re_detect("5", "[[:digit:]]"))

  expect_true(re_detect("!", "[[:graph:]]"))
  expect_false(re_detect(" ", "[[:graph:]]"))

  expect_true(re_detect("a", "[[:lower:]]"))
  expect_false(re_detect("A", "[[:lower:]]"))

  expect_true(re_detect(" ", "[[:space:]]"))
  expect_true(re_detect("\n", "[[:space:]]"))

  expect_true(re_detect("A", "[[:upper:]]"))
  expect_false(re_detect("a", "[[:upper:]]"))

  expect_true(re_detect("_", "[[:word:]]"))

  expect_true(re_detect("F", "[[:xdigit:]]"))
  expect_true(re_detect("f", "[[:xdigit:]]"))
  expect_false(re_detect("g", "[[:xdigit:]]"))
})

# ============================================================================
# Unsupported syntax
# ============================================================================

test_that("backreferences are rejected", {
  expect_true(errors("(a)\\1"))
  expect_true(errors("(?P<x>a)\\k<x>"))
})

test_that("look-ahead is rejected", {
  expect_true(errors("(?=a)"))
  expect_true(errors("(?!a)"))
})

test_that("look-behind is rejected", {
  expect_true(errors("(?<=a)"))
  expect_true(errors("(?<!a)"))
})

test_that("atomic groups are rejected", {
  expect_true(errors("(?>a)"))
})

test_that("possessive quantifier syntax is parsed as nested quantifiers", {
  # `x*+` = `(x*)+`, equivalent to `x*`
  expect_true(re_detect("aaa", "a*+"))
  expect_true(re_detect("bbb", "a*+")) # matches empty
  expect_equal(re_find("aaab", "a*+")[1, "end"][[1]], 3L)

  # `x++` = `(x+)+`, equivalent to `x+`
  expect_true(re_detect("aaa", "a++"))
  expect_false(re_detect("bbb", "a++")) # requires at least one
  expect_equal(re_find("aaab", "a++")[1, "end"][[1]], 3L)

  # `x?+` = `(x?)+`, equivalent to `x*` (NOT `x?`)
  expect_true(re_detect("aaa", "a?+"))
  expect_true(re_detect("bbb", "a?+")) # matches empty
  expect_equal(re_find("aaab", "a?+")[1, "end"][[1]], 3L)
})

test_that("conditionals are rejected", {
  expect_true(errors("(?(1)a|b)"))
})

test_that("NUL is rejected", {
  expect_true(errors("(?0)"))
})

test_that("subroutine calls are rejected", {
  expect_true(errors("(?&name)"))
})

test_that("callouts are rejected", {
  expect_true(errors("(?C1)"))
})

test_that("\\K is rejected", {
  expect_true(errors("a\\Kb"))
})

test_that("\\G is rejected", {
  expect_true(errors("\\Ga"))
})

test_that("\\R is rejected", {
  expect_true(errors("\\R"))
})

test_that("\\X is rejected", {
  expect_true(errors("\\X"))
})

# ============================================================================
# Empty pattern is disallowed by rure (wrapper behaviour)
# ============================================================================

test_that("empty pattern raises an error", {
  expect_error(re_detect("abc", ""))
  expect_error(re_find("abc", ""))
  expect_error(re_find_all("abc", ""))
})

test_that("patterns that match empty string are allowed", {
  expect_true(re_detect("abc", ".*"))
  expect_true(re_detect("abc", "a*"))
  expect_true(re_detect("abc", "(?:)"))
  expect_true(re_detect("abc", "\\b"))
})

test_that("[a&&b] is allowed and matches nothing", {
  expect_false(re_detect("abc", "[a&&b]"))
  expect_false(re_detect("", "[a&&b]"))
})

# ============================================================================
# Byte semantics (bytes::Regex)
# ============================================================================

test_that("byte offsets are returned, not character offsets", {
  # poo emoji is 1 codepoint but 4 bytes
  expect_equal(nbytes("\U0001F4A9"), 4)
  m <- re_find("\U0001F4A9", ".")
  expect_equal(m[1, "start"][[1]], 1)
  expect_equal(m[1, "end"][[1]], 4)
})

test_that("(?-u:.) matches a single byte", {
  m <- re_find("\U0001F4A9", "(?-u:.)")
  expect_equal(m[1, "start"][[1]], 1)
  expect_equal(m[1, "end"][[1]], 1)
})

test_that("(?-u:.) can split a codepoint in re_find_all", {
  m <- re_find_all("\U0001F4A9", "(?-u:.)")[[1]]
  expect_equal(nrow(m), 4) # four one-byte matches
})

test_that("disabling Unicode permits byte-level patterns", {
  # First byte of e-acute (U+00E9) is 0xC3, not an ASCII word char
  expect_true(re_detect("\u00e9", "(?-u:\\W)"))
})

test_that("disabling Unicode mode works for \\w as ASCII", {
  # ASCII \w excludes e-acute
  expect_false(re_detect("\u00e9", "(?-u:\\w)"))
})

# ============================================================================
# start argument interaction with anchors
# ============================================================================

test_that("^ cannot be found from start > 1", {
  expect_true(re_detect("abcabc", "^", start = 1L))
  expect_false(re_detect("abcabc", "^", start = 2L))
})

test_that("$ can be found from any valid start", {
  expect_true(re_detect("abcabc", "$", start = 1L))
  expect_true(re_detect("abcabc", "$", start = 7L))
  expect_false(re_detect("abcabc", "$", start = 8L)) # out of range
})

test_that("\\A cannot be found from start > 1", {
  expect_true(re_detect("abcabc", "\\A", start = 1L))
  expect_false(re_detect("abcabc", "\\A", start = 2L))
})

test_that("\\z can be found from any valid start", {
  expect_true(re_detect("abcabc", "\\z", start = 1L))
  expect_true(re_detect("abcabc", "\\z", start = 7L))
})

test_that("empty suffix is at start = nbytes + 1", {
  expect_equal(nbytes("bear"), 4)
  expect_true(re_detect("bear", "a*", start = 5L)) # empty suffix
  expect_false(re_detect("bear", "a*", start = 6L)) # out of range
})

test_that("out-of-range start overrides empty matches", {
  # "bear" is 4 bytes; start = 5 lands on empty suffix
  # "cat"  is 3 bytes; start = 5 is out of range
  # ""     is 0 bytes; start = 5 is out of range
  expect_equal(
    re_detect(c("bear", "cat", ""), "a*", start = 5L),
    c(TRUE, FALSE, FALSE)
  )
})

test_that("\\b can be found from start after the boundary", {
  # "abc abc": boundaries at bytes 0, 3, 4, 7 (0-based)
  # Searching from start = 5 (0-based 4) can find the boundary at byte 3?
  # No -- but it can find the boundary at byte 4 (between " " and "a")
  expect_true(re_detect("abc abc", "\\b", start = 5L))
})

# ============================================================================
# NA handling
# ============================================================================

test_that("NA propagates through all functions", {
  expect_equal(re_detect(c("a", NA, "b"), "a"), c(TRUE, NA, FALSE))
  expect_equal(re_detect(c("a", NA), "a", start = 1L), c(TRUE, NA))
})
