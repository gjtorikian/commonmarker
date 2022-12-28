// use std::cell::{RefCell, RefMut};

// use comrak::{adapters::SyntaxHighlighterAdapter, plugins::syntect::SyntectAdapter, ComrakPlugins};
// use magnus::{class, r_hash::ForEach, Error, RHash, Symbol};

// use crate::plugins::syntax_highlighting::fetch_syntax_highlighter_theme;

pub mod syntax_highlighting;

pub const SYNTAX_HIGHLIGHTER_PLUGIN: &str = "syntax_highlighter";
pub const SYNTAX_HIGHLIGHTER_PLUGIN_THEME_KEY: &str = "theme";
pub const SYNTAX_HIGHLIGHTER_PLUGIN_DEFAULT_THEME: &str = "base16-ocean.dark";

// pub fn iterate_plugins_hash(
//     comrak_plugins: &mut ComrakPlugins,
//     mut adapter: Option<RefCell<Box<dyn SyntaxHighlighterAdapter>>>,
//     key: Symbol,
//     value: RHash,
// ) -> Result<ForEach, magnus::Error> {
//     assert!(value.is_kind_of(class::hash()));

//     if key.name().unwrap() == SYNTAX_HIGHLIGHTER_PLUGIN {
//         let theme_val = fetch_syntax_highlighter_theme(value)?;

//         if theme_val.is_none() || theme_val.unwrap() == "none" {
//             adapter = None;
//         } else {
//             // let inner = adapter.as_ref().as_mut();
//             let theme = theme_val.to_owned().unwrap();
//             let a = SyntectAdapter::new(theme);
//             // inner = Some(Box::new(SyntectAdapter::new(theme)));
//             // adapter = inner;

//             adapter = Some(RefCell::new(Box::new(a)));
//         }
//     }

//     Ok(ForEach::Continue)
// }
