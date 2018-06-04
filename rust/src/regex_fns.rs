use regex::Regex;

pub fn regex_replace(subject: &str, pattern: &str, replacement: &str) -> String {
    String::from(Regex::new(pattern).unwrap().replace_all(subject, replacement))
}

pub fn regex_match(subject: &str, pattern: &str) -> bool {
    Regex::new(pattern).unwrap().is_match(subject)
}
