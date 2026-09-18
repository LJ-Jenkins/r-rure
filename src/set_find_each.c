#include <Rinternals.h>
#include <R.h>
#include <string.h>
#include "rure.h"
#include "argchecks.h"
#include "regex_compiler.h"

typedef struct
{
    R_xlen_t *data;
    R_xlen_t size;
    R_xlen_t capacity;
} index_buffer;

static void index_buffer_init(index_buffer *buf)
{
    buf->data = NULL;
    buf->size = 0;
    buf->capacity = 0;
}

static void index_buffer_push(index_buffer *buf, R_xlen_t value)
{
    if (buf->size == buf->capacity)
    {
        // init 16 slots; double thereafter.
        R_xlen_t new_capacity = buf->capacity == 0 ? 16 : buf->capacity * 2;

        buf->data = (R_xlen_t *)R_Realloc(buf->data, new_capacity, R_xlen_t);
        buf->capacity = new_capacity;
    }

    buf->data[buf->size++] = value;
}

static void index_buffer_free(index_buffer *buf)
{
    // R_Free sets buf->data to NULL, see writing R ext 6.1.2.
    R_Free(buf->data);
    buf->size = 0;
    buf->capacity = 0;
}

SEXP ffi_re_set_find_each(SEXP string, SEXP patterns)
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
            (size_t)strlen(s_p),
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