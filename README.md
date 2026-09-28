
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
pak::pak("LJ-Jenkins/r-rure")
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
re_find_all(x, "e|a")
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
#> [1,]     3   3
```

#### Find byte offsets for capture groups

``` r
x <- c("a=1;b=2", "c=3;d=4")
re_find_captures(x, "(?<x>\\w+)=(?<y>\\w+)")
#> $matches
#>      start end
#> [1,]     1   3
#> [2,]     1   3
#> 
#> $captures
#> $captures$x
#>      start end
#> [1,]     1   1
#> [2,]     1   1
#> 
#> $captures$y
#>      start end
#> [1,]     3   3
#> [2,]     3   3
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
x_cap <- rep(paste0(letters, "=", letters, ";", letters, "=", letters), 1000)
x_esc <- rep(c(
  ".", "+", "*", "?", "(", ")", "[", "]",
  "{", "}", "|", "^", "$", "\\"
  # "&", "-", "~", "#" # stringr doesn't escape these
), 100000)
```

    #> # A tibble: 4 × 2
    #>   expression                                   median
    #>   <bch:expr>                                 <bch:tm>
    #> 1 "re_detect(x, \"a|b|c\")"                    80.8ms
    #> 2 "re_set_detect(x, c(\"a|b\", \"c\"))"        91.9ms
    #> 3 "stringi::stri_detect_regex(x, \"a|b|c\")"  170.4ms
    #> 4 "grepl(\"a|b|c\", x)"                         139ms

    #> # A tibble: 4 × 2
    #>   expression                             median
    #>   <bch:expr>                           <bch:tm>
    #> 1 "re_where(x, \"a|b|c\")"               81.4ms
    #> 2 "re_set_where(x, c(\"a|b\", \"c\"))"   94.3ms
    #> 3 "stringr::str_which(x, \"a|b|c\")"    174.9ms
    #> 4 "grep(\"a|b|c\", x)"                  145.3ms

    #> # A tibble: 2 × 2
    #>   expression                                     median
    #>   <bch:expr>                                   <bch:tm>
    #> 1 "re_find(x, \"a\")"                            72.9ms
    #> 2 "stringi::stri_locate_first_regex(x, \"a\")"  177.3ms

    #> # A tibble: 2 × 2
    #>   expression                                                              median
    #>   <bch:expr>                                                              <bch:>
    #> 1 "re_find_captures(x_cap, \"(?<x>\\\\w+)=(?<y>\\\\w+)\")"                2.85ms
    #> 2 "stringi::stri_locate_first_regex(x_cap, \"(?<x>\\\\w+)=(?<y>\\\\w+)\"… 3.72ms

    #> # A tibble: 2 × 2
    #>   expression                                       median
    #>   <bch:expr>                                     <bch:tm>
    #> 1 "re_find_all(x_cap, \"a\")"                         5ms
    #> 2 "stringi::stri_locate_all_regex(x_cap, \"a\")"   5.66ms

    #> # A tibble: 2 × 2
    #>   expression                   median
    #>   <bch:expr>                 <bch:tm>
    #> 1 re_escape(x_esc)              143ms
    #> 2 stringr::str_escape(x_esc)    279ms
