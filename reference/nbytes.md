# Get the number of bytes.

Get the number of bytes in each string of a character vector.

## Usage

``` r
nbytes(x)
```

## Arguments

- x:

  A character vector.

## Value

An integer vector giving the number of bytes in each string.

## Details

Simple wrapper around `nchar(x, type = "bytes")`.

`NA` values are preserved in the output.

## Examples

``` r
nbytes(c("a", "ab", "abc"))
#> [1] 1 2 3
nbytes("caf\u00e9")
#> [1] 5
```
