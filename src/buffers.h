#ifndef _BUFFERS_H
#define _BUFFERS_H

#include <R.h>

typedef struct
{
    R_xlen_t *data;
    R_xlen_t size;
    R_xlen_t capacity;
} index_buffer;

static void index_buffer_init(index_buffer *buf)
{
    buf->data = NULL;
    buf->size = 0;
    buf->capacity = 0;
}

static void index_buffer_push(index_buffer *buf, R_xlen_t value)
{
    if (buf->size == buf->capacity)
    {
        // init 16 slots; double thereafter.
        R_xlen_t new_capacity = buf->capacity == 0 ? 16 : buf->capacity * 2;

        buf->data = (R_xlen_t *)R_Realloc(buf->data, new_capacity, R_xlen_t);
        buf->capacity = new_capacity;
    }

    buf->data[buf->size++] = value;
}

static void index_buffer_free(index_buffer *buf)
{
    // R_Free sets buf->data to NULL, see writing R ext 6.1.2.
    R_Free(buf->data);
    buf->size = 0;
    buf->capacity = 0;
}

//

typedef struct
{
    R_xlen_t *starts;
    R_xlen_t *ends;
    R_xlen_t size;
    R_xlen_t capacity;
} find_buffer;

static void find_buffer_init(find_buffer *buf)
{
    buf->starts = NULL;
    buf->ends = NULL;
    buf->size = 0;
    buf->capacity = 0;
}

static void find_buffer_push(find_buffer *buf, R_xlen_t start, R_xlen_t end)
{
    if (buf->size == buf->capacity)
    {
        R_xlen_t new_capacity = buf->capacity == 0 ? 16 : buf->capacity * 2;

        buf->starts = (R_xlen_t *)R_Realloc(buf->starts, new_capacity, R_xlen_t);
        buf->ends = (R_xlen_t *)R_Realloc(buf->ends, new_capacity, R_xlen_t);
        buf->capacity = new_capacity;
    }

    buf->starts[buf->size] = start;
    buf->ends[buf->size] = end;
    buf->size++;
}

static void find_buffer_free(find_buffer *buf)
{
    R_Free(buf->starts);
    R_Free(buf->ends);
    buf->size = 0;
    buf->capacity = 0;
}

#endif