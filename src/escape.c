#include <Rinternals.h>
#include <string.h>
#include "rure.h"
#include "rurerlib/api.h"

SEXP ffi_escape(SEXP string)
{
    if (TYPEOF(string) != STRSXP)
    {
        Rf_error("`string` must be a character vector.");
    }

    R_xlen_t n = Rf_xlength(string);
    if (n == 0)
        return Rf_allocVector(STRSXP, 0);

    SEXP ans = PROTECT(Rf_allocVector(STRSXP, n));

    for (R_xlen_t i = 0; i < n; ++i)
    {
        SEXP s = STRING_ELT(string, i);
        if (s == NA_STRING)
        {
            SET_STRING_ELT(ans, i, NA_STRING);
            continue;
        }

        const char *x = CHAR(s);
        char *result = NULL;

        int status = rust_escape(
            (const uint8_t *)x,
            (size_t)strlen(x),
            &result);

        if (status < 0)
            Rf_error("input is not valid UTF-8.");

        SET_STRING_ELT(ans, i, Rf_mkChar(result));

        rure_cstring_free(result);
    }

    UNPROTECT(1);
    return ans;
}
