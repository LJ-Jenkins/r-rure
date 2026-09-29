#include <Rinternals.h>
#include <string.h>
#include "rure.h"
#include "arg_checks.h"
#include "regex_compiler.h"
#include "find_buffer.h"
#include "matrix_fun.h"
#include "capture_groups.h"

static inline SEXP one_row_na_captures(int ncap, SEXP names, SEXP dimnames)
{
    SEXP cg = PROTECT(make_capture_groups(ncap, names));

    for (int g = 0; g < ncap; g++)
    {
        SEXP mat = PROTECT(na_one_row_matrix(dimnames));
        SET_VECTOR_ELT(cg, g, mat);
        UNPROTECT(1);
    }

    UNPROTECT(1);
    return cg;
}

// SEXP r_rure_find_all_captures(SEXP string, SEXP pattern, SEXP start)
// {
//     const char *pat = check_string_and_pattern(string, pattern);
//     size_t start_off = check_start(start);

//     R_xlen_t n = Rf_xlength(string);

//     rure *re = compile_utf8_pattern(pat);
//     rure_captures *caps = rure_captures_new(re);

//     int32_t ngroups = (int32_t)rure_captures_len(caps);
//     int ncap = ngroups > 0 ? ngroups - 1 : 0;

//     SEXP ans = PROTECT(Rf_allocVector(VECSXP, n));
//     SEXP cap_names = PROTECT(capture_group_names(ncap, re));
//     SEXP dimnames = PROTECT(get_start_end_dimnames());
//     SEXP matches_captures_names = PROTECT(get_matches_captures_names());

//     find_buffer *bufs = (find_buffer *)R_alloc(ncap + 1, sizeof(find_buffer));
//     for (int g = 0; g <= ncap; g++)
//         find_buffer_init(&bufs[g]);

//     for (R_xlen_t i = 0; i < n; i++)
//     {
//         for (int g = 0; g <= ncap; g++)
//             bufs[g].size = 0;

//         SEXP s = STRING_ELT(string, i);
//         bool ok = false;

//         if (s != NA_STRING)
//         {
//             const char *s_p = CHAR(s);
//             size_t s_sz = (size_t)Rf_length(s);

//             if (start_off <= s_sz)
//             {
//                 ok = true;
//                 size_t offset = start_off;
//                 rure_match m;

//                 while (offset <= s_sz &&
//                        rure_find_captures(
//                            re,
//                            (const uint8_t *)s_p,
//                            s_sz,
//                            offset,
//                            caps))
//                 {
//                     // Record group 0 (whole match) first
//                     rure_captures_at(caps, 0, &m);
//                     find_buffer_push(&bufs[0],
//                                      (R_xlen_t)m.start + 1,
//                                      (R_xlen_t)m.end);

//                     // Record each capture group
//                     for (int g = 1; g <= ncap; g++)
//                     {
//                         rure_match gm;
//                         if (rure_captures_at(caps, (size_t)g, &gm))
//                             find_buffer_push(&bufs[g],
//                                              (R_xlen_t)gm.start + 1,
//                                              (R_xlen_t)gm.end);
//                         else
//                             find_buffer_push(&bufs[g],
//                                              (R_xlen_t)NA_INTEGER,
//                                              (R_xlen_t)NA_INTEGER);
//                     }

//                     // Advance: step past the end of the match, guarding
//                     // against zero-width matches.
//                     if (m.end > offset)
//                         offset = m.end;
//                     else
//                         offset++;
//                 }
//             }
//         }

//         // NA string, too-short string, or no matches found.
//         if (!ok || bufs[0].size == 0)
//         {
//             SEXP mat = PROTECT(na_one_row_matrix(dimnames));
//             SEXP cg = PROTECT(one_row_na_captures(ncap, cap_names, dimnames));
//             SEXP elt = PROTECT(build_matches_captures(mat, cg, matches_captures_names));
//             SET_VECTOR_ELT(ans, i, elt);
//             UNPROTECT(3);
//             continue;
//         }

