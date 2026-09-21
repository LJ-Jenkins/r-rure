#include <Rinternals.h>
#include <string.h>
#include "rure.h"
#include "argchecks.h"
#include "regex_compiler.h"
#include "out_names.h"

SEXP ffi_find(SEXP string, SEXP pattern, SEXP start)
{
    const char *pat = check_string_and_pattern(string, pattern);
    size_t start_off = check_start(start);

    R_xlen_t n = Rf_xlength(string);
    if (n == 0)
    {
        SEXP ans = PROTECT(Rf_allocMatrix(INTSXP, 0, 2));
        ans = set_start_end_dimnames(ans);
        UNPROTECT(1);
        return ans;
    }

    SEXP ans = PROTECT(Rf_allocMatrix(INTSXP, (int)n, 2));
    int *out = INTEGER(ans);
    int *start_col = out;
    int *end_col = out + n;

    rure *re = compile_utf8_pattern(pat);

    for (R_xlen_t i = 0; i < n; i++)
    {
        SEXP s = STRING_ELT(string, i);
        if (s == NA_STRING)
        {
            start_col[i] = NA_INTEGER;
            end_col[i] = NA_INTEGER;
            continue;
        }

        const char *s_p = CHAR(s);

        size_t s_sz = (size_t)strlen(s_p);

        if (s_sz < start_off)
        {
            start_col[i] = NA_INTEGER;
            end_col[i] = NA_INTEGER;
            continue;
        }

        rure_match match = {0, 0};

        bool found = rure_find(
            re,
            (const uint8_t *)s_p,
            s_sz,
            start_off,
            &match);

        if (found)
        {
            start_col[i] = (int)match.start + 1;
            end_col[i] = (int)match.end;
        }
        else
        {
            start_col[i] = NA_INTEGER;
            end_col[i] = NA_INTEGER;
        }
    }

    rure_free(re);

    ans = set_start_end_dimnames(ans);
    UNPROTECT(1);
    return ans;
}