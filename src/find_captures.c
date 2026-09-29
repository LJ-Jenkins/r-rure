#include <R.h>
#include <Rinternals.h>
#include <string.h>
#include "rure.h"
#include "arg_checks.h"
#include "regex_compiler.h"
#include "matrix_fun.h"
#include "capture_groups.h"

SEXP r_rure_find_captures(SEXP string, SEXP pattern, SEXP start)
{
    const char *pat = check_string_and_pattern(string, pattern);
    size_t start_off = check_start(start);

    R_xlen_t n = Rf_xlength(string);

    SEXP ans = PROTECT(Rf_allocMatrix(INTSXP, (int)n, 2));
    int *g0_start = INTEGER(ans);
    int *g0_end = g0_start + n;

    rure *re = compile_utf8_pattern(pat);
    rure_captures *caps = rure_captures_new(re);

    int32_t ngroups = (int32_t)rure_captures_len(caps); // includes group 0
    int ncap = ngroups - 1;
    if (ncap < 0)
        ncap = 0;

    SEXP cap_names = PROTECT(capture_group_names(ncap, re));
    SEXP cg = PROTECT(make_capture_groups(ncap, cap_names));
    SEXP dimnames = PROTECT(get_start_end_dimnames());

    for (int g = 0; g < ncap; g++)
    {
        SEXP mat = PROTECT(Rf_allocMatrix(INTSXP, (int)n, 2));
        Rf_setAttrib(mat, R_DimNamesSymbol, dimnames);
        SET_VECTOR_ELT(cg, g, mat);
        UNPROTECT(1);
    }

    for (R_xlen_t i = 0; i < n; i++)
    {
        SEXP s = STRING_ELT(string, i);

        bool ok = false;
        if (s != NA_STRING)
        {
            const char *s_p = CHAR(s);
            size_t s_sz = (size_t)Rf_length(s);
            if (start_off <= s_sz)
            {
                ok = rure_find_captures(
                    re, (const uint8_t *)s_p, s_sz, start_off, caps);
            }
        }

        if (!ok)
        {
            g0_start[i] = NA_INTEGER;
            g0_end[i] = NA_INTEGER;
            for (int g = 0; g < ncap; g++)
            {
                SEXP mat = VECTOR_ELT(cg, g);
                int *p = INTEGER(mat);
                p[i] = NA_INTEGER;
                p[i + n] = NA_INTEGER;
            }
            continue;
        }

        rure_match m = {0};
        rure_captures_at(caps, 0, &m);
        g0_start[i] = (int)m.start + 1;
        g0_end[i] = (int)m.end;

        for (int g = 0; g < ncap; g++)
        {
            SEXP mat = VECTOR_ELT(cg, g);
            int *p = INTEGER(mat);
            rure_match m = {0};
            if (rure_captures_at(caps, g + 1, &m))
            {
                p[i] = (int)m.start + 1;
                p[i + n] = (int)m.end;
            }
            else
            {
                p[i] = NA_INTEGER;
                p[i + n] = NA_INTEGER;
            }
        }
    }

    Rf_setAttrib(ans, R_DimNamesSymbol, dimnames);

    SEXP out = PROTECT(Rf_allocVector(VECSXP, 2));
    SET_VECTOR_ELT(out, 0, ans);
    SET_VECTOR_ELT(out, 1, cg);

    SEXP out_nm = PROTECT(Rf_allocVector(STRSXP, 2));
    SET_STRING_ELT(out_nm, 0, Rf_mkChar("matches"));
    SET_STRING_ELT(out_nm, 1, Rf_mkChar("captures"));
    Rf_setAttrib(out, R_NamesSymbol, out_nm);

    rure_captures_free(caps);
    rure_free(re);
    UNPROTECT(6); // out_nm, out, cg, ans, cap_names, dimnames
    return out;
}
