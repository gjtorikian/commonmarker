use magnus::{TryConvert, Value};

pub fn try_convert_string(value: Value) -> Option<String> {
    TryConvert::try_convert(value).ok()
}
