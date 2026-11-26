use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex, OnceLock, PoisonError};

use comrak::plugins::syntect::{SyntectAdapter, SyntectAdapterBuilder};

use magnus::{RHash, Ruby, TryConvert};
use syntect::highlighting::ThemeSet;

/// Adapters built so far, keyed by `(theme, path)`.
///
/// Building a `SyntectAdapter` deserializes syntect's bundled syntax and theme
/// sets, and the syntax regexes are then compiled lazily on first use. That
/// costs far more than rendering a small document, so an adapter is built once
/// per theme/path combination and shared for the life of the process. Adapters
/// hold no Ruby objects and are immutable once built.
///
/// The mutex only makes the static `Sync`; every caller holds the GVL, so the
/// lock is never contended.
type AdapterCache = Mutex<HashMap<(String, PathBuf), Arc<SyntectAdapter>>>;

fn adapter_cache() -> &'static AdapterCache {
    static CACHE: OnceLock<AdapterCache> = OnceLock::new();
    CACHE.get_or_init(|| Mutex::new(HashMap::new()))
}

/// Constructs a syntax highlighter from pre-validated plugin configuration.
/// Expects the output from format_plugins():
/// - None: syntax highlighting disabled
/// - Some(RHash): contains { syntax_highlighter: { theme: String, path: String } }
pub fn construct_syntax_highlighter_from_plugin(
    ruby: &Ruby,
    rb_plugins: Option<RHash>,
) -> Result<Option<Arc<SyntectAdapter>>, magnus::Error> {
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

    // An empty or missing path means the bundled theme set. A real path is
    // resolved so different spellings of one directory share one adapter.
    let path = PathBuf::from(path);
    let path = if path.as_os_str().is_empty() || !path.exists() {
        PathBuf::new()
    } else {
        path.canonicalize().unwrap_or(path)
    };

    let key = (theme, path);

    let mut cache = adapter_cache()
        .lock()
        .unwrap_or_else(PoisonError::into_inner);

    if let Some(adapter) = cache.get(&key) {
        return Ok(Some(Arc::clone(adapter)));
    }

    let adapter = Arc::new(build_adapter(ruby, &key.0, &key.1)?);
    cache.insert(key, Arc::clone(&adapter));

    Ok(Some(adapter))
}

/// Builds the adapter for one `(theme, path)`; see `adapter_cache` for why this
/// runs at most once per combination.
fn build_adapter(ruby: &Ruby, theme: &str, path: &Path) -> Result<SyntectAdapter, magnus::Error> {
    // Empty theme means use CSS classes instead of inline styles
    if theme.is_empty() {
        return Ok(SyntectAdapter::new(None));
    }

    if path.as_os_str().is_empty() {
        // No custom path, use default themes
        ThemeSet::load_defaults().themes.get(theme).ok_or_else(|| {
            magnus::Error::new(
                ruby.exception_arg_error(),
                format!("theme `{theme}` does not exist"),
            )
        })?;
        return Ok(SyntectAdapter::new(Some(theme)));
    }

    // Custom theme path provided
    if !path.is_dir() {
        return Err(magnus::Error::new(
            ruby.exception_arg_error(),
            "`path` needs to be a directory",
        ));
    }

    let mut ts = ThemeSet::load_defaults();

    ts.add_from_folder(path).map_err(|e| {
        magnus::Error::new(
            ruby.exception_arg_error(),
            format!("failed to load theme set from path: {e}"),
        )
    })?;

    // Verify theme exists in the loaded set
    ts.themes.get(theme).ok_or_else(|| {
        magnus::Error::new(
            ruby.exception_arg_error(),
            format!("theme `{theme}` does not exist"),
        )
    })?;

    Ok(SyntectAdapterBuilder::new()
        .theme_set(ts)
        .theme(theme)
        .build())
}
