use magnus::Value;

pub fn try_convert_string(value: Value) -> Option<String> {
    match value.try_convert::<String>() {
        Ok(s) => Some(s),
        Err(_) => None,
    }
}
