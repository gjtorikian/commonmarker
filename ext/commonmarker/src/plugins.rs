pub mod syntax_highlighting;

use magnus::value::ReprValue;
use magnus::{Error, RHash, Ruby, TryConvert, Value};

pub const SYNTAX_HIGHLIGHTER_PLUGIN: &str = "syntax_highlighter";
pub const SYNTAX_HIGHLIGHTER_PLUGIN_THEME_KEY: &str = "theme";
pub const SYNTAX_HIGHLIGHTER_PLUGIN_PATH_KEY: &str = "path";

pub const DEFAULT_THEME: &str = "base16-ocean.dark";
pub const DEFAULT_PATH: &str = "";

/// Formats and validates plugins from Ruby.
///
/// No plugin is enabled by default, as in comrak. Returns None unless the Hash
/// asks for the syntax highlighter (`syntax_highlighter: {}` enables it with
/// the default theme), and otherwise Some(RHash) holding
/// `{ syntax_highlighter: { theme: String, path: String } }` with the defaults
/// filled in.
pub fn format_plugins(ruby: &Ruby, rb_plugins: Option<Value>) -> Result<Option<RHash>, Error> {
    let rb_plugins = match rb_plugins {
        None => return Ok(None),
        Some(v) if v.is_nil() => return Ok(None),
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

    // The syntax highlighter is the only plugin, and it is off unless asked for.
    let syntax_highlighter_value = plugins_hash.get(ruby.to_symbol(SYNTAX_HIGHLIGHTER_PLUGIN));

    match syntax_highlighter_value {
        None => Ok(None),
        Some(v) if v.is_nil() => Ok(None),
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

            // Merge with the plugin's defaults; `{}` enables it with the default theme.
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

/// Returns the default plugins as a Ruby Hash for introspection: every known
/// plugin, each `nil` because none is enabled by default.
pub fn default_plugins_to_hash(ruby: &Ruby) -> Result<RHash, Error> {
    let result = ruby.hash_new();
    result.aset(ruby.to_symbol(SYNTAX_HIGHLIGHTER_PLUGIN), ruby.qnil())?;
    Ok(result)
}

/// Builds comrak's plugin set around an optional syntax highlighter.
pub fn comrak_plugins(
    adapter: Option<&comrak::plugins::syntect::SyntectAdapter>,
) -> comrak::options::Plugins<'_> {
    let mut plugins = comrak::options::Plugins::default();
    if let Some(adapter) = adapter {
        plugins.render.codefence_syntax_highlighter = Some(adapter);
    }
    plugins
}
