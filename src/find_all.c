#include <Rinternals.h>
#include <string.h>
#include "rure.h"
#include "arg_checks.h"
#include "regex_compiler.h"
#include "buffers.h"
#include "matrix_fun.h"

SEXP r_rure_find_all(SEXP string, SEXP pattern, SEXP start)
{
    const char *pat = check_string_and_pattern(string, pattern);
    size_t start_off = check_start(start);
    R_xlen_t n = Rf_xlength(string);

    SEXP ans = PROTECT(Rf_allocVector(VECSXP, n));
    rure *re = compile_utf8_pattern(pat);

    for (R_xlen_t i = 0; i < n; i++)
    {
        SEXP s = STRING_ELT(string, i);
        if (s == NA_STRING)
        {
            SEXP mat = na_one_row_matrix();
            SET_VECTOR_ELT(ans, i, mat);
            UNPROTECT(1);
            continue;
        }

        const char *s_p = CHAR(s);
        size_t s_sz = (size_t)Rf_length(s);
        if (s_sz < start_off)
        {
            SEXP mat = na_one_row_matrix();
            SET_VECTOR_ELT(ans, i, mat);
            UNPROTECT(1);
            continue;
        }

        find_buffer buf;
        find_buffer_init(&buf);

        size_t offset = start_off;
        rure_match m;
        while (offset <= s_sz &&
               rure_find(re, (const uint8_t *)s_p, s_sz, offset, &m))
        {
            find_buffer_push(&buf, (R_xlen_t)m.start + 1, (R_xlen_t)m.end);
            offset = (m.end > offset) ? m.end : offset + 1;
        }

        if (buf.size == 0)
        {
            find_buffer_free(&buf);
            SEXP mat = na_one_row_matrix();
            SET_VECTOR_ELT(ans, i, mat);
            UNPROTECT(1);
            continue;
        }

        SEXP mat = PROTECT(Rf_allocMatrix(INTSXP, (int)buf.size, 2));
        int *mout = INTEGER(mat);
        for (R_xlen_t k = 0; k < buf.size; k++)
        {
            mout[k] = (int)buf.starts[k];
            mout[k + buf.size] = (int)buf.ends[k];
        }
        set_start_end_dimnames(mat);
        SET_VECTOR_ELT(ans, i, mat);
        UNPROTECT(1);
        find_buffer_free(&buf);
    }

    rure_free(re);
    UNPROTECT(1);
    return ans;
}