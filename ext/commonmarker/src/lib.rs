extern crate core;

use std::fmt::{self, Write};
use std::sync::{Arc, OnceLock};

use comrak::parse_document;
use comrak::plugins::syntect::SyntectAdapter;
use magnus::{method, Class, Module, RString, Ruby, Value};
use node::CommonmarkerNode;
use plugins::syntax_highlighting::construct_syntax_highlighter_from_plugin;
use plugins::{comrak_plugins, format_plugins};

mod nesting;
mod options;
mod plugins;
mod rctree;
mod utils;

use rb_allocator::ruby_global_allocator;
use typed_arena::Arena;

use crate::options::{default_options_to_hash, format_options, Options};
use crate::plugins::default_plugins_to_hash;

mod node;

pub const EMPTY_STR: &str = "";

// Inform Ruby's GC about memory allocations.
ruby_global_allocator!();

/// A writer that writes directly to a Ruby String, avoiding intermediate Rust allocations.
struct RStringWriter(RString);

impl Write for RStringWriter {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        self.0.cat(s);
        Ok(())
    }
}

/// Borrows the CommonMark text as `&str`, rejecting invalid UTF-8.
fn commonmark_str<'a>(ruby: &Ruby, rb_commonmark: &'a RString) -> Result<&'a str, magnus::Error> {
    // SAFETY: We hold the GVL and rb_commonmark won't be modified until we return
    unsafe {
        rb_commonmark.as_str().map_err(|e| {
            magnus::Error::new(
                ruby.exception_encoding_error(),
                format!("invalid UTF-8: {e}"),
            )
        })
    }
}

/// Everything a `Commonmarker` instance needs to parse and render, processed
/// once from the Ruby `options` and `plugins` hashes.
struct Config {
    options: Options,
    syntax_highlighter: Option<Arc<SyntectAdapter>>,
}

impl Config {
    fn plugins(&self) -> comrak::options::Plugins<'_> {
        comrak_plugins(self.syntax_highlighter.as_deref())
    }
}

/// The Rust side of a `Commonmarker` instance.
///
/// Ruby allocates it empty and `initialize` fills it through `commonmark_init`,
/// so the configuration is validated once and every later `parse`/`to_html`
/// call reuses it. It holds no Ruby objects, so there is nothing to mark.
#[derive(Default)]
#[magnus::wrap(class = "Commonmarker", free_immediately, size)]
struct Commonmarker {
    config: OnceLock<Config>,
}

impl Commonmarker {
    /// `Commonmarker#commonmark_init(options, plugins)`, called from `initialize`.
    fn init(
        ruby: &Ruby,
        rb_self: &Self,
        rb_options: Value,
        rb_plugins: Value,
    ) -> Result<(), magnus::Error> {
        let options = format_options(ruby, Some(rb_options))?;
        let formatted_plugins = format_plugins(ruby, Some(rb_plugins))?;
        let syntax_highlighter = construct_syntax_highlighter_from_plugin(ruby, formatted_plugins)?;

        rb_self
            .config
            .set(Config {
                options,
                syntax_highlighter,
            })
            .map_err(|_| {
                magnus::Error::new(
                    ruby.exception_runtime_error(),
                    "Commonmarker instance is already initialized",
                )
            })
    }

    fn config(&self, ruby: &Ruby) -> Result<&Config, magnus::Error> {
        self.config.get().ok_or_else(|| {
            magnus::Error::new(
                ruby.exception_runtime_error(),
                "Commonmarker instance was not initialized; create it with Commonmarker.new",
            )
        })
    }

    /// `Commonmarker#commonmark_parse(text)`.
    fn parse(
        ruby: &Ruby,
        rb_self: &Self,
        rb_commonmark: RString,
    ) -> Result<CommonmarkerNode, magnus::Error> {
        let config = rb_self.config(ruby)?;
        let commonmark_str = commonmark_str(ruby, &rb_commonmark)?;

        let arena = Arena::new();
        let root = parse_document(&arena, commonmark_str, &config.options.comrak);

        CommonmarkerNode::new_from_comrak_node(ruby, root, config.options.max_nesting_depth)
    }

