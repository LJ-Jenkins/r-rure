#ifndef _INDICES_H
#define _INDICES_H

#include <Rinternals.h>
#include <stdbool.h>
#include <string.h>

static inline void fill_indices(
    const R_xlen_t *indices,
    SEXP out,
    bool is_large,
    R_xlen_t n_indices)
{
    if (n_indices > 0)
    {
        if (is_large)
        {
            double *r = REAL(out);
            for (R_xlen_t i = 0; i < n_indices; i++)
                r[i] = (double)indices[i];
        }
        else
        {
            int *r = INTEGER(out);
            for (R_xlen_t i = 0; i < n_indices; ++i)
                r[i] = (int)indices[i];
        }
    }
}

#endif