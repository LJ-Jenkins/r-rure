# Find locations of all regex matches

Return the start and end offsets (in bytes) of all regex matches within
each element of `string`.

## Usage

``` r
re_find_all(string, pattern, start = 1L)

re_find_all_captures(string, pattern, start = 1L)
```

## Arguments

- string:

  Character vector.

- pattern:

  Pattern to look for. For more information see
  [here](https://lj-jenkins.github.io/r-rure/reference/re_pattern.md).

- start:

  Byte offset at which to start searching (`1`-based). Default is `1`
  (start at the beginning of each string). The regex engine may look at
  bytes before the start position to determine match information. For
  example, if the start position is greater than `1`, then the `"\\A"`
  ("begin text") anchor can never match. For more information see
  [here](https://lj-jenkins.github.io/r-rure/reference/re_start.md).

## Value

For `re_find_all()`, a list the length of `string`. Each element is an
integer matrix with two columns, `start` and `end`, with one row per
match. See **Match positions** below for the convention used by `start`
and `end`. No match, `NA` elements, or elements shorter than the `start`
argument result in `NA` in both columns.

For `re_find_all_captures()`, a list the length of `string`. Each
element is a two-element list: `matches`, an integer matrix with one row
per match (same structure as the output of `re_find_all()`); and
`captures`, a list with one element per capture group, each a matrix of
the same structure as `matches`.

## Details

`re_find_all()` returns the offset locations of all matches.

`re_find_all_captures()` returns the offset locations of all matches as
well as the offset locations of any capture groups for each match.

Patterns must be valid UTF-8 to work with Rust's regex engine. Any
non-UTF-8 patterns will result in an error. `string` may contain
arbitrary bytes but ASCII compatible text is more useful, and UTF-8 is
more useful still. Other text encodings are not supported.

## Match positions

Match positions use the following convention:

- `start` is the **1-based** byte position of the first byte of the
  match.

- `end` is the **exclusive** end offset (0-based), i.e. the position
  just past the last byte of the match.

So a match on the first byte of `"abc"` has `start = 1, end = 1`; a
match on the first two bytes has `start = 1, end = 2`. `end - start + 1`
gives the byte length of the match, and `substr(string, start, end)`
extracts the matched substring (for ASCII input).

An empty match has `end == start - 1`. For example,
`re_find("abc", "^")` returns `start = 1, end = 0`.

These are **byte** offsets, not character offsets. For strings
containing multi-byte UTF-8 characters, `start` and `end` do not
correspond to character positions, and **R**'s character-based string
functions ([`substr()`](https://rdrr.io/r/base/substr.html),
[`substring()`](https://rdrr.io/r/base/substr.html)) will not correctly
extract the match. See
[here](https://lj-jenkins.github.io/r-rure/reference/re_pattern.md) for
details.

## See also

[re_find](https://lj-jenkins.github.io/r-rure/reference/re_find.md),
[re_find_shortest](https://lj-jenkins.github.io/r-rure/reference/re_find.md),
and
[re_find_captures](https://lj-jenkins.github.io/r-rure/reference/re_find.md)
for finding locations of the first match.

[re_detect](https://lj-jenkins.github.io/r-rure/reference/re_detect.md)
and
[re_where](https://lj-jenkins.github.io/r-rure/reference/re_where.md) to
return locations of vector element matches.

[nbytes](https://lj-jenkins.github.io/r-rure/reference/nbytes.md) to get
the number of bytes in each string.

## Examples

``` r
fruit <- c("apple", "banana", "pear", "pineapple")
re_find_all(fruit, "e|a")
#> [[1]]
#>      start end
#> [1,]     1   1
#> [2,]     5   5
#> 
#> [[2]]
#>      start end
#> [1,]     2   2
#> [2,]     4   4
#> [3,]     6   6
#> 
#> [[3]]
#>      start end
#> [1,]     2   2
#> [2,]     3   3
#> 
#> [[4]]
#>      start end
#> [1,]     4   4
#> [2,]     5   5
#> [3,]     9   9
#> 
re_find_all(fruit, "e|a", start = 5)
#> [[1]]
#>      start end
#> [1,]     5   5
#> 
#> [[2]]
#>      start end
#> [1,]     6   6
#> 
#> [[3]]
#>      start end
#> [1,]    NA  NA
#> 
#> [[4]]
#>      start end
#> [1,]     5   5
#> [2,]     9   9
#> 

# 'zero'-length matches can occur
re_find_all("bear", "a*")
#> [[1]]
#>      start end
#> [1,]     1   0
#> [2,]     2   1
#> [3,]     3   3
#> [4,]     4   3
#> [5,]     5   4
#> 

# Match positions: start is 1-based inclusive, end is exclusive
re_find_all("abc", "a") # start = 1, end = 1
#> [[1]]
#>      start end
#> [1,]     1   1
#> 
re_find_all("abc", "ab") # start = 1, end = 2
#> [[1]]
#>      start end
#> [1,]     1   2
#> 
re_find_all("abc", "b") # start = 2, end = 2
#> [[1]]
#>      start end
#> [1,]     2   2
#> 
re_find_all("abc", "^") # start = 1, end = 0 (empty match)
#> [[1]]
#>      start end
#> [1,]     1   0
#> 

x <- c("a=1;b=2", "c=3;d=4")
re_find_all_captures(x, "(?<cg_one>\\w+)=(?<cg_two>\\w+)")
#> [[1]]
#> [[1]]$matches
#>      start end
#> [1,]     1   3
#> [2,]     5   7
#> 
#> [[1]]$captures
#> [[1]]$captures$cg_one
#>      start end
#> [1,]     1   1
#> [2,]     5   5
#> 
#> [[1]]$captures$cg_two
#>      start end
#> [1,]     3   3
#> [2,]     7   7
#> 
#> 
#> 
#> [[2]]
#> [[2]]$matches
#>      start end
#> [1,]     1   3
#> [2,]     5   7
#> 
#> [[2]]$captures
#> [[2]]$captures$cg_one
#>      start end
#> [1,]     1   1
#> [2,]     5   5
#> 
#> [[2]]$captures$cg_two
#>      start end
#> [1,]     3   3
#> [2,]     7   7
#> 
#> 
#> 
```
