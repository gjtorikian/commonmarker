use magnus::{TryConvert, Value};

pub fn try_convert_string(value: Value) -> Option<String> {
    match TryConvert::try_convert(value) {
        Ok(s) => Some(s),
        Err(_) => None,
    }
}
