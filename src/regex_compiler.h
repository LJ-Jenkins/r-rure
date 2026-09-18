#ifndef _REGEX_COMPILER_H
#define _REGEX_COMPILER_H

#include <string.h>
#include <Rinternals.h>
#include "rure.h"

static inline rure *compile_utf8_pattern(const char *pat)
{
    rure *re = rure_compile(
        (const uint8_t *)pat,
        strlen(pat),
        RURE_DEFAULT_FLAGS,
        NULL,
        NULL);

    if (re == NULL)
        Rf_error("invalid regex pattern (ensure UTF-8).");

    return re;
}

static inline rure_set *compile_utf8_pattern_set(const pattern_set *pats, R_xlen_t np)
{
    const uint8_t **ptrs = (const uint8_t **)R_alloc(np, sizeof(*ptrs));
    size_t *lens = (size_t *)R_alloc(np, sizeof(*lens));

    for (R_xlen_t i = 0; i < np; i++)
    {
        ptrs[i] = (const uint8_t *)pats[i].ptr;
        lens[i] = pats[i].len;
    }

    rure_set *re = rure_compile_set(
        ptrs,
        lens,
        (size_t)np,
        RURE_DEFAULT_FLAGS,
        NULL,
        NULL);

    if (re == NULL)
        Rf_error("invalid regex pattern set (ensure UTF-8).");

    return re;
}

#endif