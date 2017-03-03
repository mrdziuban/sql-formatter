#[cfg(test)]
use regex::Regex;

use libc;
use std::ffi::{CString, CStr};
use std::str;
use webplatform::Interop;

// These functions are kind of hacky, but using the regex crate
// makes the compiled js file go from 2.1M to 15M
pub fn regex_replace(subject: &str, pattern: &str, flags: &str, replacement: &str) -> String {
    #[cfg(not(test))]
    {
        let replaced = js! { (subject, pattern, flags, replacement) b"\
            var str = UTF8ToString($0).replace(new RegExp(UTF8ToString($1), UTF8ToString($2)), UTF8ToString($3));\
            return allocate(intArrayFromString(str), 'i8', ALLOC_STACK);\
        \0" };
        unsafe {
            str::from_utf8(CStr::from_ptr(replaced as *const libc::c_char).to_bytes()).unwrap().to_owned()
        }
    }
    #[cfg(test)]
    String::from(Regex::new(pattern).unwrap().replace_all(subject, replacement))
}

pub fn regex_match(subject: &str, pattern: &str, flags: &str) -> bool {
    #[cfg(not(test))]
    {
        let matched = js! { (subject, pattern, flags) b"\
            return new RegExp(UTF8ToString($1), UTF8ToString($2)).test(UTF8ToString($0));\
        \0" };
        matched == 1
    }
    #[cfg(test)]
    Regex::new(pattern).unwrap().is_match(subject)
}