//         R_xlen_t k = bufs[0].size;

//         SEXP mat = PROTECT(Rf_allocMatrix(INTSXP, (int)k, 2));
//         int *mout = INTEGER(mat);
//         for (R_xlen_t r = 0; r < k; r++)
//         {
//             mout[r] = (int)bufs[0].starts[r];
//             mout[r + k] = (int)bufs[0].ends[r];
//         }
//         Rf_setAttrib(mat, R_DimNamesSymbol, dimnames);

//         SEXP cg = PROTECT(make_capture_groups(ncap, cap_names));
//         for (int g = 0; g < ncap; g++)
//         {
//             SEXP cm = PROTECT(Rf_allocMatrix(INTSXP, (int)k, 2));
//             int *cout = INTEGER(cm);
//             for (R_xlen_t r = 0; r < k; r++)
//             {
//                 cout[r] = (int)bufs[g + 1].starts[r];
//                 cout[r + k] = (int)bufs[g + 1].ends[r];
//             }
//             Rf_setAttrib(cm, R_DimNamesSymbol, dimnames);
//             SET_VECTOR_ELT(cg, g, cm);
//             UNPROTECT(1);
//         }

//         SEXP elt = PROTECT(build_matches_captures(mat, cg, matches_captures_names));
//         SET_VECTOR_ELT(ans, i, elt);
//         UNPROTECT(3);
//     }

//     for (int g = 0; g <= ncap; g++)
//         find_buffer_free(&bufs[g]);

//     rure_captures_free(caps);
//     rure_free(re);
//     UNPROTECT(4);
//     return ans;
// }

// SEXP r_rure_find_all_captures(SEXP string, SEXP pattern, SEXP start)
// {
//     const char *pat = check_string_and_pattern(string, pattern);
//     size_t start_off = check_start(start);

//     R_xlen_t n = Rf_xlength(string);

//     rure *re = compile_utf8_pattern(pat);
//     rure_captures *caps = rure_captures_new(re);

//     int32_t ngroups = (int32_t)rure_captures_len(caps);
//     int ncap = ngroups > 0 ? ngroups - 1 : 0;

//     SEXP ans = PROTECT(Rf_allocVector(VECSXP, n));
//     SEXP cap_names = PROTECT(capture_group_names(ncap, re));
//     SEXP dimnames = PROTECT(get_start_end_dimnames());
//     SEXP matches_captures_names = PROTECT(get_matches_captures_names());

//     SEXP empty_cg = PROTECT(Rf_allocVector(VECSXP, 0));

//     find_buffer *bufs = (find_buffer *)R_alloc(ncap + 1, sizeof(find_buffer));
//     for (int g = 0; g <= ncap; g++)
//         find_buffer_init(&bufs[g]);

//     for (R_xlen_t i = 0; i < n; i++)
//     {
//         for (int g = 0; g <= ncap; g++)
//             bufs[g].size = 0;

//         SEXP s = STRING_ELT(string, i);
//         bool ok = false;

//         if (s != NA_STRING)
//         {
//             const char *s_p = CHAR(s);
//             size_t s_sz = (size_t)Rf_length(s);

//             if (start_off <= s_sz)
//             {
//                 ok = true;
//                 size_t offset = start_off;
//                 rure_match m;

//                 while (offset <= s_sz &&
//                        rure_find_captures(
//                            re,
//                            (const uint8_t *)s_p,
//                            s_sz,
//                            offset,
//                            caps))
//                 {
//                     // Record group 0 (whole match) first
//                     rure_captures_at(caps, 0, &m);
//                     find_buffer_push(&bufs[0],
//                                      (R_xlen_t)m.start + 1,
//                                      (R_xlen_t)m.end);

