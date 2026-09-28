#include <Rinternals.h>
#include <R.h>
#include <string.h>
#include "rure.h"
#include "arg_checks.h"
#include "regex_compiler.h"
#include "buffers.h"

SEXP r_rure_set_is_match_inds_each(SEXP string, SEXP patterns)
{
    R_xlen_t np = Rf_xlength(patterns);
    pattern_set *pats = check_string_and_pattern_set(string, patterns, np);

    R_xlen_t n = Rf_xlength(string);

    SEXP ans = PROTECT(Rf_allocVector(VECSXP, np));

    if (n == 0)
    {
        for (R_xlen_t j = 0; j < np; j++)
            SET_VECTOR_ELT(ans, j, Rf_allocVector(INTSXP, 0));

        UNPROTECT(1);
        return ans;
    }

    rure_set *re = compile_utf8_pattern_set(pats, np);

    bool *m = (bool *)R_alloc(np, sizeof(bool));

    index_buffer *bufs = (index_buffer *)R_alloc(np, sizeof(index_buffer));
    for (R_xlen_t j = 0; j < np; j++)
        index_buffer_init(&bufs[j]);

    for (R_xlen_t i = 0; i < n; i++)
    {
        SEXP s = STRING_ELT(string, i);
        if (s == NA_STRING)
            continue;

        const char *s_p = CHAR(s);

        rure_set_matches(
            re,
            (const uint8_t *)s_p,
            (size_t)Rf_length(s),
            0,
            m);

        // for buffer 'j', append the index (+1 for R) if match
        for (R_xlen_t j = 0; j < np; j++)
            if (m[j])
                index_buffer_push(&bufs[j], i + 1);
    }

    rure_set_free(re);

    bool large = n > INT_MAX;

    // buffers to R vectors
    for (R_xlen_t j = 0; j < np; j++)
    {
        // pointer to buffer and size of the vector
        index_buffer *buf = &bufs[j];
        R_xlen_t k = buf->size;

        if (large)
        {
            SEXP x = PROTECT(Rf_allocVector(REALSXP, k));
            double *out = REAL(x);

            for (R_xlen_t i = 0; i < k; i++)
                out[i] = (double)buf->data[i];

            SET_VECTOR_ELT(ans, j, x);
            UNPROTECT(1);
        }
        else
        {
            SEXP x = PROTECT(Rf_allocVector(INTSXP, k));
            int *out = INTEGER(x);

            for (R_xlen_t i = 0; i < k; i++)
                out[i] = (int)buf->data[i];

            SET_VECTOR_ELT(ans, j, x);
            UNPROTECT(1);
        }

        index_buffer_free(buf);
    }

    UNPROTECT(1);
    return ans;
}
