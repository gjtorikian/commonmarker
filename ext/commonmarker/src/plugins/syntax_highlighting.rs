use magnus::{RHash, Value};

pub const SYNTAX_HIGHLIGHTER_PLUGIN_THEME_KEY: &str = "theme";
pub const SYNTAX_HIGHLIGHTER_PLUGIN_DEFAULT_THEME: &str = "base16-ocean.dark";

pub fn fetch_syntax_highlighter_theme<'a>(value: Value) -> Result<Option<String>, magnus::Error> {
    if value.is_nil() {
        return Ok(None);
    }

    let syntax_highlighter_plugin = value.try_convert::<RHash>()?;
    let theme = syntax_highlighter_plugin.get(SYNTAX_HIGHLIGHTER_PLUGIN_THEME_KEY);
    match theme {
        Some(theme) => {
            Ok(Some(theme.try_convert::<String>().unwrap_or_else(|_| {
                SYNTAX_HIGHLIGHTER_PLUGIN_DEFAULT_THEME.to_string()
            })))
        }
        None => Ok(Some(SYNTAX_HIGHLIGHTER_PLUGIN_DEFAULT_THEME.to_string())),
    }
}
