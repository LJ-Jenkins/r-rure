#' Argument type: regular expression pattern
#'
#' @description
#' This page describes the `pattern` argument shared by all rure
#' functions. `pattern` is a single character string containing a
#' regular expression, written in the syntax supported by the Rust
#' [`regex`](https://docs.rs/regex/latest/regex/) crate, specifically
#' the [`regex::bytes`](https://docs.rs/regex/latest/regex/bytes/)
#' module. `patterns` is a character vector containing multiple
#' patterns.
#'
#' This syntax is broadly similar to PCRE but is **not identical**.
#' Notable differences are described below.
#'
#' # The empty pattern is disallowed
#'
#' `pattern` must be a non-empty string. The empty string `""` is
#' **not a valid pattern** and will raise an error, even though the
#' underlying engine accepts it.
#'
#' The reason is that rure uses `regex::bytes`, under which the empty
#' pattern matches at **every byte offset**, including positions that
#' split a multi-byte UTF-8 codepoint. For a 4-byte emoji,
#' `re_find_all()` with an empty pattern would return 5 matches, at
#' byte offsets 0, 1, 2, 3, and 4. Rejecting `""` avoids this class of
#' surprising output.
#'
#' If you want to match the empty string at every position, use
#' `".*"`, `".?"`, or `"(?:)"`. If you want a pattern that matches
#' **nothing**, use `"[a&&b]"`, an empty character class.
#'
#' # Regex semantics
#'
#' rure uses the Rust `regex::bytes` module. Its semantics differ from
#' PCRE, Oniguruma, and base **R**'s `grep()` in several important
#' ways:
#'
#' * **No backtracking.** The engine is a finite automaton, not a
#'   backtracking matcher. It runs in time linear in the input length,
#'   but **backreferences** (`\1`, `\2`, ...) and **look-around**
#'   (`(?=...)`, `(?!...)`, `(?<=...)`, `(?<!...)`) are **not
#'   supported**. Attempting to use them raises an error.
#'
#' * **Leftmost-first, not leftmost-longest.** Among matches starting
#'   at the same position, the engine prefers the first branch of an
#'   alternation that matches, not the longest overall match. For
#'   example, `"sam|samwise"` matches `"sam"` in `"samwise"`, while
#'   `"samwise|sam"` matches `"samwise"`.
#'
#' * **Unicode by default.** `\w`, `\d`, `\s`, and `.` operate on
#'   Unicode codepoints, not bytes. `\w` matches any Unicode word
#'   character (`\p{Alphabetic}` plus `\p{M}`, `\d`, `\p{Pc}`, and
#'   `\p{Join_Control}`), not just `[A-Za-z0-9_]`. `.` does not match
#'   newline unless the `s` flag is set.
#'
#' * **Byte-level matching is available.** Disabling Unicode with
#'   `(?-u:...)` makes `.` match a single byte and allows patterns
#'   that would otherwise split codepoints.
#'
#' * **Every search is implicitly anchored to "anywhere in the
#'   string".** The engine finds the leftmost match anywhere in the
#'   haystack. Use `^` / `\A` and `$` / `\z` to anchor to the whole
#'   string (see [re_start] for how `start` interacts with anchors).
#'
#' # Encoding and byte semantics
#'
#' rure wraps `regex::bytes::Regex`, not the `&str`-based
#' `regex::Regex`. Two consequences:
#'
#' 1. **All offsets are byte offsets.** Match positions and `start`
#'    arguments are bytes, not characters. For ASCII the two coincide;
#'    for multi-byte UTF-8 they do not.
#'
#' 2. **Disabling Unicode is unrestricted.** Patterns like
#'    `"(?-u:\\W)"` or `"(?-u:\\xFF)"`, which the `&str`-based `Regex`
#'    type would reject, are accepted here.
#'
#' Because the default `u` flag is on, most patterns behave as if they
#' were codepoint-oriented. Byte-level behaviour only surfaces when
#' Unicode is explicitly disabled with `"(?-u:...)"`, as the examples
#' below show.
#'
#' `pattern` must be valid UTF-8 and will error if not. `string` may
#' contain arbitrary bytes, but ASCII compatible text is more useful,
#' and UTF-8 is more useful still. Other text encodings are not supported.
#'
#' # Syntax overview
#'
#' ## Matching one character
#'
#' ```r
#' .             any character except new line (any character with s flag)
#' [0-9]         any ASCII digit
#' \d            digit (\p{Nd})
#' \D            not digit
#' \p{Greek}     Unicode character class (general category or script)
#' \pX           Unicode character class, one-letter name
#' \P{Greek}     negated Unicode character class
#' ```
#'
#' ## Character classes
#'
#' ```r
#' [xyz]         any of x, y, or z
#' [^xyz]        any character except x, y, z
#' [a-z]         any character in range a-z
#' [[:alpha:]]   ASCII character class ([A-Za-z])
#' [[:^alpha:]]  negated ASCII character class
#' [x[^xyz]]     nested/grouping class
#' [a-y&&xyz]    intersection
#' [0-9&&[^4]]   subtraction via intersection and negation
#' [0-9--4]      direct subtraction
#' [a-g~~b-h]    symmetric difference
#' [\[\]]        escaping inside a character class
#' [a&&b]        empty class, matches nothing
#' ```
#'
#' ## Composites
#'
#' ```r
#' xy            concatenation
#' x|y           alternation (prefer x)
#' ```
#'
#' ## Repetitions
#'
#' ```r
#' x*  x+  x?          greedy
#' x*? x+? x??         ungreedy / lazy
#' x{n,m} x{n,} x{n}   greedy with bounds
#' x{n,m}? x{n,}? x{n}? ungreedy with bounds
#' ```
#'
#' ## Anchors and empty matches
#'
#' ```r
#' ^                start of haystack (or line, with m flag)
#' $                end of haystack (or line, with m flag)
#' \A               start of haystack (even with m flag)
#' \z               end of haystack (even with m flag)
#' \b               Unicode word boundary
#' \B               not a word boundary
#' \b{start}, \<    start-of-word boundary
#' \b{end},   \>    end-of-word boundary
#' ```
#'
#' ## Grouping and flags
#'
#' ```r
#' (exp)            numbered capture group
#' (?P<name>exp)    named (and numbered) capture group
#' (?<name>exp)     named (and numbered) capture group
#' (?:exp)          non-capturing group
#' (?flags)         set flags within current group
#' (?flags:exp)     set flags for exp (non-capturing)
#' ```
#'
#' Capture group names must be alphanumeric Unicode codepoints plus
#' `.`, `_`, `[`, `]`, and must start with `_` or an alphabetic
#' codepoint.
#'
#' Available flags:
#'
#' ```r
#' i     case-insensitive
#' m     multi-line: ^ and $ match begin/end of line
#' s     allow . to match \n
#' R     CRLF mode (with m, \r\n is treated as one line terminator)
#' U     swap meaning of x* and x*?
#' u     Unicode support (enabled by default)
#' x     verbose mode, ignore whitespace and allow # comments
#' ```
#'
#' Flags can be set and cleared inline, e.g. `"(?i)a+(?-i)b+"` matches
#' `a` case-insensitively and `b` case-sensitively.
#'
#' ## Escape sequences
#'
#' ```r
#' \*              literal * (works for any ASCII punctuation)
#' \a \f \t \n \r \v   control characters
#' \A \z \b \B     anchors and boundaries
#' \123            octal character code (up to three digits)
#' \x7F            hex character code (exactly two digits)
#' \x{10FFFF}      hex codepoint (any length)
#' \u007F          hex character code (exactly four digits)
#' \u{7F}          hex codepoint (any length)
#' \U0000007F      hex character code (exactly eight digits)
#' \U{7F}          hex codepoint (any length)
#' \p{Letter}      Unicode character class
#' \P{Letter}      negated Unicode character class
#' \d \s \w        Perl character class
#' \D \S \W        negated Perl character class
#' ```
#'
#' ## Perl character classes (Unicode friendly)
#'
#' ```r
#' \d    digit (\p{Nd})
#' \D    not digit
#' \s    whitespace (\p{White_Space})
#' \S    not whitespace
#' \w    word character
#' \W    not word character
#' ```
#'
#' ## ASCII character classes
#'
#' ```r
#' [[:alnum:]]    [0-9A-Za-z]
#' [[:alpha:]]    [A-Za-z]
#' [[:ascii:]]    [\x00-\x7F]
#' [[:blank:]]    [\t ]
#' [[:cntrl:]]    [\x00-\x1F\x7F]
#' [[:digit:]]    [0-9]
#' [[:graph:]]    [!-~]
#' [[:lower:]]    [a-z]
#' [[:print:]]    [ -~]
#' [[:punct:]]    [!-/:-@\[-`{-~]
#' [[:space:]]    [\t\n\v\f\r ]
#' [[:upper:]]    [A-Z]
#' [[:word:]]     [0-9A-Za-z_]
#' [[:xdigit:]]   [0-9A-Fa-f]
#' ```
#'
#' # Unsupported syntax
#'
#' The following PCRE features are **not** available, and attempting
#' to use them will either raise an error or exhibit (possibly)
#' unwanted behaviour. For example, the possessive quantifiers do not
#' typically error, instead being parsed as nested quantifiers.
#'
#' * Backreferences: `\1`, `\2`, `\k<name>`
#' * Look-ahead: `(?=...)`, `(?!...)`
#' * Look-behind: `(?<=...)`, `(?<!...)`
#' * Atomic groups: `(?>...)`
#' * Possessive quantifiers: `x*+`, `x++`, `x?+`
#' * Conditionals: `(?(cond)yes|no)`
#' * Recursion: `(?0)`
#' * Subroutine calls: `(?&name)`
#' * Callouts: `(?C...)`
#' * `\K` (reset match start)
#' * `\G` (match at previous match end)
#' * `\R` (any newline sequence)
#' * `\X` (extended grapheme cluster)
#'
#' If you need these, use base **R**, `stringi`, or `stringr`.
#'
#' @examples
#' # Basic literals and classes
#' re_detect("abc", "b") # TRUE
#' re_detect("abc", "[a-z]") # TRUE
#' re_detect("abc", "\\d") # FALSE
#'
#' # The empty pattern is disallowed
#' try(re_detect("abc", "")) # error
#'
#' # ... use ".*" or "(?:)" for "match anything"
#' re_detect("abc", ".*") # TRUE
#' re_detect("abc", "(?:)") # TRUE
#'
#' # ... or "[a&&b]" for "match nothing"
#' re_detect("abc", "[a&&b]") # FALSE
#'
#' # Leftmost-first, not leftmost-longest
#' re_find("samwise", "sam|samwise")[, "end"] # 3  (matches "sam")
#' re_find("samwise", "samwise|sam")[, "end"] # 7  (matches "samwise")
#'
#' # Unicode by default
#' re_detect("caf\u00e9", "\\w+") # TRUE
#' re_detect("caf\u00e9", "[a-z]+") # TRUE  (ASCII class, stops at e-acute)
#'
#' # Flags
#' re_detect("ABC", "abc") # FALSE
#' re_detect("ABC", "(?i)abc") # TRUE
#'
#' re_detect("a\nb", "a.b") # FALSE
#' re_detect("a\nb", "(?s)a.b") # TRUE
#'
#' re_detect("a\nb\nc", "(?m)^b") # TRUE
#'
#' # Character class algebra
#' re_detect("x", "[a-z&&[^aeiou]]") # TRUE  (x is a consonant)
#' re_detect("a", "[a-z&&[^aeiou]]") # FALSE (a is a vowel)
#'
#' # Unsupported features (typically) raise errors
#' try(re_detect("abc", "(?=a)")) # error: look-around not supported
#' try(re_detect("abc", "(a)\\1")) # error: backreferences not supported
#'
#' # Named capture groups
#' m <- re_find_captures(
#'   "2024-01-15",
#'   "(?<year>\\d{4})-(?<month>\\d{2})-(?<day>\\d{2})"
#' )
#' m$captures$year
#'
#' # Byte offsets, not character offsets.
#' # The poo emoji is one codepoint but four bytes.
#' re_find("\U0001F4A9", ".") # start=1, end=4 (whole codepoint)
#' re_find("\U0001F4A9", "(?-u:.)") # start=1, end=1 (first byte)
#' re_find_all("\U0001F4A9", "(?-u:.)") # 4 one-byte matches
#'
#' # Disabling Unicode permits byte-level patterns
#' re_detect("\u00e9", "(?-u:\\W)") # TRUE (first byte of e-acute is not ASCII \w)
#'
#' @seealso
#' * [re_start] for how the `start` argument interacts with anchors.
#' * The Rust [`regex` crate syntax
#'   documentation](https://docs.rs/regex/latest/regex/#syntax) for the
#'   authoritative reference.
#'
#' @keywords internal
#' @name re_pattern
NULL

