// use comrak::ComrakPlugins;
// use magnus::{class, r_hash::ForEach, RHash, Symbol, Value};

// use crate::plugins::syntax_highlighting::fetch_syntax_highlighter_theme;

pub mod syntax_highlighting;

pub const SYNTAX_HIGHLIGHTER_PLUGIN: &str = "syntax_highlighter";

// pub fn iterate_plugins_hash(
//     comrak_plugins: &mut ComrakPlugins,
//     mut theme: String,
//     key: Symbol,
//     value: Value,
// ) -> Result<ForEach, magnus::Error> {
//     if key.name().unwrap() == SYNTAX_HIGHLIGHTER_PLUGIN {
//         theme = fetch_syntax_highlighter_theme(value)?;
//     }

//     Ok(ForEach::Continue)
// }
