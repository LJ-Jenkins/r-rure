# Detect regex matches

Return logical values indicating where regex patterns match the input
strings.

## Usage

``` r
re_detect(string, pattern, start = 1L)

re_set_detect(string, patterns, start = 1L)

re_set_detect_each(string, patterns, start = 1L)
```

## Arguments

- string:

  Character vector.

- pattern, patterns:

  Pattern/s to look for. For more information see
  [here](https://lj-jenkins.github.io/r-rure/reference/re_pattern.md).

- start:

  Byte offset at which to start searching (`1`-based). Default is `1`
  (start at the beginning of each string). The regex engine may look at
  bytes before the start position to determine match information. For
  example, if the start position is greater than `1`, then the `"\\A"`
  ("begin text") anchor can never match. For more information see
  [here](https://lj-jenkins.github.io/r-rure/reference/re_start.md).

## Value

For `re_detect()` and `re_set_detect()`, a logical vector the same
length as `string`. For `re_set_detect_each()`, a logical matrix with
one row per element of `string` and one column per pattern in
`patterns`.

## Details

`re_detect()` returns a logical vector with `TRUE` for each element of
`string` that matches `pattern` and `FALSE` otherwise.

`re_set_detect()` does the same for a set of patterns, returning `TRUE`
if **any** of the patterns match.

`re_set_detect_each()` returns a logical matrix with one row per element
of `string` and one column per pattern in `patterns` - showing which
patterns match each string.

`NA` values in `string` will result in `NA` in the output.

Patterns must be valid UTF-8 to work with Rust's regex engine. Any
non-UTF-8 patterns will result in an error. `string` may contain
arbitrary bytes but ASCII compatible text is more useful, and UTF-8 is
more useful still. Other text encodings are not supported.

`re_detect()` uses `rure_shortest_match` internally, which is faster on
short strings than `rure_is_match`. The two return identical results.
The set functions (`re_set_detect()` and `re_set_detect_each()`) use
`rure_set_is_match`, because `rure` does not expose a shortest-match
variant for sets.

## Note

Patterns that can match the empty string (such as `"a*"`) return `TRUE`
for every element of `string`, since a zero-length match occurs at the
start of every string. Zero-length matches are treated as valid matches.

## See also

[re_where](https://lj-jenkins.github.io/r-rure/reference/re_where.md)
for index return values and
[re_find](https://lj-jenkins.github.io/r-rure/reference/re_find.md) for
match locations.

## Examples

``` r
fruit <- c("apple", "banana", "pear", "pineapple")
re_detect(fruit, "a")
#> [1] TRUE TRUE TRUE TRUE
re_detect(fruit, "a", start = 3L)
#> [1] FALSE  TRUE  TRUE  TRUE
re_detect(fruit, "^a|a$")
#> [1]  TRUE  TRUE FALSE FALSE
re_detect(fruit, "b")
#> [1] FALSE  TRUE FALSE FALSE
re_detect(fruit, "[aeiou]")
#> [1] TRUE TRUE TRUE TRUE

re_set_detect(fruit, c("a", "e"))
#> [1] TRUE TRUE TRUE TRUE
re_set_detect_each(fruit, c("a", "e"), start = 3L)
#>       [,1]  [,2]
#> [1,] FALSE  TRUE
#> [2,]  TRUE FALSE
#> [3,]  TRUE FALSE
#> [4,]  TRUE  TRUE

# Zero-length matches count as matches
re_detect(c("bear", "cat", ""), "a*") # all TRUE
#> [1] TRUE TRUE TRUE

# Out-of-range start yields FALSE, even for patterns that match empty
# strings. Here start = 5 lands on the empty suffix for "bear" (4 bytes),
# but is out of range for "cat" (3 bytes) and "" (0 bytes).
re_detect(c("bear", "cat", ""), "a*", start = 5L) # TRUE FALSE FALSE
#> [1]  TRUE FALSE FALSE
```