#' Argument type: search start offset
#'
#' @description
#' This page describes the `start` argument in rure. `start` controls
#' the byte position at which the regular expression engine begins
#' searching.
#'
#' It is a **1-based byte offset**, matching R's usual string-indexing
#' conventions. The default, `start = 1L`, begins at the first byte.
#' The valid range is `1 <= start <= nbytes(string) + 1`. Values less
#' than `1` raise an error; values greater than this range produce no
#' match (`FALSE` or `NA`, depending on the function).
#'
#' # How matching works
#'
#' A search from `start` finds the **first match at or after byte
#' `start`**. The engine tries to match `pattern` at byte `start`; if
#' that fails, it tries at byte `start + 1`; and so on.
#'
#' `start` is **not** equivalent to slicing the string. The engine
#' receives the full string and may inspect bytes before `start` to
#' evaluate anchors and other zero-width assertions. For example, `\b`
#' at position `start` inspects the byte at `start - 1` to decide
#' whether a word boundary exists there.
#'
#' # Anchors
#'
#' Because the search begins at `start` and moves forward:
#'
#' * `^` and `\A` assert the start of the string (byte 1, or after a
#'   newline with multi-line mode). Since the search cannot move
#'   backwards, **only `start = 1L`** can find a match anchored with
#'   `^` or `\A`.
#'
#' * `$` and `\z` assert the end of the string (byte
#'   `nbytes(string) + 1`, or before a newline with multi-line mode).
#'   Since the search moves forward to the end, **any
#'   `start <= nbytes(string) + 1`** can find a match anchored with
#'   `$` or `\z`.
#'
#' * `\b` asserts a word boundary at the current position. Any `start`
#'   whose suffix contains a word boundary can find a match.
#'
#' # Boundaries
#'
#' Let `n = nbytes(string)`. The valid range is `1 <= start <= n + 1`:
#'
#' * `start = 1L` searches the whole string.
#' * `start = n` searches the final byte.
#' * `start = n + 1L` searches the empty suffix at the end of the
#'   string. Patterns that can match the empty string (e.g. `".*"`,
#'   `"$"`) will match here; patterns that require a byte will not.
#' * `start > n + 1L` is out of range. The result is `FALSE` for the
#'   detection and location functions, and `NA` for the extraction
#'   functions.
#'
#' # Bytes, not characters
#'
#' `start` is a **byte** offset, not a character offset. For ASCII
#' input the two coincide; for multi-byte UTF-8, `start` refers to the
#' byte at that position, which may fall in the middle of a multi-byte
#' character. Use [nbytes()] (a wrapper for
#' `nchar(x, type = "bytes")`) to compute byte lengths.
#'
#' # NA handling
#'
#' If `string` contains `NA`, the result for that element is `NA`,
#' regardless of `start`.
#'
#' @examples
#' # Whole string
#' re_detect("abcabc", "a", start = 1L) # TRUE
#'
#' # Start at byte 4 (the second "a")
#' re_detect("abcabc", "a", start = 4L) # TRUE  (matches the second a)
#' re_detect("abcabc", "b", start = 6L) # FALSE (only "c" remains)
#'
#' # `^` only matches at byte 1, so only start = 1 can find it.
#' re_detect("abcabc", "^", start = 1L) # TRUE
#' re_detect("abcabc", "^", start = 2L) # FALSE
#'
#' # `$` matches at byte n + 1, so any start in 1..n+1 can find it.
#' re_detect("abcabc", "$", start = 1L) # TRUE
#' re_detect("abcabc", "$", start = 7L) # TRUE
#' re_detect("abcabc", "$", start = 8L) # FALSE (out of range)
#'
#' # Empty suffix
#' re_detect("abcabc", ".*", start = 7L) # TRUE
#' re_detect("abcabc", ".*", start = 8L) # FALSE (out of range)
#'
#' # Byte, not character: e-acute is 2 bytes, 1 character.
#' nbytes("\u00e9") # 2
#' nchar("\u00e9") # 1
#' re_detect("\u00e9", ".", start = 1L) # TRUE
#' re_find("\u00e9", ".", start = 1L) # start=1, end=2
#'
#' @seealso [nbytes()] for byte lengths, and [re_pattern] for pattern
#'   syntax.
#'
#' @keywords internal
#' @name re_start
NULL
