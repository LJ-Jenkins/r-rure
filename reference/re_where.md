# Find elements where regex match occurs

Return the indices of elements in `string` that match regex patterns.

## Usage

``` r
re_where(string, pattern)

re_set_where(string, patterns)

re_set_where_each(string, patterns)
```

## Arguments

- string:

  Character vector.

- pattern:

  Pattern to look for (single string).

- patterns:

  Patterns to look for (character vector).

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
non-UTF-8 patterns will result in an error.

## See also

[re_detect](https://lj-jenkins.github.io/r-rure/reference/re_detect.md)
for logical return values.

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
```
