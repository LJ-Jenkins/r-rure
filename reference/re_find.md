# Find regex matches

Return the indices of elements in `string` that match regex patterns.

## Usage

``` r
re_find(string, pattern)

re_set_find(string, patterns)

re_set_find_each(string, patterns)
```

## Arguments

- string:

  Character vector.

- pattern:

  Pattern to look for (single string).

- patterns:

  Patterns to look for (character vector).

## Value

For `re_set_find()` and `re_set_find_each()`, an integer vector. For
`re_set_find_each()`, a list the length of `patterns` with each element
containing an integer vector.

## Details

`re_find()` returns the indices of elements in `string` that match
`pattern`.

`re_set_find()` does the same for a set of patterns, returning indices
of elements in `string` where **any** of the patterns match.

`re_set_find_each()` returns a list of integer vectors, where each list
element corresponds to a pattern in `patterns` and is filled with the
indices of elements in `string` that match the corresponding pattern.

No matches will result in an empty integer vector. For
`re_set_find_each()`, this will result in a list of empty integer
vectors.

## See also

[re_detect](https://lj-jenkins.github.io/r-rure/reference/re_detect.md)
for logical return values.

## Examples

``` r
fruit <- c("apple", "banana", "pear", "pineapple")
re_find(fruit, "a")
#> [1] 1 2 3 4
re_find(fruit, "^a")
#> [1] 1
re_find(fruit, "a$")
#> [1] 2
re_find(fruit, "b")
#> [1] 2
re_find(fruit, "[aeiou]")
#> [1] 1 2 3 4

re_set_find(fruit, c("a", "e"))
#> [1] 1 2 3 4
re_set_find_each(fruit, c("a", "e"))
#> [[1]]
#> [1] 1 2 3 4
#> 
#> [[2]]
#> [1] 1 3 4
#> 
```
