#include <Rinternals.h>
#include <string.h>
#include "rure.h"
#include "argchecks.h"
#include "regex_compiler.h"

SEXP ffi_set_is_match_each(SEXP string, SEXP patterns)
{
    R_xlen_t np = Rf_xlength(patterns);
    pattern_set *pats = check_string_and_pattern_set(string, patterns, np);

    R_xlen_t n = Rf_xlength(string);
    if (n == 0)
        return Rf_allocMatrix(LGLSXP, 0, (int)np);

    SEXP ans = PROTECT(Rf_allocMatrix(LGLSXP, n, (int)np));
    int *out = LOGICAL(ans);
    bool *m = (bool *)R_alloc(np, sizeof(bool));

    rure_set *re = compile_utf8_pattern_set(pats, np);

    for (R_xlen_t i = 0; i < n; i++)
    {
        SEXP s = STRING_ELT(string, i);
        if (s == NA_STRING)
        {
            for (R_xlen_t j = 0; j < np; j++)
                out[i + n * j] = NA_LOGICAL;

            continue;
        }

        const char *s_p = CHAR(s);
        rure_set_matches(
            re,
            (const uint8_t *)s_p,
            (size_t)strlen(s_p),
            0,
            m);

        for (R_xlen_t j = 0; j < np; j++)
            out[i + n * j] = m[j];
    }

    rure_set_free(re);

    UNPROTECT(1);
    return ans;
}
