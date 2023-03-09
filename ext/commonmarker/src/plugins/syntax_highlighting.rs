use std::path::PathBuf;

use magnus::{RHash, Symbol, Value};

use crate::EMPTY_STR;

pub const SYNTAX_HIGHLIGHTER_PLUGIN_THEME_KEY: &str = "theme";
pub const SYNTAX_HIGHLIGHTER_PLUGIN_PATH_KEY: &str = "path";
pub const SYNTAX_HIGHLIGHTER_PLUGIN_DEFAULT_THEME: &str = "base16-ocean.dark";

pub fn fetch_syntax_highlighter_theme(value: Value) -> Result<String, magnus::Error> {
    if value.is_nil() {
        // `syntax_highlighter: nil`
        return Ok(EMPTY_STR.to_string());
    }

    let syntax_highlighter_plugin = value.try_convert::<RHash>()?;
    let theme_key = Symbol::new(SYNTAX_HIGHLIGHTER_PLUGIN_THEME_KEY);

    match syntax_highlighter_plugin.get(theme_key) {
        Some(theme) => {
            if theme.is_nil() {
                // `syntax_highlighter: { theme: nil }`
                return Ok(EMPTY_STR.to_string());
            }
            Ok(theme.try_convert::<String>()?)
        }
        None => {
            // `syntax_highlighter: {  }`
            Ok(EMPTY_STR.to_string())
        }
    }
}

pub fn fetch_syntax_highlighter_path(value: Value) -> Result<PathBuf, magnus::Error> {
    if value.is_nil() {
        // `syntax_highlighter: nil`
        return Ok(PathBuf::from(EMPTY_STR));
    }

    let syntax_highlighter_plugin = value.try_convert::<RHash>()?;
    let path_key = Symbol::new(SYNTAX_HIGHLIGHTER_PLUGIN_PATH_KEY);

    match syntax_highlighter_plugin.get(path_key) {
        Some(path) => {
            if path.is_nil() {
                // `syntax_highlighter: { path: nil }`
                return Ok(PathBuf::from(EMPTY_STR));
            }

            Ok(PathBuf::from(path.try_convert::<String>()?))
        }
        None => {
            // `syntax_highlighter: {  }`
            Ok(PathBuf::from(EMPTY_STR))
        }
    }
}
