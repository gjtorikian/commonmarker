extern crate core;

use comrak::{markdown_to_html_with_plugins, parse_document};
use magnus::{function, r_hash::ForEach, scan_args, Error, RHash, Symbol, Value};
use node::CommonmarkerNode;
use plugins::syntax_highlighting::construct_syntax_highlighter_from_plugin;

mod options;

mod plugins;

use typed_arena::Arena;

use crate::options::{iterate_extension_options, iterate_parse_options, iterate_render_options};

mod node;
mod utils;

pub const EMPTY_STR: &str = "";

fn commonmark_parse(args: &[Value]) -> Result<CommonmarkerNode, magnus::Error> {
    let args = scan_args::scan_args::<_, (), (), (), _, ()>(args)?;
    let (rb_commonmark,): (String,) = args.required;

    let kwargs = scan_args::get_kwargs::<_, (), (Option<RHash>, Option<RHash>, Option<RHash>), ()>(
        args.keywords,
        &[],
        &["parse", "render", "extension"],
    )?;
    let (rb_parse, rb_render, rb_extension) = kwargs.optional;

    let mut comrak_parse_options = comrak::options::Parse::default();
    let mut comrak_render_options = comrak::options::Render::default();
    let mut comrak_extension_options = comrak::options::Extension::default();

    if let Some(rb_parse) = rb_parse {
        iterate_parse_options(&mut comrak_parse_options, rb_parse);
    }
    if let Some(rb_render) = rb_render {
        iterate_render_options(&mut comrak_render_options, rb_render);
    }
    if let Some(rb_extension) = rb_extension {
        iterate_extension_options(&mut comrak_extension_options, rb_extension);
    }

    let comrak_options = comrak::Options {
        parse: comrak_parse_options,
        render: comrak_render_options,
        extension: comrak_extension_options,
    };

    let arena = Arena::new();
    let root = parse_document(&arena, &rb_commonmark, &comrak_options);

    CommonmarkerNode::new_from_comrak_node(root)
}

fn commonmark_to_html(args: &[Value]) -> Result<String, magnus::Error> {
    let args = scan_args::scan_args::<_, (), (), (), _, ()>(args)?;
    let (rb_commonmark,): (String,) = args.required;

    let kwargs = scan_args::get_kwargs::<
        _,
        (),
        (Option<RHash>, Option<RHash>, Option<RHash>, Option<RHash>),
        (),
    >(
        args.keywords,
        &[],
        &["render", "parse", "extension", "plugins"],
    )?;
    let (rb_render, rb_parse, rb_extension, rb_plugins) = kwargs.optional;

    let mut comrak_parse_options = comrak::options::Parse::default();
    let mut comrak_render_options = comrak::options::Render::default();
    let mut comrak_extension_options = comrak::options::Extension::default();

    if let Some(rb_parse) = rb_parse {
        iterate_parse_options(&mut comrak_parse_options, rb_parse);
    }
    if let Some(rb_render) = rb_render {
        iterate_render_options(&mut comrak_render_options, rb_render);
    }
    if let Some(rb_extension) = rb_extension {
        iterate_extension_options(&mut comrak_extension_options, rb_extension);
    }

    let mut comrak_plugins = comrak::options::Plugins::default();

    let syntect_adapter = match construct_syntax_highlighter_from_plugin(rb_plugins) {
        Ok(Some(adapter)) => Some(adapter),
        Ok(None) => None,
        Err(err) => return Err(err),
    };

    match syntect_adapter {
        Some(ref adapter) => comrak_plugins.render.codefence_syntax_highlighter = Some(adapter),
        None => comrak_plugins.render.codefence_syntax_highlighter = None,
    }

    let comrak_options = comrak::Options {
        parse: comrak_parse_options,
        render: comrak_render_options,
        extension: comrak_extension_options,
    };

    Ok(markdown_to_html_with_plugins(
        &rb_commonmark,
        &comrak_options,
        &comrak_plugins,
    ))
}

#[magnus::init]
fn init() -> Result<(), Error> {
    let ruby = magnus::Ruby::get().unwrap();
    let m_commonmarker = ruby.define_module("Commonmarker")?;

    m_commonmarker.define_module_function("commonmark_parse", function!(commonmark_parse, -1))?;
    m_commonmarker
        .define_module_function("commonmark_to_html", function!(commonmark_to_html, -1))?;

    node::init(m_commonmarker).expect("cannot define Commonmarker::Node class");

    Ok(())
}
