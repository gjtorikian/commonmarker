extern crate core;

use comrak::{markdown_to_html, ComrakOptions};
use magnus::{define_module, function, r_hash::ForEach, Error, RHash, Symbol};

mod comrak_options;
use comrak_options::iterate_options_hash;

fn commonmark_to_html(rb_commonmark: String, rb_options: magnus::RHash) -> String {
    let mut comrak_options = ComrakOptions::default();

    rb_options.foreach(|key: Symbol, value: RHash| {
        iterate_options_hash(&mut comrak_options, key, value);
        Ok(ForEach::Continue)
    });

    markdown_to_html(&rb_commonmark, &comrak_options)
}

#[magnus::init]
fn init() -> Result<(), Error> {
    let module = define_module("Commonmarker")?;

    module.define_module_function("commonmark_to_html", function!(commonmark_to_html, 2))?;

    Ok(())
}
