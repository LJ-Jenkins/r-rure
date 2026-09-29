# Find elements where a regex match occurs

Return the indices of elements in `string` that match regex patterns.

## Usage

``` r
re_where(string, pattern, start = 1L)

re_set_where(string, patterns, start = 1L)

re_set_where_each(string, patterns, start = 1L)
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

For `re_set_where()` and `re_set_where_each()`, an integer vector. For
`re_set_where_each()`, a list the length of `patterns` with each element
containing an integer vector.

## Details

`re_where()` returns the indices of elements in `string` that match
`pattern`.

`re_set_where()` does the same for a set of patterns, returning indices
of elements in `string` where **any** of the patterns match.

`re_set_where_each()` returns a list of integer vectors, where each list
element corresponds to a pattern in `patterns` and is filled with the
indices of elements in `string` that match the corresponding pattern.

No matches will result in an empty integer vector. For
`re_set_where_each()`, this will result in a list of empty integer
vectors.

Patterns must be valid UTF-8 to work with Rust's regex engine. Any
non-UTF-8 patterns will result in an error. `string` may contain
arbitrary bytes but ASCII compatible text is more useful, and UTF-8 is
more useful still. Other text encodings are not supported.

`re_where()` uses `rure_shortest_match` internally, which is faster on
short strings than `rure_is_match`. The two return identical results.
The set functions (`re_set_where()`, and `re_set_where_each()`) use
`rure_set_is_match`, because `rure` does not expose a shortest-match
variant for sets.

## Note

Patterns that can match the empty string (such as `"a*"`) return the
index for every element of `string`, since a zero-length match occurs at
the start of every string. Zero-length matches are treated as valid
matches.

## See also

[re_detect](https://lj-jenkins.github.io/r-rure/reference/re_detect.md)
for logical return values and
[re_find](https://lj-jenkins.github.io/r-rure/reference/re_find.md) for
match locations.

## Examples

``` r
fruit <- c("apple", "banana", "pear", "pineapple")
re_where(fruit, "a")
#> [1] 1 2 3 4
re_where(fruit, "^a")
#> [1] 1
re_where(fruit, "a$")
#> [1] 2
re_where(fruit, "b")
#> [1] 2
re_where(fruit, "[aeiou]")
#> [1] 1 2 3 4

re_set_where(fruit, c("a", "e"))
#> [1] 1 2 3 4
re_set_where_each(fruit, c("a", "e"))
#> [[1]]
#> [1] 1 2 3 4
#> 
#> [[2]]
#> [1] 1 3 4
#> 

# Zero-length matches count as matches
re_where(c("bear", "cat", ""), "a*") # all indexes
#> [1] 1 2 3

# Out-of-range start yields FALSE, even for patterns that match empty
# strings. Here start = 5 lands on the empty suffix for "bear" (4 bytes),
# but is out of range for "cat" (3 bytes) and "" (0 bytes).
re_where(c("bear", "cat", ""), "a*", start = 5L) # only 1L
#> [1] 1
```
