# Find locations of regex matches

Return the start and end offsets (in bytes) of regex matches within each
element of `string`.

## Usage

``` r
re_find(string, pattern, start = 1L)
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
and `end` offsets of the match. If no match is found, the row contains
`NA` values.

## Details

`string` may contain arbitrary bytes but ASCII compatible text is more
useful, and UTF-8 is more useful still. Other text encodings are not
supported.

No match will result in `NA` values in `start` and `end`. The same will
occur for elements of `string` that are shorter than the specified
`start` offset.

Patterns must be valid UTF-8 to work with Rust's regex engine. Any
non-UTF-8 patterns will result in an error.

## See also

[re_detect](https://lj-jenkins.github.io/r-rure/reference/re_detect.md)
for logical return values.

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
```
