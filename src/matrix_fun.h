#ifndef _MATRIX_FILL_H
#define _MATRIX_FILL_H

#include <R.h>

static inline SEXP get_start_end_dimnames(void)
{
    SEXP dimnames = PROTECT(Rf_allocVector(VECSXP, 2));
    SEXP colnames = PROTECT(Rf_allocVector(STRSXP, 2));
    SET_STRING_ELT(colnames, 0, Rf_mkChar("start"));
    SET_STRING_ELT(colnames, 1, Rf_mkChar("end"));
    SET_VECTOR_ELT(dimnames, 0, R_NilValue);
    SET_VECTOR_ELT(dimnames, 1, colnames);
    UNPROTECT(2);
    return dimnames;
}

static inline SEXP na_one_row_matrix(SEXP dimnames)
{
    SEXP mat = PROTECT(Rf_allocMatrix(INTSXP, 1, 2));
    int *p = INTEGER(mat);
    p[0] = NA_INTEGER;
    p[1] = NA_INTEGER;
    Rf_setAttrib(mat, R_DimNamesSymbol, dimnames);
    UNPROTECT(1);
    return mat;
}

static inline SEXP get_matches_captures_names(void)
{
    SEXP nm = PROTECT(Rf_allocVector(STRSXP, 2));
    SET_STRING_ELT(nm, 0, Rf_mkChar("matches"));
    SET_STRING_ELT(nm, 1, Rf_mkChar("captures"));
    UNPROTECT(1);
    return nm;
}

static inline SEXP build_matches_captures(SEXP matches_mat, SEXP captures_list, SEXP nm)
{
    SEXP elt = PROTECT(Rf_allocVector(VECSXP, 2));
    SET_VECTOR_ELT(elt, 0, matches_mat);
    SET_VECTOR_ELT(elt, 1, captures_list);

    Rf_setAttrib(elt, R_NamesSymbol, nm);

    UNPROTECT(1);
    return elt;
}

#endif