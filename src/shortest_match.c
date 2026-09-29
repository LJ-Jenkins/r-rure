#include <Rinternals.h>
#include <string.h>
#include "rure.h"
#include "arg_checks.h"
#include "regex_compiler.h"
#include "indices.h"

SEXP r_rure_shortest_match_offset(SEXP string, SEXP pattern, SEXP start)
{
    const char *pat = check_string_and_pattern(string, pattern);
    size_t start_off = check_start(start);

    R_xlen_t n = Rf_xlength(string);
    if (n == 0)
        return Rf_allocVector(INTSXP, 0);

    SEXP ans = PROTECT(Rf_allocVector(INTSXP, n));
    int *out = INTEGER(ans);

    rure *re = compile_utf8_pattern(pat);

    for (R_xlen_t i = 0; i < n; i++)
    {
        SEXP s = STRING_ELT(string, i);
        if (s == NA_STRING)
        {
            out[i] = NA_INTEGER;
            continue;
        }

        const char *s_p = CHAR(s);
        R_xlen_t s_sz = Rf_length(s);

        if (start_off > s_sz)
        {
            out[i] = NA_INTEGER;
            continue;
        }

        size_t end = 0;
        bool found = rure_shortest_match(
            re,
            (const uint8_t *)s_p,
            (size_t)s_sz,
            start_off,
            &end);

        out[i] = found ? (int)end : NA_INTEGER;
    }

    rure_free(re);
    UNPROTECT(1);
    return ans;
}

SEXP r_rure_shortest_match_lgl(SEXP string, SEXP pattern, SEXP start)
{
    const char *pat = check_string_and_pattern(string, pattern);
    size_t start_off = check_start(start);

    R_xlen_t n = Rf_xlength(string);
    if (n == 0)
        return Rf_allocVector(LGLSXP, 0);

    SEXP ans = PROTECT(Rf_allocVector(LGLSXP, n));
    int *out = LOGICAL(ans);

    rure *re = compile_utf8_pattern(pat);

    for (R_xlen_t i = 0; i < n; i++)
    {
        SEXP s = STRING_ELT(string, i);
        if (s == NA_STRING)
        {
            out[i] = NA_LOGICAL;
            continue;
        }

        const char *s_p = CHAR(s);
        R_xlen_t s_sz = Rf_length(s);

        if (start_off > s_sz)
        {
            out[i] = 0;
        }
        else
        {
            out[i] = rure_shortest_match(
                re,
                (const uint8_t *)s_p,
                (size_t)s_sz,
                start_off,
                NULL);
        }
    }

    rure_free(re);
    UNPROTECT(1);
    return ans;
}

SEXP r_rure_shortest_match_inds(SEXP string, SEXP pattern, SEXP start)
{
    const char *pat = check_string_and_pattern(string, pattern);
    size_t start_off = check_start(start);

    R_xlen_t n = Rf_xlength(string);
    if (n == 0)
        return Rf_allocVector(INTSXP, 0);

    R_xlen_t *ans = (R_xlen_t *)R_alloc(n, sizeof(R_xlen_t));
    R_xlen_t j = 0;

    rure *re = compile_utf8_pattern(pat);

    for (R_xlen_t i = 0; i < n; i++)
    {
        SEXP s = STRING_ELT(string, i);
        if (s == NA_STRING)
            continue;

        const char *s_p = CHAR(s);
        R_xlen_t s_sz = Rf_length(s);

        if (start_off > s_sz)
            continue;

        bool tf = rure_shortest_match(
            re,
            (const uint8_t *)s_p,
            (size_t)s_sz,
            start_off,
            NULL);

        if (tf)
            ans[j++] = i + 1;
    }

    rure_free(re);

    bool large = j > INT_MAX;
    SEXP out = PROTECT(Rf_allocVector(large ? REALSXP : INTSXP, j));
    fill_indices(ans, out, large, j);

    UNPROTECT(1);
    return out;
}