//                     // Record each capture group
//                     for (int g = 1; g <= ncap; g++)
//                     {
//                         rure_match gm;
//                         if (rure_captures_at(caps, (size_t)g, &gm))
//                             find_buffer_push(&bufs[g],
//                                              (R_xlen_t)gm.start + 1,
//                                              (R_xlen_t)gm.end);
//                         else
//                             find_buffer_push(&bufs[g],
//                                              (R_xlen_t)NA_INTEGER,
//                                              (R_xlen_t)NA_INTEGER);
//                     }

//                     // Advance: step past the end of the match, guarding
//                     // against zero-width matches.
//                     if (m.end > offset)
//                         offset = m.end;
//                     else
//                         offset++;
//                 }
//             }
//         }

//         // NA string, too-short string, or no matches found.
//         if (!ok || bufs[0].size == 0)
//         {
//             SEXP mat = PROTECT(na_one_row_matrix(dimnames));
//             SEXP cg = PROTECT(one_row_na_captures(ncap, cap_names, dimnames));
//             SEXP elt = PROTECT(build_matches_captures(mat, cg, matches_captures_names));
//             SET_VECTOR_ELT(ans, i, elt);
//             UNPROTECT(3);
//             continue;
//         }

//         R_xlen_t k = bufs[0].size;

//         SEXP mat = PROTECT(Rf_allocMatrix(INTSXP, (int)k, 2));
//         int *mout = INTEGER(mat);
//         for (R_xlen_t r = 0; r < k; r++)
//         {
//             mout[r] = (int)bufs[0].starts[r];
//             mout[r + k] = (int)bufs[0].ends[r];
//         }
//         Rf_setAttrib(mat, R_DimNamesSymbol, dimnames);

//         SEXP cg;
//         bool cg_protected;
//         if (ncap == 0)
//         {
//             cg = empty_cg; // already protected above
//             cg_protected = false;
//         }
//         else
//         {
//             cg = PROTECT(make_capture_groups(ncap, cap_names));
//             cg_protected = true;
//         }

//         for (int g = 0; g < ncap; g++)
//         {
//             SEXP cm = PROTECT(Rf_allocMatrix(INTSXP, (int)k, 2));
//             int *cout = INTEGER(cm);
//             for (R_xlen_t r = 0; r < k; r++)
//             {
//                 cout[r] = (int)bufs[g + 1].starts[r];
//                 cout[r + k] = (int)bufs[g + 1].ends[r];
//             }
//             Rf_setAttrib(cm, R_DimNamesSymbol, dimnames);
//             SET_VECTOR_ELT(cg, g, cm);
//             UNPROTECT(1);
//         }

//         SEXP elt = PROTECT(build_matches_captures(mat, cg, matches_captures_names));
//         SET_VECTOR_ELT(ans, i, elt);
//         if (cg_protected)
//             UNPROTECT(1);
//         UNPROTECT(2);
//     }

//     for (int g = 0; g <= ncap; g++)
//         find_buffer_free(&bufs[g]);

//     rure_captures_free(caps);
//     rure_free(re);
//     UNPROTECT(5);
//     return ans;
// }

