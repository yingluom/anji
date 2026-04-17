//! C ABI bridge for the Anki Rust backend.
//!
//! Exposes four C functions that Swift calls through an XCFramework.
//! This is the same pattern used by AnkiDroid's JNI bridge, adapted for
//! Apple platforms via C ABI.

use std::os::raw::c_int;
use std::slice;

use anki::backend::{init_backend, Backend};

/// Create a new Anki backend instance.
///
/// # Safety
/// - `init_data` must point to a valid protobuf `BackendInit` buffer, or be NULL.
/// - `out_ptr` must be a writable `i64` that receives the opaque handle.
///
/// Returns 0 on success, -1 on failure.
#[no_mangle]
pub unsafe extern "C" fn anki_open_backend(
    init_data: *const u8,
    init_len: usize,
    out_ptr: *mut i64,
) -> c_int {
    let init_bytes: &[u8] = if init_data.is_null() || init_len == 0 {
        b""
    } else {
        unsafe { slice::from_raw_parts(init_data, init_len) }
    };

    let effective_bytes: Vec<u8>;
    let bytes_to_use = if init_bytes.is_empty() {
        use prost::Message;
        let default_init = anki_proto::backend::BackendInit::default();
        effective_bytes = default_init.encode_to_vec();
        &effective_bytes
    } else {
        init_bytes
    };

    match init_backend(bytes_to_use) {
        Ok(backend) => {
            let boxed = Box::new(backend);
            let ptr = Box::into_raw(boxed) as i64;
            unsafe { *out_ptr = ptr };
            0
        }
        Err(_) => -1,
    }
}

/// Execute a backend RPC method.
///
/// # Safety
/// - `backend_ptr` must be a valid handle from `anki_open_backend`.
/// - `input_data` / `input_len` describe the serialized protobuf request.
/// - `out_data` / `out_len` receive the response (free with `anki_free_response`).
///
/// Returns 0 on success, 1 on backend error (response contains error protobuf), -1 on FFI error.
#[no_mangle]
pub unsafe extern "C" fn anki_run_method(
    backend_ptr: i64,
    service: u32,
    method: u32,
    input_data: *const u8,
    input_len: usize,
    out_data: *mut *mut u8,
    out_len: *mut usize,
) -> c_int {
    let backend = unsafe { &*(backend_ptr as *const Backend) };

    let input = if input_data.is_null() || input_len == 0 {
        &[]
    } else {
        unsafe { slice::from_raw_parts(input_data, input_len) }
    };

    match backend.run_service_method(service, method, input) {
        Ok(output) => {
            write_output(output, out_data, out_len);
            0
        }
        Err(err_bytes) => {
            write_output(err_bytes, out_data, out_len);
            1
        }
    }
}

/// Free a response buffer previously returned by `anki_run_method`.
#[no_mangle]
pub unsafe extern "C" fn anki_free_response(data: *mut u8, len: usize) {
    if !data.is_null() && len > 0 {
        let _ = unsafe { Vec::from_raw_parts(data, len, len) };
    }
}

/// Close and destroy the backend handle.
#[no_mangle]
pub unsafe extern "C" fn anki_close_backend(backend_ptr: i64) {
    if backend_ptr != 0 {
        let _ = unsafe { Box::from_raw(backend_ptr as *mut Backend) };
    }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

unsafe fn write_output(data: Vec<u8>, out_data: *mut *mut u8, out_len: *mut usize) {
    let len = data.len();
    if len > 0 {
        let mut boxed = data.into_boxed_slice();
        let ptr = boxed.as_mut_ptr();
        std::mem::forget(boxed);
        unsafe {
            *out_data = ptr;
            *out_len = len;
        }
    } else {
        unsafe {
            *out_data = std::ptr::null_mut();
            *out_len = 0;
        }
    }
}
