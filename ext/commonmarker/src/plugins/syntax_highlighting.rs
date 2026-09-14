use std::path::PathBuf;

use comrak::plugins::syntect::{SyntectAdapter, SyntectAdapterBuilder};

use magnus::{RHash, Ruby, TryConvert};
use syntect::highlighting::ThemeSet;

/// Constructs a syntax highlighter from pre-validated plugin configuration.
/// Expects the output from format_plugins():
/// - None: syntax highlighting disabled
/// - Some(RHash): contains { syntax_highlighter: { theme: String, path: String } }
pub fn construct_syntax_highlighter_from_plugin(
    ruby: &Ruby,
    rb_plugins: Option<RHash>,
) -> Result<Option<SyntectAdapter>, magnus::Error> {
    let rb_plugins = match rb_plugins {
        None => return Ok(None),
        Some(p) => p,
    };

    let syntax_highlighter_hash: RHash = rb_plugins
        .get(ruby.to_symbol(super::SYNTAX_HIGHLIGHTER_PLUGIN))
        .map(TryConvert::try_convert)
        .transpose()?
        .ok_or_else(|| {
            magnus::Error::new(
                ruby.exception_arg_error(),
                "missing syntax_highlighter key in plugins",
            )
        })?;

    let theme: String = syntax_highlighter_hash
        .get(ruby.to_symbol(super::SYNTAX_HIGHLIGHTER_PLUGIN_THEME_KEY))
        .map(TryConvert::try_convert)
        .transpose()?
        .unwrap_or_default();

    let path: String = syntax_highlighter_hash
        .get(ruby.to_symbol(super::SYNTAX_HIGHLIGHTER_PLUGIN_PATH_KEY))
        .map(TryConvert::try_convert)
        .transpose()?
        .unwrap_or_default();

    // Empty theme means use CSS classes instead of inline styles
    if theme.is_empty() {
        return Ok(Some(SyntectAdapter::new(None)));
    }

    let path = PathBuf::from(&path);

    if path.as_os_str().is_empty() || !path.exists() {
        // No custom path, use default themes
        ThemeSet::load_defaults()
            .themes
            .get(&theme)
            .ok_or_else(|| {
                magnus::Error::new(
                    ruby.exception_arg_error(),
                    format!("theme `{}` does not exist", theme),
                )
            })?;
        return Ok(Some(SyntectAdapter::new(Some(&theme))));
    }

    // Custom theme path provided
    if !path.is_dir() {
        return Err(magnus::Error::new(
            ruby.exception_arg_error(),
            "`path` needs to be a directory",
        ));
    }

    let builder = SyntectAdapterBuilder::new();
    let mut ts = ThemeSet::load_defaults();

    ts.add_from_folder(&path).map_err(|e| {
        magnus::Error::new(
            ruby.exception_arg_error(),
            format!("failed to load theme set from path: {e}"),
        )
    })?;

    // Verify theme exists in the loaded set
    ts.themes.get(&theme).ok_or_else(|| {
        magnus::Error::new(
            ruby.exception_arg_error(),
            format!("theme `{}` does not exist", theme),
        )
    })?;

    Ok(Some(builder.theme_set(ts).theme(&theme).build()))
}