SEXP r_rure_find_all_captures(SEXP string, SEXP pattern, SEXP start)
{
    const char *pat = check_string_and_pattern(string, pattern);
    size_t start_off = check_start(start);

    R_xlen_t n = Rf_xlength(string);

    rure *re = compile_utf8_pattern(pat);
    rure_captures *caps = rure_captures_new(re);

    int32_t ngroups = (int32_t)rure_captures_len(caps);
    int ncap = ngroups > 0 ? ngroups - 1 : 0;

    SEXP ans = PROTECT(Rf_allocVector(VECSXP, n));
    SEXP cap_names = PROTECT(capture_group_names(ncap, re));
    SEXP dimnames = PROTECT(get_start_end_dimnames());
    SEXP matches_captures_names = PROTECT(get_matches_captures_names());
    SEXP empty_cg = PROTECT(Rf_allocVector(VECSXP, 0));

    // shared objs
    SEXP na_mat = PROTECT(na_one_row_matrix(dimnames));
    SEXP na_cg = PROTECT(one_row_na_captures(ncap, cap_names, dimnames));
    SEXP na_elt = PROTECT(build_matches_captures(na_mat, na_cg, matches_captures_names));
    // na_mat, na_cg are now reachable via na_elt, which is protected
    UNPROTECT(2);

    find_buffer *bufs = (find_buffer *)R_alloc(ncap + 1, sizeof(find_buffer));
    for (int g = 0; g <= ncap; g++)
        find_buffer_init(&bufs[g]);

    for (R_xlen_t i = 0; i < n; i++)
    {
        for (int g = 0; g <= ncap; g++)
            bufs[g].size = 0;

        SEXP s = STRING_ELT(string, i);
        bool ok = false;

        if (s != NA_STRING)
        {
            const char *s_p = CHAR(s);
            size_t s_sz = (size_t)Rf_length(s);

            if (start_off <= s_sz)
            {
                ok = true;
                size_t offset = start_off;
                rure_match m;

                while (offset <= s_sz &&
                       rure_find_captures(
                           re,
                           (const uint8_t *)s_p,
                           s_sz,
                           offset,
                           caps))
                {
                    rure_captures_at(caps, 0, &m);
                    find_buffer_push(&bufs[0],
                                     (R_xlen_t)m.start + 1,
                                     (R_xlen_t)m.end);

                    for (int g = 1; g <= ncap; g++)
                    {
                        rure_match gm;
                        if (rure_captures_at(caps, (size_t)g, &gm))
                            find_buffer_push(&bufs[g],
                                             (R_xlen_t)gm.start + 1,
                                             (R_xlen_t)gm.end);
                        else
                            find_buffer_push(&bufs[g],
                                             (R_xlen_t)NA_INTEGER,
                                             (R_xlen_t)NA_INTEGER);
                    }

                    if (m.end > offset)
                        offset = m.end;
                    else
                        offset++;
                }
            }
        }

        if (!ok || bufs[0].size == 0)
        {
            SET_VECTOR_ELT(ans, i, na_elt);
            continue;
        }

        R_xlen_t k = bufs[0].size;

        int n_prot = 2;

        SEXP mat = PROTECT(Rf_allocMatrix(INTSXP, (int)k, 2));
        {
            int *mout = INTEGER(mat);
            for (R_xlen_t r = 0; r < k; r++)
            {
                mout[r] = (int)bufs[0].starts[r];
                mout[r + k] = (int)bufs[0].ends[r];
            }
        }
        Rf_setAttrib(mat, R_DimNamesSymbol, dimnames);

        SEXP cg;
        if (ncap == 0)
        {
            cg = empty_cg;
        }
        else
        {
            cg = PROTECT(make_capture_groups(ncap, cap_names));
            n_prot++;
        }

        for (int g = 0; g < ncap; g++)
        {
            SEXP cm = PROTECT(Rf_allocMatrix(INTSXP, (int)k, 2));
            int *cout = INTEGER(cm);
            for (R_xlen_t r = 0; r < k; r++)
            {
                cout[r] = (int)bufs[g + 1].starts[r];
                cout[r + k] = (int)bufs[g + 1].ends[r];
            }
            Rf_setAttrib(cm, R_DimNamesSymbol, dimnames);
            SET_VECTOR_ELT(cg, g, cm);
            UNPROTECT(1);
        }

        SEXP elt = PROTECT(build_matches_captures(mat, cg, matches_captures_names));
        SET_VECTOR_ELT(ans, i, elt);
        UNPROTECT(n_prot);
    }

    for (int g = 0; g <= ncap; g++)
        find_buffer_free(&bufs[g]);

    rure_captures_free(caps);
    rure_free(re);

    // ans, cap_names, dimnames, matches_captures_names, empty_cg, na_elt
    UNPROTECT(6);
    return ans;
}