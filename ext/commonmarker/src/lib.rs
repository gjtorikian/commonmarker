extern crate core;

use std::fmt::{self, Write};

use comrak::parse_document;
use magnus::{function, scan_args, RHash, RString, Ruby, Value};
use node::CommonmarkerNode;
use plugins::syntax_highlighting::construct_syntax_highlighter_from_plugin;

mod options;

mod plugins;

use typed_arena::Arena;

use crate::options::{iterate_extension_options, iterate_parse_options, iterate_render_options};

mod node;
mod utils;

pub const EMPTY_STR: &str = "";

#[cfg(not(target_env = "msvc"))]
use tikv_jemallocator::Jemalloc;

#[cfg(not(target_env = "msvc"))]
#[global_allocator]
static GLOBAL: Jemalloc = Jemalloc;

/// A writer that writes directly to a Ruby String, avoiding intermediate Rust allocations.
struct RStringWriter(RString);

impl Write for RStringWriter {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        self.0.cat(s);
        Ok(())
    }
}

fn commonmark_parse(ruby: &Ruby, args: &[Value]) -> Result<CommonmarkerNode, magnus::Error> {
    let args = scan_args::scan_args::<_, (), (), (), _, ()>(args)?;
    let (rb_commonmark,): (RString,) = args.required;

    // SAFETY: We hold the GVL and rb_commonmark won't be modified until we return
    let commonmark_str = unsafe {
        rb_commonmark.as_str().map_err(|e| {
            magnus::Error::new(
                ruby.exception_encoding_error(),
                format!("invalid UTF-8: {}", e),
            )
        })?
    };

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
    let root = parse_document(&arena, commonmark_str, &comrak_options);

    CommonmarkerNode::new_from_comrak_node(root)
}

fn commonmark_to_html(ruby: &Ruby, args: &[Value]) -> Result<RString, magnus::Error> {
    let args = scan_args::scan_args::<_, (), (), (), _, ()>(args)?;
    let (rb_commonmark,): (RString,) = args.required;

    // SAFETY: We hold the GVL and rb_commonmark won't be modified until we return
    let commonmark_str = unsafe {
        rb_commonmark.as_str().map_err(|e| {
            magnus::Error::new(
                ruby.exception_encoding_error(),
                format!("invalid UTF-8: {}", e),
            )
        })?
    };

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

    let syntect_adapter = match construct_syntax_highlighter_from_plugin(ruby, rb_plugins) {
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

    // Pre-allocate Ruby string with estimated capacity (assume HTML is typically 2x commonmark size)
    let output = ruby.str_with_capacity(commonmark_str.len() * 2);
    let mut writer = RStringWriter(output);

    // Parse and render directly to Ruby string, avoiding intermediate Rust String allocation
    let arena = Arena::new();
    let root = parse_document(&arena, commonmark_str, &comrak_options);

    comrak::html::format_document_with_plugins(root, &comrak_options, &mut writer, &comrak_plugins)
        .map_err(|e| magnus::Error::new(ruby.exception_runtime_error(), e.to_string()))?;

    Ok(output)
}

#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), magnus::Error> {
    let m_commonmarker = ruby.define_module("Commonmarker")?;

    m_commonmarker.define_module_function("commonmark_parse", function!(commonmark_parse, -1))?;
    m_commonmarker
        .define_module_function("commonmark_to_html", function!(commonmark_to_html, -1))?;

    node::init(ruby, m_commonmarker).expect("cannot define Commonmarker::Node class");

    Ok(())
}
