#include <stdint.h>

// #define STRIP_OK 0
// #define STRIP_NO_MATCH 1
// #define STRIP_ERROR 2

#ifdef __cplusplus
extern "C"
{
#endif

    int rust_escape(
        const uint8_t *pattern,
        size_t length,
        char **result);

#ifdef __cplusplus
}
#endif
