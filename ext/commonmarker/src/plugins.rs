pub mod syntax_highlighting;

use magnus::value::ReprValue;
use magnus::{Error, RHash, Ruby, TryConvert, Value};

pub const SYNTAX_HIGHLIGHTER_PLUGIN: &str = "syntax_highlighter";
pub const SYNTAX_HIGHLIGHTER_PLUGIN_THEME_KEY: &str = "theme";
pub const SYNTAX_HIGHLIGHTER_PLUGIN_PATH_KEY: &str = "path";

pub const DEFAULT_THEME: &str = "base16-ocean.dark";
pub const DEFAULT_PATH: &str = "";

/// Formats and validates plugins from Ruby.
/// Returns None if syntax highlighting should be disabled (plugins: nil or syntax_highlighter: nil).
/// Returns Some(RHash) with merged defaults if syntax highlighting should be enabled.
pub fn format_plugins(ruby: &Ruby, rb_plugins: Option<Value>) -> Result<Option<RHash>, Error> {
    let rb_plugins = match rb_plugins {
        None => return Ok(Some(default_plugins_to_hash(ruby)?)),
        Some(v) if v.is_nil() => return Ok(None), // plugins: nil disables syntax highlighting
        Some(v) => v,
    };

    let plugins_hash: RHash = TryConvert::try_convert(rb_plugins).map_err(|_| {
        Error::new(
            ruby.exception_type_error(),
            format!(
                "plugins must be a Hash; got {}",
                crate::utils::get_classname(rb_plugins)
            ),
        )
    })?;

    if plugins_hash.is_empty() {
        return Ok(Some(default_plugins_to_hash(ruby)?));
    }

    // Check for syntax_highlighter key
    let syntax_highlighter_value = plugins_hash.get(ruby.to_symbol(SYNTAX_HIGHLIGHTER_PLUGIN));

    match syntax_highlighter_value {
        None => {
            // No syntax_highlighter key, use defaults
            Ok(Some(default_plugins_to_hash(ruby)?))
        }
        Some(v) if v.is_nil() => {
            // syntax_highlighter: nil disables syntax highlighting
            Ok(None)
        }
        Some(v) => {
            // Validate it's a hash
            let sh_hash: RHash = TryConvert::try_convert(v).map_err(|_| {
                Error::new(
                    ruby.exception_type_error(),
                    format!(
                        "syntax_highlighter must be a Hash; got {}",
                        crate::utils::get_classname(v)
                    ),
                )
            })?;

            if sh_hash.is_empty() {
                return Err(Error::new(
                    ruby.exception_type_error(),
                    "syntax_highlighter cannot be an empty Hash",
                ));
            }

            // Merge with defaults
            let result = ruby.hash_new();
            let merged_sh = ruby.hash_new();

            // Get theme - nil is an error, missing key uses default
            let theme: String =
                match sh_hash.get(ruby.to_symbol(SYNTAX_HIGHLIGHTER_PLUGIN_THEME_KEY)) {
                    Some(t) if t.is_nil() => {
                        return Err(Error::new(
                            ruby.exception_type_error(),
                            "syntax_highlighter theme cannot be nil",
                        ));
                    }
                    Some(t) => TryConvert::try_convert(t).map_err(|_| {
                        Error::new(
                            ruby.exception_type_error(),
                            format!(
                                "syntax_highlighter theme must be a String; got {}",
                                crate::utils::get_classname(t)
                            ),
                        )
                    })?,
                    None => DEFAULT_THEME.to_string(),
                };
            merged_sh.aset(ruby.to_symbol(SYNTAX_HIGHLIGHTER_PLUGIN_THEME_KEY), theme)?;

            // Get path (use default if not provided)
            let path: String = match sh_hash.get(ruby.to_symbol(SYNTAX_HIGHLIGHTER_PLUGIN_PATH_KEY))
            {
                Some(p) if !p.is_nil() => TryConvert::try_convert(p).map_err(|_| {
                    Error::new(
                        ruby.exception_type_error(),
                        format!(
                            "syntax_highlighter path must be a String; got {}",
                            crate::utils::get_classname(p)
                        ),
                    )
                })?,
                _ => DEFAULT_PATH.to_string(),
            };
            merged_sh.aset(ruby.to_symbol(SYNTAX_HIGHLIGHTER_PLUGIN_PATH_KEY), path)?;

            result.aset(ruby.to_symbol(SYNTAX_HIGHLIGHTER_PLUGIN), merged_sh)?;
            Ok(Some(result))
        }
    }
}

/// Returns the default plugins as a Ruby Hash for introspection.
pub fn default_plugins_to_hash(ruby: &Ruby) -> Result<RHash, Error> {
    let result = ruby.hash_new();
    let sh = ruby.hash_new();
    sh.aset(
        ruby.to_symbol(SYNTAX_HIGHLIGHTER_PLUGIN_THEME_KEY),
        DEFAULT_THEME,
    )?;
    sh.aset(
        ruby.to_symbol(SYNTAX_HIGHLIGHTER_PLUGIN_PATH_KEY),
        DEFAULT_PATH,
    )?;
    result.aset(ruby.to_symbol(SYNTAX_HIGHLIGHTER_PLUGIN), sh)?;
    Ok(result)
}
