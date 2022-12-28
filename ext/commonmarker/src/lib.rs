extern crate core;

use std::{
    any::Any,
    borrow::Borrow,
    cell::{RefCell, RefMut},
    rc::Rc,
};

use comrak::{
    adapters::SyntaxHighlighterAdapter, markdown_to_html, markdown_to_html_with_plugins,
    plugins::syntect::SyntectAdapter, ComrakOptions, ComrakPlugins,
};
use magnus::{define_module, function, r_hash::ForEach, scan_args, Error, RHash, Symbol, Value};

mod options;
use options::iterate_options_hash;

mod plugins;
use plugins::{
    syntax_highlighting::fetch_syntax_highlighter_theme, SYNTAX_HIGHLIGHTER_PLUGIN,
    SYNTAX_HIGHLIGHTER_PLUGIN_DEFAULT_THEME,
};

mod utils;

fn commonmark_to_html<'a>(args: &[Value]) -> Result<String, magnus::Error> {
    let args = scan_args::scan_args(args)?;
    let (rb_commonmark,): (String,) = args.required;
    let _: () = args.optional;
    let _: () = args.splat;
    let _: () = args.trailing;
    let _: () = args.block;

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

        let mut adapter: Option<Box<dyn Any>> = None;

        match rb_plugins.get(Symbol::new(SYNTAX_HIGHLIGHTER_PLUGIN)) {
            Some(theme_val) => {
                let theme_val = fetch_syntax_highlighter_theme(theme_val)?;

                if theme_val.is_none() || theme_val.as_ref().unwrap() == "none" {
                    adapter = None;
                } else {
                    let t = theme_val.as_ref().to_owned();
                    // let theme: &str = theme_val.to_owned().unwrap().as_ref();
                    adapter = Some(Box::new(SyntectAdapter::new(
                        SYNTAX_HIGHLIGHTER_PLUGIN_DEFAULT_THEME,
                    )));
                }
            }
            None => (),
        }

        let x = adapter.unwrap();
        match x.downcast_ref::<SyntectAdapter>() {
            Some(a) => {
                let adapter = Box::new(a);
                comrak_plugins.render.codefence_syntax_highlighter = Some(a);
            }
            None => (),
        }

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
