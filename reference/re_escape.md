# Escape regex special characters

`re_escape()` returns a character vector with all regex special
characters escaped.

## Usage

``` r
re_escape(string)
```

## Arguments

- string:

  Character vector.

## Value

A character vector the same length as `string`.

## Details

Inputs must be valid UTF-8 to work with Rust's regex engine. Any
non-UTF-8 elements will result in an error.

`NA` values are preserved and returned as `NA` in the output - but note
`NA` is not a valid pattern for rure.

## Examples

``` r
re_escape(".")
#> [1] "\\."
```
