#ifndef _MATRIX_FILL_H
#define _MATRIX_FILL_H

#include <R.h>

static inline void set_start_end_dimnames(SEXP out)
{
    SEXP dimnames = PROTECT(Rf_allocVector(VECSXP, 2));
    SEXP colnames = PROTECT(Rf_allocVector(STRSXP, 2));
    SET_STRING_ELT(colnames, 0, Rf_mkChar("start"));
    SET_STRING_ELT(colnames, 1, Rf_mkChar("end"));
    SET_VECTOR_ELT(dimnames, 0, R_NilValue);
    SET_VECTOR_ELT(dimnames, 1, colnames);
    Rf_setAttrib(out, R_DimNamesSymbol, dimnames);
    UNPROTECT(2);
}

// caller needs to unprotect

static inline SEXP match_to_matrix(rure_match m)
{
    SEXP mat = PROTECT(Rf_allocMatrix(INTSXP, 1, 2));
    int *p = INTEGER(mat);
    p[0] = (int)m.start + 1;
    p[1] = (int)m.end;
    set_start_end_dimnames(mat);
    return mat;
}

static inline SEXP na_one_row_matrix(void)
{
    SEXP mat = PROTECT(Rf_allocMatrix(INTSXP, 1, 2));
    int *p = INTEGER(mat);
    p[0] = NA_INTEGER;
    p[1] = NA_INTEGER;
    set_start_end_dimnames(mat);
    return mat;
}

static inline SEXP na_n_row_matrix(R_xlen_t n)
{
    SEXP mat = PROTECT(Rf_allocMatrix(INTSXP, (int)n, 2));
    int *p = INTEGER(mat);
    for (R_xlen_t i = 0; i < n; i++)
    {
        p[i] = NA_INTEGER;
        p[i + n] = NA_INTEGER;
    }
    set_start_end_dimnames(mat);
    return mat;
}

/* Fill row `i` of the capture-group matrices from `caps`.
 * `cg` is the VECSXP produced by make_capture_groups_attr; it holds `ncap`
 * (n x 2) INT matrices. `n` is the number of strings.
 */
static inline void fill_capture_groups_row(SEXP cg, R_xlen_t n, R_xlen_t i,
                                           int ncap, rure_captures *caps)
{
    for (int g = 0; g < ncap; g++)
    {
        SEXP m = VECTOR_ELT(cg, g);
        int *p = INTEGER(m);
        rure_match mg = {0};
        if (rure_captures_at(caps, g + 1, &mg))
        {
            p[i] = (int)mg.start + 1;
            p[i + n] = (int)mg.end;
        }
        else
        {
            p[i] = NA_INTEGER;
            p[i + n] = NA_INTEGER;
        }
    }
}

#endif