# Argument type: search start offset

This page describes the `start` argument in rure. `start` controls the
byte position at which the regular expression engine begins searching.

It is a **1-based byte offset**, matching R's usual indexing
conventions. The default, `start = 1L`, begins at the first byte. The
valid range is `1 <= start <= nbytes(string) + 1`. Values less than `1`
raise an error; values greater than this range produce no match (`FALSE`
or `NA`, depending on the function).

## How matching works

A search from `start` finds the **first match at or after byte
`start`**. The engine tries to match `pattern` at byte `start`; if that
fails, it tries at byte `start + 1`; and so on.

`start` is **not** equivalent to slicing the string. The engine receives
the full string and may inspect bytes before `start` to evaluate anchors
and other zero-width assertions. For example, `"\\b"` at position
`start` inspects the byte at `start - 1` to decide whether a word
boundary exists there.

## Anchors

Because the search begins at `start` and moves forward:

- `"^"` and `"\\A"` assert the start of the string (byte 1, or after a
  newline with multi-line mode). Since the search cannot move backwards,
  **only `start = 1L`** can find a match anchored with `"^"` or `"\\A"`.

- `"$"` and `"\\z"` assert the end of the string (byte
  `nbytes(string) + 1`, or before a newline with multi-line mode). Since
  the search moves forward to the end, **any
  `start <= nbytes(string) + 1`** can find a match anchored with `"$"`
  or `"\\z"`.

- `"\\b"` asserts a word boundary at the current position. Any `start`
  whose suffix contains a word boundary can find a match.

## Boundaries

Let `n = nbytes(string)`. The valid range is `1 <= start <= n + 1`:

- `start = 1L` searches the whole string.

- `start = n` searches the final byte.

- `start = n + 1L` searches the empty suffix at the end of the string.
  Patterns that can match the empty string (e.g. `".*"`, `"$"`) will
  match here; patterns that require a byte will not.

- `start > n + 1L` is out of range. The result is `FALSE` for the
  detection and location functions, and `NA` for the extraction
  functions.

## Bytes, not characters

`start` is a **byte** offset, not a character offset. For ASCII input
the two coincide; for multi-byte UTF-8, `start` refers to the byte at
that position, which may fall in the middle of a multi-byte character.
Use
[`nbytes()`](https://lj-jenkins.github.io/r-rure/reference/nbytes.md) (a
wrapper for `nchar(x, type = "bytes")`) to compute byte lengths.

## NA handling

If `string` contains `NA`, the result for that element is `NA`,
regardless of `start`.

## See also

[`nbytes()`](https://lj-jenkins.github.io/r-rure/reference/nbytes.md)
for byte lengths, and
[re_pattern](https://lj-jenkins.github.io/r-rure/reference/re_pattern.md)
for pattern syntax.

## Examples

``` r
# Whole string
re_detect("abcabc", "a", start = 1L) # TRUE
#> [1] TRUE

# Start at byte 4 (the second "a")
re_detect("abcabc", "a", start = 4L) # TRUE  (matches the second a)
#> [1] TRUE
re_detect("abcabc", "b", start = 6L) # FALSE (only "c" remains)
#> [1] FALSE

# `^` only matches at byte 1, so only start = 1 can find it.
re_detect("abcabc", "^", start = 1L) # TRUE
#> [1] TRUE
re_detect("abcabc", "^", start = 2L) # FALSE
#> [1] FALSE

# `$` matches at byte n + 1, so any start in 1..n+1 can find it.
re_detect("abcabc", "$", start = 1L) # TRUE
#> [1] TRUE
re_detect("abcabc", "$", start = 7L) # TRUE
#> [1] TRUE
re_detect("abcabc", "$", start = 8L) # FALSE (out of range)
#> [1] FALSE

# Empty suffix
re_detect("abcabc", ".*", start = 7L) # TRUE
#> [1] TRUE
re_detect("abcabc", ".*", start = 8L) # FALSE (out of range)
#> [1] FALSE

# Byte, not character: e-acute is 2 bytes, 1 character.
nbytes("\u00e9") # 2
#> [1] 2
nchar("\u00e9") # 1
#> [1] 1
re_detect("\u00e9", ".", start = 1L) # TRUE
#> [1] TRUE
re_find("\u00e9", ".", start = 1L) # start=1, end=2
#>      start end
#> [1,]     1   2
```
