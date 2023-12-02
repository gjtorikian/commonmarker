extern crate core;

use std::path::PathBuf;

use ::syntect::highlighting::ThemeSet;
use comrak::{
    adapters::SyntaxHighlighterAdapter,
    markdown_to_html, markdown_to_html_with_plugins,
    plugins::syntect::{SyntectAdapter, SyntectAdapterBuilder},
    ComrakOptions, ComrakPlugins,
};
use magnus::{
    define_module, exception, function, r_hash::ForEach, scan_args, Error, RHash, Symbol, Value,
};

mod options;
use options::iterate_options_hash;

mod plugins;
use plugins::{
    syntax_highlighting::{fetch_syntax_highlighter_path, fetch_syntax_highlighter_theme},
    SYNTAX_HIGHLIGHTER_PLUGIN,
};

mod utils;

pub const EMPTY_STR: &str = "";

fn commonmark_to_html(args: &[Value]) -> Result<String, magnus::Error> {
    let args = scan_args::scan_args::<_, (), (), (), _, ()>(args)?;
    let (rb_commonmark,): (String,) = args.required;

    let kwargs = scan_args::get_kwargs::<_, (), (Option<RHash>, Option<RHash>), ()>(
        args.keywords,
        &[],
        &["options", "plugins"],
    )?;
    let (rb_options, rb_plugins) = kwargs.optional;

    let mut comrak_options = ComrakOptions::default();

    if let Some(rb_options) = rb_options {
        rb_options.foreach(|key: Symbol, value: RHash| {
            iterate_options_hash(&mut comrak_options, key, value)?;
            Ok(ForEach::Continue)
        })?;
    }

    if let Some(rb_plugins) = rb_plugins {
        let mut comrak_plugins = ComrakPlugins::default();

        let syntax_highlighter: Option<&dyn SyntaxHighlighterAdapter>;
        let adapter: SyntectAdapter;

        let theme = match rb_plugins.get(Symbol::new(SYNTAX_HIGHLIGHTER_PLUGIN)) {
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

        match theme {
            None => syntax_highlighter = None,
            Some(theme) => {
                if theme.is_empty() {
                    // no theme? uss css classes
                    adapter = SyntectAdapter::new(None);
                    syntax_highlighter = Some(&adapter);
                } else {
                    let path = match rb_plugins.get(Symbol::new(SYNTAX_HIGHLIGHTER_PLUGIN)) {
                        Some(syntax_highlighter_options) => {
                            fetch_syntax_highlighter_path(syntax_highlighter_options)?
                        }
                        None => PathBuf::from("".to_string()), // no `syntax_highlighter:` defined
                    };

                    if path.exists() {
                        if !path.is_dir() {
                            return Err(Error::new(
                                exception::arg_error(),
                                "`path` needs to be a directory",
                            ));
                        }

                        let builder = SyntectAdapterBuilder::new();
                        let mut ts = ThemeSet::load_defaults();

                        match ts.add_from_folder(&path) {
                            Ok(_) => {}
                            Err(e) => {
                                return Err(Error::new(
                                    exception::arg_error(),
                                    format!("failed to load theme set from path: {e}"),
                                ));
                            }
                        }

                        // check if the theme exists in the dir
                        match ts.themes.get(&theme) {
                            Some(theme) => theme,
                            None => {
                                return Err(Error::new(
                                    exception::arg_error(),
                                    format!("theme `{}` does not exist", theme),
                                ));
                            }
                        };

                        adapter = builder.theme_set(ts).theme(&theme).build();

                        syntax_highlighter = Some(&adapter);
                    } else {
                        // no path? default theme lookup
                        ThemeSet::load_defaults()
                            .themes
                            .get(&theme)
                            .ok_or_else(|| {
                                Error::new(
                                    exception::arg_error(),
                                    format!("theme `{}` does not exist", theme),
                                )
                            })?;
                        adapter = SyntectAdapter::new(Some(&theme));
                        syntax_highlighter = Some(&adapter);
                    }
                }
            }
        }
        comrak_plugins.render.codefence_syntax_highlighter = syntax_highlighter;

        Ok(markdown_to_html_with_plugins(
            &rb_commonmark,
            &comrak_options,
            &comrak_plugins,
        ))
    } else {
        Ok(markdown_to_html(&rb_commonmark, &comrak_options))
    }
}

#[magnus::init]
fn init() -> Result<(), Error> {
    let module = define_module("Commonmarker")?;

    module.define_module_function("commonmark_to_html", function!(commonmark_to_html, -1))?;

    Ok(())
}
