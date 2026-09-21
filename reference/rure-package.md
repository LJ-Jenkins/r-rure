# rure: Bindings to the 'Rust' 'regex' Crate Through the 'rure' C API

Provides bindings to the 'Rust' 'regex' crate through the 'rure' C API,
giving access to high-performance regular expression operations for
'UTF-8' compliant patterns. The 'regex' crate guarantees linear time
searching using finite automata. In exchange, it does not include some
common regex features such as backreferences and arbitrary lookaround.
However, it does include capturing groups, lazy matching, 'Unicode'
support and word boundary assertions. Matching semantics generally
correspond to 'Perl', or "leftmost first". Namely, the match locations
reported correspond to the first match that would be found by a
backtracking engine.

## See also

Useful links:

- <https://lj-jenkins.github.io/r-rure/>

- <https://github.com/LJ-Jenkins/r-rure>

- Report bugs at <https://github.com/LJ-Jenkins/r-rure/issues>

## Author

**Maintainer**: Luke Jenkins <luke-jenkins-dev@outlook.com>
([ORCID](https://orcid.org/0000-0002-7206-7242))

Authors:

- Luke Jenkins <luke-jenkins-dev@outlook.com>
  ([ORCID](https://orcid.org/0000-0002-7206-7242))

- Authors of the dependency Rust crates (see inst/AUTHORS file)
