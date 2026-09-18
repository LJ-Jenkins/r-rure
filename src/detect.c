#include <Rinternals.h>
#include <string.h>
#include "rure.h"
#include "argchecks.h"
#include "regex_compiler.h"

SEXP ffi_re_detect(SEXP string, SEXP pattern)
{
    const char *pat = check_string_and_pattern(string, pattern);

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
        out[i] = rure_is_match(
            re,
            (const uint8_t *)s_p,
            (size_t)strlen(s_p),
            0);
    }

    rure_free(re);

    UNPROTECT(1);
    return ans;
}
