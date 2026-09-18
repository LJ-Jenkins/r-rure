use regex;
use std::ffi::CString;
use libc::{size_t, c_int, c_char};
use std::ptr;
use std::slice;
use std::str;

ffi_fn! {
    fn rust_escape(
        string: *const u8,
        length: size_t,
        result: *mut *mut c_char
    ) -> c_int {
        unsafe { *result = ptr::null_mut(); }

        let s: &[u8] = unsafe { 
            slice::from_raw_parts(string, length) 
        };

        let s = match str::from_utf8(s) {
            Ok(val) => val,
            Err(_) => return -1 as c_int,
        };

        let esc_s = regex::escape(s);

        let c_esc_s = match CString::new(esc_s) {
            Ok(val) => val,
            Err(_) => return -2 as c_int,
        };

        unsafe {
            *result = c_esc_s.into_raw();
        }
        
        1 as c_int
    }
}