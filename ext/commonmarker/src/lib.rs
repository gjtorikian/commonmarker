extern crate core;

use comrak::{markdown_to_html_with_plugins, parse_document};
use magnus::{function, scan_args, Module, Ruby, Value};
use node::CommonmarkerNode;
use plugins::format_plugins;
use plugins::syntax_highlighting::construct_syntax_highlighter_from_plugin;

mod options;
mod plugins;
mod utils;

use typed_arena::Arena;

use crate::options::{default_options_to_hash, format_options};
use crate::plugins::default_plugins_to_hash;

mod node;

pub const EMPTY_STR: &str = "";

fn commonmark_parse(ruby: &Ruby, args: &[Value]) -> Result<CommonmarkerNode, magnus::Error> {
    let args = scan_args::scan_args::<_, (), (), (), _, ()>(args)?;
    let (rb_commonmark,): (String,) = args.required;

    let kwargs =
        scan_args::get_kwargs::<_, (), (Option<Value>,), ()>(args.keywords, &[], &["options"])?;
    let (rb_options,) = kwargs.optional;

    let comrak_options = format_options(ruby, rb_options)?;

    let arena = Arena::new();
    let root = parse_document(&arena, &rb_commonmark, &comrak_options);

    CommonmarkerNode::new_from_comrak_node(root)
}

fn commonmark_to_html(ruby: &Ruby, args: &[Value]) -> Result<String, magnus::Error> {
    let args = scan_args::scan_args::<_, (), (), (), _, ()>(args)?;
    let (rb_commonmark,): (String,) = args.required;

    let kwargs = scan_args::get_kwargs::<_, (), (Option<Value>, Option<Value>), ()>(
        args.keywords,
        &[],
        &["options", "plugins"],
    )?;
    let (rb_options, rb_plugins) = kwargs.optional;

    let comrak_options = format_options(ruby, rb_options)?;

    let mut comrak_plugins = comrak::options::Plugins::default();

    let formatted_plugins = format_plugins(ruby, rb_plugins)?;
    let syntect_adapter = match construct_syntax_highlighter_from_plugin(ruby, formatted_plugins) {
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

#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), magnus::Error> {
    let m_commonmarker = ruby.define_module("Commonmarker")?;

    // Define Config module to hold constants
    let m_config = m_commonmarker.define_module("Config")?;
    m_config.const_set("OPTIONS", default_options_to_hash(ruby)?)?;
    m_config.const_set("PLUGINS", default_plugins_to_hash(ruby)?)?;

    m_commonmarker.define_module_function("commonmark_parse", function!(commonmark_parse, -1))?;
    m_commonmarker
        .define_module_function("commonmark_to_html", function!(commonmark_to_html, -1))?;

    node::init(ruby, m_commonmarker).expect("cannot define Commonmarker::Node class");

    Ok(())
}
