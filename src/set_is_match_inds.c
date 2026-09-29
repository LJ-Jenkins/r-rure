#include <Rinternals.h>
#include <string.h>
#include "rure.h"
#include "arg_checks.h"
#include "regex_compiler.h"
#include "indices.h"

SEXP r_rure_set_is_match_inds(SEXP string, SEXP patterns, SEXP start)
{
    R_xlen_t np = Rf_xlength(patterns);
    pattern_set *pats = check_string_and_pattern_set(string, patterns, np);
    size_t start_off = check_start(start);

    R_xlen_t n = Rf_xlength(string);
    if (n == 0)
        return Rf_allocVector(INTSXP, 0);

    R_xlen_t *ans = (R_xlen_t *)R_alloc(n, sizeof(R_xlen_t));
    R_xlen_t j = 0;

    rure_set *re = compile_utf8_pattern_set(pats, np);

    for (R_xlen_t i = 0; i < n; i++)
    {
        SEXP s = STRING_ELT(string, i);
        if (s == NA_STRING)
            continue;

        const char *s_p = CHAR(s);
        R_xlen_t s_n = Rf_length(s);

        if (start_off > s_n)
            continue;

        int tf = rure_set_is_match(
            re,
            (const uint8_t *)s_p,
            (size_t)s_n,
            start_off);

        if (tf)
            ans[j++] = i + 1;
    }

    rure_set_free(re);

    bool large = j > INT_MAX;
    SEXP out = PROTECT(Rf_allocVector(large ? REALSXP : INTSXP, j));
    fill_indices(ans, out, large, j);

    UNPROTECT(1);
    return out;
}
