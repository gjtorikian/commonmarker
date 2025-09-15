use std::path::PathBuf;

use comrak::plugins::syntect::{SyntectAdapter, SyntectAdapterBuilder};

use magnus::value::ReprValue;
use magnus::{RHash, TryConvert, Value};
use syntect::highlighting::ThemeSet;

use crate::EMPTY_STR;

pub fn construct_syntax_highlighter_from_plugin(
    rb_plugins: Option<RHash>,
) -> Result<Option<SyntectAdapter>, magnus::Error> {
    match rb_plugins {
        None => Ok(None),
        Some(rb_plugins) => {
            let ruby = magnus::Ruby::get_with(rb_plugins);
            let theme = match rb_plugins.get(ruby.to_symbol(super::SYNTAX_HIGHLIGHTER_PLUGIN)) {
                Some(syntax_highlighter_options) => {
                    match fetch_syntax_highlighter_theme(syntax_highlighter_options) {
                        Ok(theme) => theme,
                        Err(e) => {
                            return Err(e);
                        }
                    }
                }
                None => None, // no `syntax_highlighter:` defined
            };

            let adapter: SyntectAdapter;

            match theme {
                None => Ok(None),
                Some(theme) => {
                    if theme.is_empty() {
                        // no theme? uss css classes
                        adapter = SyntectAdapter::new(None);
                        Ok(Some(adapter))
                    } else {
                        let path = match rb_plugins
                            .get(ruby.to_symbol(super::SYNTAX_HIGHLIGHTER_PLUGIN))
                        {
                            Some(syntax_highlighter_options) => {
                                fetch_syntax_highlighter_path(syntax_highlighter_options)?
                            }
                            None => PathBuf::from("".to_string()), // no `syntax_highlighter:` defined
                        };

                        if path.exists() {
                            if !path.is_dir() {
                                return Err(magnus::Error::new(
                                    ruby.exception_arg_error(),
                                    "`path` needs to be a directory",
                                ));
                            }

                            let builder = SyntectAdapterBuilder::new();
                            let mut ts = ThemeSet::load_defaults();

                            match ts.add_from_folder(&path) {
                                Ok(_) => {}
                                Err(e) => {
                                    return Err(magnus::Error::new(
                                        ruby.exception_arg_error(),
                                        format!("failed to load theme set from path: {e}"),
                                    ));
                                }
                            }

                            // check if the theme exists in the dir
                            match ts.themes.get(&theme) {
                                Some(theme) => theme,
                                None => {
                                    return Err(magnus::Error::new(
                                        ruby.exception_arg_error(),
                                        format!("theme `{}` does not exist", theme),
                                    ));
                                }
                            };

                            adapter = builder.theme_set(ts).theme(&theme).build();

                            Ok(Some(adapter))
                        } else {
                            // no path? default theme lookup
                            ThemeSet::load_defaults()
                                .themes
                                .get(&theme)
                                .ok_or_else(|| {
                                    magnus::Error::new(
                                        ruby.exception_arg_error(),
                                        format!("theme `{}` does not exist", theme),
                                    )
                                })?;
                            adapter = SyntectAdapter::new(Some(&theme));
                            Ok(Some(adapter))
                        }
                    }
                }
            }
        }
    }
}

fn fetch_syntax_highlighter_theme(value: Value) -> Result<Option<String>, magnus::Error> {
    let ruby = magnus::Ruby::get_with(value);
    if value.is_nil() {
        // `syntax_highlighter: nil`
        return Ok(None);
    }

    let syntax_highlighter_plugin: RHash = match TryConvert::try_convert(value) {
        Ok(plugin) => plugin, // `syntax_highlighter: { theme: "<something>" }`
        Err(e) => {
            // not a hash!
            return Err(e);
        }
    };

    if syntax_highlighter_plugin.is_nil() || syntax_highlighter_plugin.is_empty() {
        return Err(magnus::Error::new(
            ruby.exception_type_error(),
            "theme cannot be blank hash",
        ));
    }

    let theme_key = ruby.to_symbol(super::SYNTAX_HIGHLIGHTER_PLUGIN_THEME_KEY);

    match syntax_highlighter_plugin.get(theme_key) {
        Some(theme) => {
            if theme.is_nil() {
                return Err(magnus::Error::new(
                    ruby.exception_type_error(),
                    "theme cannot be nil",
                ));
            }
            Ok(TryConvert::try_convert(theme)?)
        }
        None => {
            // `syntax_highlighter: { theme: nil }`
            Ok(None)
        }
    }
}

fn fetch_syntax_highlighter_path(value: Value) -> Result<PathBuf, magnus::Error> {
    if value.is_nil() {
        // `syntax_highlighter: nil`
        return Ok(PathBuf::from(EMPTY_STR));
    }

    let syntax_highlighter_plugin: RHash = TryConvert::try_convert(value)?;
    let ruby = magnus::Ruby::get_with(value);
    let path_key = ruby.to_symbol(super::SYNTAX_HIGHLIGHTER_PLUGIN_PATH_KEY);

    match syntax_highlighter_plugin.get(path_key) {
        Some(path) => {
            if path.is_nil() {
                // `syntax_highlighter: { path: nil }`
                return Ok(PathBuf::from(EMPTY_STR));
            }
            let val: String = TryConvert::try_convert(path)?;
            Ok(PathBuf::from(val))
        }
        None => {
            // `syntax_highlighter: {  }`
            Ok(PathBuf::from(EMPTY_STR))
        }
    }
}
