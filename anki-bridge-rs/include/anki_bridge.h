#ifndef ANKI_BRIDGE_H
#define ANKI_BRIDGE_H

#include <stdint.h>
#include <stddef.h>

/**
 * Open a new Anki backend instance.
 *
 * @param init_data  Serialized BackendInit protobuf (NULL for defaults).
 * @param init_len   Byte length of init_data.
 * @param out_ptr    Receives the opaque backend handle on success.
 * @return 0 on success, -1 on error.
 */
int anki_open_backend(const uint8_t *init_data, size_t init_len, int64_t *out_ptr);

/**
 * Run a backend RPC method.
 *
 * @param backend_ptr  Handle from anki_open_backend.
 * @param service      Service ID.
 * @param method       Method ID within the service.
 * @param input_data   Serialized protobuf request.
 * @param input_len    Length of input_data.
 * @param out_data     Receives heap-allocated response bytes.
 * @param out_len      Receives response length.
 * @return 0 = success, 1 = backend error (out_data has error protobuf), -1 = FFI error.
 */
int anki_run_method(
    int64_t backend_ptr,
    uint32_t service,
    uint32_t method,
    const uint8_t *input_data,
    size_t input_len,
    uint8_t **out_data,
    size_t *out_len
);

/**
 * Free response bytes allocated by anki_run_method.
 */
void anki_free_response(uint8_t *data, size_t len);

/**
 * Close and destroy the backend instance.
 */
void anki_close_backend(int64_t backend_ptr);

#endif /* ANKI_BRIDGE_H */
