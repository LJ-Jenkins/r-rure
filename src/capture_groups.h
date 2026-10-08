#ifndef _CAPTURE_GROUPS_H
#define _CAPTURE_GROUPS_H

#include <R.h>
#include "rure.h"
#include "matrix_fun.h"

static inline SEXP capture_group_names(int ncap, rure *re)
{
    if (ncap > 0)
    {
        SEXP nm = PROTECT(Rf_allocVector(STRSXP, ncap));
        rure_iter_capture_names *it = rure_iter_capture_names_new(re);
        char *name;
        while (rure_iter_capture_names_next(it, &name))
        {
            int32_t idx = rure_capture_name_index(re, name);
            if (idx >= 1 && idx <= ncap)
                SET_STRING_ELT(nm, idx - 1, Rf_mkChar(name));
        }
        rure_iter_capture_names_free(it);
        UNPROTECT(1);
        return nm;
    }
    return R_NilValue;
}

static inline SEXP make_capture_groups(int ncap, SEXP names)
{
    SEXP cg = PROTECT(Rf_allocVector(VECSXP, ncap));

    if (ncap > 0)
        Rf_setAttrib(cg, R_NamesSymbol, names);

    UNPROTECT(1);
    return cg;
}

#endif
