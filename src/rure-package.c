#include <R.h>
#include <Rinternals.h>

extern SEXP ffi_re_detect(SEXP strings, SEXP pattern);
extern SEXP ffi_re_set_detect(SEXP strings, SEXP patterns);
extern SEXP ffi_re_set_detect_each(SEXP strings, SEXP patterns);
extern SEXP ffi_re_find(SEXP strings, SEXP pattern);
extern SEXP ffi_re_set_find(SEXP strings, SEXP patterns);
extern SEXP ffi_re_set_find_each(SEXP strings, SEXP patterns);
extern SEXP ffi_re_escape(SEXP string);

static const R_CallMethodDef callMethods[] = {
    {"ffi_re_detect", (DL_FUNC)&ffi_re_detect, 2},
    {"ffi_re_set_detect", (DL_FUNC)&ffi_re_set_detect, 2},
    {"ffi_re_set_detect_each", (DL_FUNC)&ffi_re_set_detect_each, 2},
    {"ffi_re_find", (DL_FUNC)&ffi_re_find, 2},
    {"ffi_re_set_find", (DL_FUNC)&ffi_re_set_find, 2},
    {"ffi_re_set_find_each", (DL_FUNC)&ffi_re_set_find_each, 2},
    {"ffi_re_escape", (DL_FUNC)&ffi_re_escape, 1},
    {NULL, NULL, 0}};

void R_init_rure(DllInfo *dll)
{
  R_registerRoutines(dll, NULL, callMethods, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
  R_forceSymbols(dll, TRUE);
}
