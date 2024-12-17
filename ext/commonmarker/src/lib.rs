extern crate core;

use comrak::{markdown_to_html_with_plugins, parse_document, ComrakOptions};
use magnus::{define_module, function, r_hash::ForEach, scan_args, Error, RHash, Symbol, Value};
use node::CommonmarkerNode;
use plugins::syntax_highlighting::construct_syntax_highlighter_from_plugin;

mod options;
use options::iterate_options_hash;

mod plugins;

use typed_arena::Arena;

mod node;
mod utils;

pub const EMPTY_STR: &str = "";

fn commonmark_parse(args: &[Value]) -> Result<CommonmarkerNode, magnus::Error> {
    let args = scan_args::scan_args::<_, (), (), (), _, ()>(args)?;
    let (rb_commonmark,): (String,) = args.required;

    let kwargs =
        scan_args::get_kwargs::<_, (), (Option<RHash>,), ()>(args.keywords, &[], &["options"])?;
    let (rb_options,) = kwargs.optional;

    let mut comrak_options = ComrakOptions::default();

    if let Some(rb_options) = rb_options {
        rb_options.foreach(|key: Symbol, value: RHash| {
            iterate_options_hash(&mut comrak_options, key, value)?;
            Ok(ForEach::Continue)
        })?;
    }

    let arena = Arena::new();
    let root = parse_document(&arena, &rb_commonmark, &comrak_options);

    CommonmarkerNode::new_from_comrak_node(root)
}

fn commonmark_to_html(args: &[Value]) -> Result<String, magnus::Error> {
    let args = scan_args::scan_args::<_, (), (), (), _, ()>(args)?;
    let (rb_commonmark,): (String,) = args.required;

    let kwargs = scan_args::get_kwargs::<_, (), (Option<RHash>, Option<RHash>), ()>(
        args.keywords,
        &[],
        &["options", "plugins"],
    )?;
    let (rb_options, rb_plugins) = kwargs.optional;

    let comrak_options = match format_options(rb_options) {
        Ok(options) => options,
        Err(err) => return Err(err),
    };

    let mut comrak_plugins = comrak::Plugins::default();

    let syntect_adapter = match construct_syntax_highlighter_from_plugin(rb_plugins) {
        Ok(Some(adapter)) => Some(adapter),
        Ok(None) => None,
        Err(err) => return Err(err),
    };

    match syntect_adapter {
        Some(ref adapter) => comrak_plugins.render.codefence_syntax_highlighter = Some(adapter),
        None => comrak_plugins.render.codefence_syntax_highlighter = None,
    }

    Ok(markdown_to_html_with_plugins(
        &rb_commonmark,
        &comrak_options,
        &comrak_plugins,
    ))
}

fn format_options<'c>(rb_options: Option<RHash>) -> Result<comrak::Options<'c>, magnus::Error> {
    let mut comrak_options = ComrakOptions::default();

    if let Some(rb_options) = rb_options {
        rb_options.foreach(|key: Symbol, value: RHash| {
            iterate_options_hash(&mut comrak_options, key, value)?;
            Ok(ForEach::Continue)
        })?;
    }

    Ok(comrak_options)
}

#[magnus::init]
fn init() -> Result<(), Error> {
    let m_commonmarker = define_module("Commonmarker")?;

    m_commonmarker.define_module_function("commonmark_parse", function!(commonmark_parse, -1))?;
    m_commonmarker
        .define_module_function("commonmark_to_html", function!(commonmark_to_html, -1))?;

    node::init(m_commonmarker).expect("cannot define Commonmarker::Node class");

    Ok(())
}
