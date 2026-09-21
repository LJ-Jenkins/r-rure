#ifndef _OUT_NAMES_H
#define _OUT_NAMES_H

#include <Rinternals.h>

static inline SEXP set_start_end_dimnames(SEXP out)
{
    SEXP dimnames = PROTECT(Rf_allocVector(VECSXP, 2));
    SEXP colnames = PROTECT(Rf_allocVector(STRSXP, 2));
    SET_STRING_ELT(colnames, 0, Rf_mkChar("start"));
    SET_STRING_ELT(colnames, 1, Rf_mkChar("end"));
    SET_VECTOR_ELT(dimnames, 0, R_NilValue);
    SET_VECTOR_ELT(dimnames, 1, colnames);
    Rf_setAttrib(out, R_DimNamesSymbol, dimnames);
    UNPROTECT(2);
    return out;
}

#endif