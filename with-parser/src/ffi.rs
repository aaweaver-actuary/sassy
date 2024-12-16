//! This module wraps the functionality of this crate into a C-compatible interface.
//! This module is primarily expected to be used to interface with SAS (PROC PROTO is the 
//! main interfacing tool) though other languages that interface with C can also use this.
//! The goal of the crate is to parse a %WITH macro statement and convert it into a
//! standard PROC SQL statement.

use std::ffi::{CStr, CString, c_char, c_int, c_uint};