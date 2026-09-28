#include <R.h>
#include <Rinternals.h>

extern SEXP r_rure_is_match(SEXP string, SEXP pattern);
extern SEXP r_rure_set_is_match(SEXP string, SEXP patterns);
extern SEXP r_rure_set_is_match_each(SEXP string, SEXP patterns);
extern SEXP r_rure_is_match_inds(SEXP strings, SEXP pattern);
extern SEXP r_rure_set_is_match_inds(SEXP strings, SEXP patterns);
extern SEXP r_rure_set_is_match_inds_each(SEXP strings, SEXP patterns);
extern SEXP r_rure_find(SEXP string, SEXP pattern, SEXP start);
extern SEXP r_rure_find_captures(SEXP string, SEXP pattern, SEXP start);
extern SEXP r_rure_find_all(SEXP string, SEXP pattern, SEXP start);
extern SEXP r_rure_escape(SEXP string);

static const R_CallMethodDef callMethods[] = {
    {"r_rure_is_match", (DL_FUNC)&r_rure_is_match, 2},
    {"r_rure_set_is_match", (DL_FUNC)&r_rure_set_is_match, 2},
    {"r_rure_set_is_match_each", (DL_FUNC)&r_rure_set_is_match_each, 2},
    {"r_rure_is_match_inds", (DL_FUNC)&r_rure_is_match_inds, 2},
    {"r_rure_set_is_match_inds", (DL_FUNC)&r_rure_set_is_match_inds, 2},
    {"r_rure_set_is_match_inds_each", (DL_FUNC)&r_rure_set_is_match_inds_each, 2},
    {"r_rure_find", (DL_FUNC)&r_rure_find, 3},
    {"r_rure_find_captures", (DL_FUNC)&r_rure_find_captures, 3},
    {"r_rure_find_all", (DL_FUNC)&r_rure_find_all, 3},
    {"r_rure_escape", (DL_FUNC)&r_rure_escape, 1},
    {NULL, NULL, 0}};

void R_init_rure(DllInfo *dll)
{
  R_registerRoutines(dll, NULL, callMethods, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
  R_forceSymbols(dll, TRUE);
}
