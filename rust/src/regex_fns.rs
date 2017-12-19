#[cfg(test)] use regex::Regex;
#[cfg(not(test))] use stdweb::unstable::TryInto;

// These functions are kind of hacky, but using the regex crate
// makes the compiled js file go from 106K to 604K
pub fn regex_replace(subject: &str, pattern: &str, flags: &str, replacement: &str) -> String {
    #[cfg(test)]
    { String::from(Regex::new(pattern).unwrap().replace_all(subject, replacement)) }
    #[cfg(not(test))]
    (js! { return @{subject}.replace(new RegExp(@{pattern}, @{flags}), @{replacement}); }).into_string().unwrap()
}

pub fn regex_match(subject: &str, pattern: &str, flags: &str) -> bool {
    #[cfg(test)]
    { Regex::new(pattern).unwrap().is_match(subject) }
    #[cfg(not(test))]
    (js! { return new RegExp(@{pattern}, @{flags}).test(@{subject}); }).try_into().unwrap()
}
