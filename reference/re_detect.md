# Detect regex matches

Return logical values indicating where regex patterns match the input
strings.

## Usage

``` r
re_detect(string, pattern)

re_set_detect(string, patterns)

re_set_detect_each(string, patterns)
```

## Arguments

- string:

  Character vector.

- pattern:

  Pattern to look for (single string).

- patterns:

  Patterns to look for (character vector).

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
non-UTF-8 patterns will result in an error.

## See also

[re_find](https://lj-jenkins.github.io/r-rure/reference/re_find.md) for
index return values.

## Examples

``` r
fruit <- c("apple", "banana", "pear", "pineapple")
re_detect(fruit, "a")
#> [1] TRUE TRUE TRUE TRUE
re_detect(fruit, "^a")
#> [1]  TRUE FALSE FALSE FALSE
re_detect(fruit, "a$")
#> [1] FALSE  TRUE FALSE FALSE
re_detect(fruit, "b")
#> [1] FALSE  TRUE FALSE FALSE
re_detect(fruit, "[aeiou]")
#> [1] TRUE TRUE TRUE TRUE

re_set_detect(fruit, c("a", "e"))
#> [1] TRUE TRUE TRUE TRUE
re_set_detect_each(fruit, c("a", "e"))
#>      [,1]  [,2]
#> [1,] TRUE  TRUE
#> [2,] TRUE FALSE
#> [3,] TRUE  TRUE
#> [4,] TRUE  TRUE
```
