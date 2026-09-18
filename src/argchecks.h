#ifndef _ARGCHECKS_H
#define _ARGCHECKS_H

#include <Rinternals.h>

static inline const char *check_string_and_pattern(SEXP string, SEXP pattern)
{
    if (TYPEOF(pattern) != STRSXP || Rf_xlength(pattern) != 1)
        Rf_error("`pattern` must be a single character string.");

    if (TYPEOF(string) != STRSXP)
        Rf_error("`string` must be a character vector.");

    SEXP p = STRING_ELT(pattern, 0);
    if (p == NA_STRING)
        Rf_error("`pattern` must not be NA.");

    const char *cp = CHAR(p);
    if (cp[0] == '\0')
        Rf_error("`pattern` must not be empty.");

    return cp;
}

typedef struct
{
    const char *ptr;
    size_t len;
} pattern_set;

static inline pattern_set *check_string_and_pattern_set(SEXP string, SEXP patterns, R_xlen_t np)
{
    if (TYPEOF(patterns) != STRSXP || np == 0)
        Rf_error("`patterns` must be a non-empty character vector.");

    if (TYPEOF(string) != STRSXP)
        Rf_error("`string` must be a character vector.");

    pattern_set *out = (pattern_set *)R_alloc(np, sizeof(pattern_set));

    for (R_xlen_t i = 0; i < np; i++)
    {
        SEXP p = STRING_ELT(patterns, i);
        if (p == NA_STRING)
            Rf_error("`patterns[%0.f]` must not be NA.", (double)(i + 1));

        const char *cp = CHAR(p);
        if (cp[0] == '\0')
            Rf_error("`patterns[%0.f]` must not be empty.", (double)(i + 1));

        out[i].ptr = cp;
        out[i].len = (size_t)strlen(cp);
    }

    return out;
}

#endif