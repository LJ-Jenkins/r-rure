# Find locations of regex matches

Return the start and end offsets (in bytes) of regex matches within each
element of `string`.

## Usage

``` r
re_find(string, pattern, start = 1L)

re_find_captures(string, pattern, start = 1L)

re_find_all(string, pattern, start = 1L)
```

## Arguments

- string:

  Character vector.

- pattern:

  Pattern to look for (single string).

- start:

  Byte offset at which to start searching (`1`-based). Default is `1`
  (start at the beginning of each string).

## Value

For `re_find()`, a (integer) matrix with two columns: `start` and `end`.
Each row corresponds to an element of `string` and contains the `start`
and `end` offsets of the match. No match or `NA` string elements will
result in `NA` values in both the `start` and `end` columns. The same
will occur for elements of `string` that are shorter than the specified
`start` offset.

For `re_find_captures()`, a two-element list. The first element
(`'matches'`) is the same as the output of `re_find()`. The second
element (`'captures'`) is a list the length of the number of capture
groups, with each element containing a matrix of the same structure
described but for each capture group.

For `re_find_all()`, a list the length of `string` with each element
containing a matrix with `n` rows where `n` is the number of matches for
that element of `string`. No matches will result in a matrix with a
single row with `NA` values in both the `start` and `end` columns.

## Details

`re_find()` returns the offset locations of the first match.

`re_find_all()` returns the offset locations of all matches.

`re_find_captures()` returns the offset locations of the first match as
well as the offset locations of any capture groups for that match.

Patterns must be valid UTF-8 to work with Rust's regex engine. Any
non-UTF-8 patterns will result in an error. `string` may contain
arbitrary bytes but ASCII compatible text is more useful, and UTF-8 is
more useful still. Other text encodings are not supported.

## Note

Patterns that can match the empty string (such as `"a*"`) will produce
additional zero-length matches, including a trailing empty match at the
end of each string. In the output this can manifest as a row where the
`start` value is greater than the `end` value (often where the `end`
value is `0`).

## See also

[re_detect](https://lj-jenkins.github.io/r-rure/reference/re_detect.md)
and
[re_where](https://lj-jenkins.github.io/r-rure/reference/re_where.md) to
return locations of vector element matches.

[nbytes](https://lj-jenkins.github.io/r-rure/reference/nbytes.md) to get
the number of bytes in each string.

## Examples

``` r
fruit <- c("apple", "banana", "pear", "pineapple")
re_find(fruit, "ap")
#>      start end
#> [1,]     1   2
#> [2,]    NA  NA
#> [3,]    NA  NA
#> [4,]     5   6
re_find(fruit, "ap", start = 2)
#>      start end
#> [1,]    NA  NA
#> [2,]    NA  NA
#> [3,]    NA  NA
#> [4,]     5   6

# rure operates on bytes - results may not be what
# you expect for multibyte characters.
regexec("caf\u00e9", "caf\u00e9 caf\u00e9")
#> [[1]]
#> [1] 1
#> attr(,"match.length")
#> [1] 4
#> 
re_find("caf\u00e9 caf\u00e9", "caf\u00e9")
#>      start end
#> [1,]     1   5

# 'zero'-length matches can occur
re_find("bear", "a*")
#>      start end
#> [1,]     1   0
```
