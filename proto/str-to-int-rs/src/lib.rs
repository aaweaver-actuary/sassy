use std::ffi::CStr;
use std::os::raw::c_char;

/// Converts a C string representing a (possibly zero-padded) number to an integer.
///
/// This function is designed to be called from C (for example, via SAS PROC PROTO).
/// If the input pointer is NULL, if the string is empty, if it is not valid UTF-8,
/// or if the string does not represent a valid integer (including extraneous characters),
/// the function returns the SAS missing value for an integer (i32::MIN).
///
/// # Safety
///
/// This function dereferences a raw pointer and thus is unsafe. The caller must ensure that
/// the pointer is valid and points to a null-terminated string.
///
/// # Examples
///
/// ```
/// use std::ffi::CString;
///
/// let s = CString::new("00123").unwrap();
/// let result = unsafe { char_to_int(s.as_ptr()) };
/// assert_eq!(result, 123);
/// ```
#[no_mangle]
pub unsafe extern "C" fn char_to_int(s: *const c_char) -> i32 {
    if s.is_null() {
        return i32::MIN;
    }

    let c_str = CStr::from_ptr(s);
    let s_str = match c_str.to_str() {
        Ok(s) => s.trim(),  // Remove leading/trailing whitespace.
        Err(_) => return i32::MIN,
    };

    // Return missing if the trimmed string is empty.
    if s_str.is_empty() {
        return i32::MIN;
    }

    // Attempt to parse the string into an i32.
    // This will fail (and return i32::MIN) if the string contains invalid characters.
    match s_str.parse::<i32>() {
        Ok(num) => num,
        Err(_) => i32::MIN,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;
    use std::ptr;

    #[test]
    fn test_valid_numbers() {
        unsafe {
            let s = CString::new("123").unwrap();
            assert_eq!(char_to_int(s.as_ptr()), 123);

            let s = CString::new("00123").unwrap();
            assert_eq!(char_to_int(s.as_ptr()), 123);

            let s = CString::new("-00123").unwrap();
            assert_eq!(char_to_int(s.as_ptr()), -123);

            let s = CString::new("  456  ").unwrap();
            assert_eq!(char_to_int(s.as_ptr()), 456);
        }
    }

    #[test]
    fn test_invalid_numbers() {
        unsafe {
            let s = CString::new("abc").unwrap();
            assert_eq!(char_to_int(s.as_ptr()), i32::MIN);

            let s = CString::new("123abc").unwrap();
            assert_eq!(char_to_int(s.as_ptr()), i32::MIN);

            let s = CString::new("").unwrap();
            assert_eq!(char_to_int(s.as_ptr()), i32::MIN);
        }
    }

    #[test]
    fn test_null_pointer() {
        unsafe {
            assert_eq!(char_to_int(ptr::null()), i32::MIN);
        }
    }
}
