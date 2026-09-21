#include <R.h>
#include <Rinternals.h>

extern SEXP ffi_is_match(SEXP string, SEXP pattern);
extern SEXP ffi_set_is_match(SEXP string, SEXP patterns);
extern SEXP ffi_set_is_match_each(SEXP string, SEXP patterns);
extern SEXP ffi_is_match_inds(SEXP strings, SEXP pattern);
extern SEXP ffi_set_is_match_inds(SEXP strings, SEXP patterns);
extern SEXP ffi_set_is_match_inds_each(SEXP strings, SEXP patterns);
extern SEXP ffi_find(SEXP string, SEXP pattern, SEXP start);
extern SEXP ffi_escape(SEXP string);

static const R_CallMethodDef callMethods[] = {
    {"ffi_is_match", (DL_FUNC)&ffi_is_match, 2},
    {"ffi_set_is_match", (DL_FUNC)&ffi_set_is_match, 2},
    {"ffi_set_is_match_each", (DL_FUNC)&ffi_set_is_match_each, 2},
    {"ffi_is_match_inds", (DL_FUNC)&ffi_is_match_inds, 2},
    {"ffi_set_is_match_inds", (DL_FUNC)&ffi_set_is_match_inds, 2},
    {"ffi_set_is_match_inds_each", (DL_FUNC)&ffi_set_is_match_inds_each, 2},
    {"ffi_find", (DL_FUNC)&ffi_find, 3},
    {"ffi_escape", (DL_FUNC)&ffi_escape, 1},
    {NULL, NULL, 0}};

void R_init_rure(DllInfo *dll)
{
  R_registerRoutines(dll, NULL, callMethods, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
  R_forceSymbols(dll, TRUE);
}
