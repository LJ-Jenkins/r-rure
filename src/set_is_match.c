#include <Rinternals.h>
#include <string.h>
#include "rure.h"
#include "argchecks.h"
#include "regex_compiler.h"

SEXP ffi_set_is_match(SEXP string, SEXP patterns)
{
    R_xlen_t np = Rf_xlength(patterns);
    pattern_set *pats = check_string_and_pattern_set(string, patterns, np);

    R_xlen_t n = Rf_xlength(string);
    if (n == 0)
        return Rf_allocVector(LGLSXP, 0);

    SEXP ans = PROTECT(Rf_allocVector(LGLSXP, n));
    int *out = LOGICAL(ans);

    rure_set *re = compile_utf8_pattern_set(pats, np);

    for (R_xlen_t i = 0; i < n; i++)
    {
        SEXP s = STRING_ELT(string, i);
        if (s == NA_STRING)
        {
            out[i] = NA_LOGICAL;
            continue;
        }

        const char *s_p = CHAR(s);
        out[i] = rure_set_is_match(
            re,
            (const uint8_t *)s_p,
            (size_t)strlen(s_p),
            0);
    }

    rure_set_free(re);

    UNPROTECT(1);
    return ans;
}