    /// `Commonmarker#commonmark_to_html(text)`.
    fn to_html(
        ruby: &Ruby,
        rb_self: &Self,
        rb_commonmark: RString,
    ) -> Result<RString, magnus::Error> {
        let config = rb_self.config(ruby)?;
        let commonmark_str = commonmark_str(ruby, &rb_commonmark)?;

        // Pre-allocate Ruby string with estimated capacity (assume HTML is typically 2x commonmark size)
        let output = ruby.str_with_capacity(commonmark_str.len() * 2);
        let mut writer = RStringWriter(output);

        // Parse and render directly to Ruby string, avoiding intermediate Rust String allocation
        let arena = Arena::new();
        let root = parse_document(&arena, commonmark_str, &config.options.comrak);

        nesting::check(ruby, root, config.options.max_nesting_depth)?;

        comrak::html::format_document_with_plugins(
            root,
            &config.options.comrak,
            &mut writer,
            &config.plugins(),
        )
        .map_err(|e| magnus::Error::new(ruby.exception_runtime_error(), e.to_string()))?;

        Ok(output)
    }

    /// `Commonmarker#commonmark_to_commonmark(text)`: parses the text and
    /// writes it back out as CommonMark.
    fn to_commonmark(
        ruby: &Ruby,
        rb_self: &Self,
        rb_commonmark: RString,
    ) -> Result<RString, magnus::Error> {
        let config = rb_self.config(ruby)?;
        let commonmark_str = commonmark_str(ruby, &rb_commonmark)?;

        let output = ruby.str_with_capacity(commonmark_str.len());
        let mut writer = RStringWriter(output);

        let arena = Arena::new();
        let root = parse_document(&arena, commonmark_str, &config.options.comrak);

        nesting::check(ruby, root, config.options.max_nesting_depth)?;

        comrak::format_commonmark_with_plugins(
            root,
            &config.options.comrak,
            &mut writer,
            &config.plugins(),
        )
        .map_err(|e| magnus::Error::new(ruby.exception_runtime_error(), e.to_string()))?;

        Ok(output)
    }

    /// `Commonmarker#commonmark_render_html(node)`.
    fn render_html(
        ruby: &Ruby,
        rb_self: &Self,
        node: &CommonmarkerNode,
    ) -> Result<String, magnus::Error> {
        let config = rb_self.config(ruby)?;

        node.render_html(ruby, &config.options, &config.plugins())
    }

    /// `Commonmarker#commonmark_render_commonmark(node)`.
    fn render_commonmark(
        ruby: &Ruby,
        rb_self: &Self,
        node: &CommonmarkerNode,
    ) -> Result<String, magnus::Error> {
        let config = rb_self.config(ruby)?;

        node.render_commonmark(ruby, &config.options, &config.plugins())
    }
}

#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), magnus::Error> {
    let c_commonmarker = ruby.define_class("Commonmarker", ruby.class_object())?;

    // Instances are allocated empty and configured by `initialize` (in Ruby),
    // which hands the options and plugins to `commonmark_init`.
    c_commonmarker.define_alloc_func::<Commonmarker>();
    c_commonmarker.define_private_method("commonmark_init", method!(Commonmarker::init, 2))?;
    c_commonmarker.define_private_method("commonmark_parse", method!(Commonmarker::parse, 1))?;
    c_commonmarker
        .define_private_method("commonmark_to_html", method!(Commonmarker::to_html, 1))?;
    c_commonmarker.define_private_method(
        "commonmark_to_commonmark",
        method!(Commonmarker::to_commonmark, 1),
    )?;
    c_commonmarker.define_private_method(
        "commonmark_render_html",
        method!(Commonmarker::render_html, 1),
    )?;
    c_commonmarker.define_private_method(
        "commonmark_render_commonmark",
        method!(Commonmarker::render_commonmark, 1),
    )?;

    // Define Config module to hold constants
    let m_config = c_commonmarker.define_module("Config")?;
    m_config.const_set("OPTIONS", default_options_to_hash(ruby)?)?;
    m_config.const_set("PLUGINS", default_plugins_to_hash(ruby)?)?;

    node::init(ruby, c_commonmarker).expect("cannot define Commonmarker::Node class");

    Ok(())
}
