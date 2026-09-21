
<!-- README.md is generated from README.Rmd. Please edit that file -->

# r-rure <img src="man/figures/logo.png" align="right" height="120" alt="" />

<!-- badges: start -->

<!-- badges: end -->

(R-) rure provides high-performance regex operations using the Rust
[regex crate](https://github.com/rust-lang/regex) (through the [rure C
API](https://github.com/rust-lang/regex/tree/master/regex-capi)).

- **NOTE:** This package is in development and is subject to significant
  change.

From the rure docs:

- rure is a C API to Rust’s regex library, which guarantees linear time
  searching using finite automata. In exchange, it must give up some
  common regex features such as backreferences and arbitrary lookaround.
  It does however include capturing groups, lazy matching, Unicode
  support and word boundary assertions. Its matching semantics generally
  correspond to Perl’s, or “leftmost first.” Namely, the match locations
  reported correspond to the first match that would be found by a
  backtracking engine.

Regular expressions must be UTF-8 compliant and are determined to be so
using Rust’s `str::from_utf8()`. However, haystacks do not have to be
UTF-8 compliant and no conversion to UTF-8 is performed. Whether invalid
UTF-8 is matched or not depends on the regular expression - see the
‘Text encoding’ section of the [rure C
API](https://github.com/rust-lang/regex/tree/master/regex-capi). Care
must be taken to ensure expected behaviour.

## Installation

You can install the development version of rure like so:

``` r
# install.packages("pak")
pak::pak("LJ-Jenkins/rure")
```

## Usage

``` r
library(rure)

x <- c("apple", "banana", "cherry")
```

#### Detect regex matches

``` r
re_detect(x, "a|b")
#> [1]  TRUE  TRUE FALSE
re_where(x, "a|b")
#> [1] 1 2
```

#### Detect regex matches for a set of patterns

``` r
re_set_detect(x, c("a|b", "c"))
#> [1] TRUE TRUE TRUE
re_set_where(x, c("a|b", "c"))
#> [1] 1 2 3
```

#### Detect regex matches for each pattern in a set

``` r
re_set_detect_each(x, c("a|b", "c"))
#>       [,1]  [,2]
#> [1,]  TRUE FALSE
#> [2,]  TRUE FALSE
#> [3,] FALSE  TRUE
re_set_where_each(x, c("a|b", "c"))
#> [[1]]
#> [1] 1 2
#> 
#> [[2]]
#> [1] 3
```

#### Find byte offsets of regex matches

``` r
re_find(x, "an")
#>      start end
#> [1,]    NA  NA
#> [2,]     2   3
#> [3,]    NA  NA
re_find(x, "an", start = 3)
#>      start end
#> [1,]    NA  NA
#> [2,]     4   5
#> [3,]    NA  NA
```

#### Escape regex metacharacters

``` r
x <- c(
  ".", "+", "*", "?", "(", ")", "[", "]",
  "{", "}", "|", "^", "$", "\\", "&", "-",
  "~", "#"
)
re_escape(x)
#>  [1] "\\."  "\\+"  "\\*"  "\\?"  "\\("  "\\)"  "\\["  "\\]"  "\\{"  "\\}" 
#> [11] "\\|"  "\\^"  "\\$"  "\\\\" "\\&"  "\\-"  "\\~"  "\\#"
```

## Benchmarks

For illustration only, these are not meant to be comprehensive or
definitive benchmarks.

``` r
x <- rep(paste0(letters, letters), 100000)
x_esc <- rep(c(
  ".", "+", "*", "?", "(", ")", "[", "]",
  "{", "}", "|", "^", "$", "\\"
  # "&", "-", "~", "#" # stringr doesn't escape these
), 100000)
```

    #> # A tibble: 4 × 2
    #>   expression                                   median
    #>   <bch:expr>                                 <bch:tm>
    #> 1 "re_detect(x, \"a|b|c\")"                      89ms
    #> 2 "re_set_detect(x, c(\"a|b\", \"c\"))"         102ms
    #> 3 "stringi::stri_detect_regex(x, \"a|b|c\")"    233ms
    #> 4 "grepl(\"a|b|c\", x)"                         200ms

    #> # A tibble: 4 × 2
    #>   expression                             median
    #>   <bch:expr>                           <bch:tm>
    #> 1 "re_where(x, \"a|b|c\")"                111ms
    #> 2 "re_set_where(x, c(\"a|b\", \"c\"))"    156ms
    #> 3 "stringr::str_which(x, \"a|b|c\")"      348ms
    #> 4 "grep(\"a|b|c\", x)"                    265ms

    #> # A tibble: 2 × 2
    #>   expression                                     median
    #>   <bch:expr>                                   <bch:tm>
    #> 1 "re_find(x, \"a\")"                             162ms
    #> 2 "stringi::stri_locate_first_regex(x, \"a\")"    378ms

    #> # A tibble: 2 × 2
    #>   expression                   median
    #>   <bch:expr>                 <bch:tm>
    #> 1 re_escape(x_esc)              218ms
    #> 2 stringr::str_escape(x_esc)    549ms
