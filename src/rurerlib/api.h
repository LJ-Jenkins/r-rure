#include <stdint.h>

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
