use std::borrow::Cow;

use comrak::ComrakOptions;

use magnus::value::ReprValue;
use magnus::TryConvert;
use magnus::{class, r_hash::ForEach, Error, RHash, Symbol, Value};

use crate::utils::try_convert_string;

const PARSE_SMART: &str = "smart";
const PARSE_DEFAULT_INFO_STRING: &str = "default_info_string";
const PARSE_RELAXED_TASKLIST_MATCHING: &str = "relaxed_tasklist_matching";
const PARSE_RELAXED_AUTOLINKS: &str = "relaxed_autolinks";

fn iterate_parse_options(comrak_options: &mut ComrakOptions, options_hash: RHash) {
    options_hash
        .foreach(|key: Symbol, value: Value| {
            match key.name()? {
                Cow::Borrowed(PARSE_SMART) => {
                    comrak_options.parse.smart = TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(PARSE_DEFAULT_INFO_STRING) => {
                    comrak_options.parse.default_info_string = try_convert_string(value);
                }
                Cow::Borrowed(PARSE_RELAXED_TASKLIST_MATCHING) => {
                    comrak_options.parse.relaxed_tasklist_matching =
                        TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(PARSE_RELAXED_AUTOLINKS) => {
                    comrak_options.parse.relaxed_autolinks = TryConvert::try_convert(value)?;
                }
                _ => {}
            }
            Ok(ForEach::Continue)
        })
        .unwrap();
}

const RENDER_HARDBREAKS: &str = "hardbreaks";
const RENDER_GITHUB_PRE_LANG: &str = "github_pre_lang";
const RENDER_FULL_INFO_STRING: &str = "full_info_string";
const RENDER_WIDTH: &str = "width";
const RENDER_UNSAFE: &str = "unsafe";
const RENDER_ESCAPE: &str = "escape";
const RENDER_SOURCEPOS: &str = "sourcepos";
const RENDER_ESCAPED_CHAR_SPANS: &str = "escaped_char_spans";
const RENDER_IGNORE_SETEXT: &str = "ignore_setext";
const RENDER_IGNORE_EMPTY_LINKS: &str = "ignore_empty_links";
const RENDER_GFM_QUIRKS: &str = "gfm_quirks";
const RENDER_PREFER_FENCED: &str = "prefer_fenced";
const RENDER_TASKLIST_CLASSES: &str = "tasklist_classes";

fn iterate_render_options(comrak_options: &mut ComrakOptions, options_hash: RHash) {
    options_hash
        .foreach(|key: Symbol, value: Value| {
            match key.name()? {
                Cow::Borrowed(RENDER_HARDBREAKS) => {
                    comrak_options.render.hardbreaks = TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(RENDER_GITHUB_PRE_LANG) => {
                    comrak_options.render.github_pre_lang = TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(RENDER_FULL_INFO_STRING) => {
                    comrak_options.render.full_info_string = TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(RENDER_WIDTH) => {
                    comrak_options.render.width = TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(RENDER_UNSAFE) => {
                    comrak_options.render.unsafe_ = TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(RENDER_ESCAPE) => {
                    comrak_options.render.escape = TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(RENDER_SOURCEPOS) => {
                    comrak_options.render.sourcepos = TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(RENDER_ESCAPED_CHAR_SPANS) => {
                    comrak_options.render.escaped_char_spans = TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(RENDER_IGNORE_SETEXT) => {
                    comrak_options.render.ignore_setext = TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(RENDER_IGNORE_EMPTY_LINKS) => {
                    comrak_options.render.ignore_empty_links = TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(RENDER_GFM_QUIRKS) => {
                    comrak_options.render.gfm_quirks = TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(RENDER_PREFER_FENCED) => {
                    comrak_options.render.prefer_fenced = TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(RENDER_TASKLIST_CLASSES) => {
                    comrak_options.render.tasklist_classes = TryConvert::try_convert(value)?;
                }
                _ => {}
            }
            Ok(ForEach::Continue)
        })
        .unwrap();
}

const EXTENSION_STRIKETHROUGH: &str = "strikethrough";
const EXTENSION_TAGFILTER: &str = "tagfilter";
const EXTENSION_TABLE: &str = "table";
const EXTENSION_AUTOLINK: &str = "autolink";
const EXTENSION_TASKLIST: &str = "tasklist";
const EXTENSION_SUPERSCRIPT: &str = "superscript";
const EXTENSION_HEADER_IDS: &str = "header_ids";
const EXTENSION_FOOTNOTES: &str = "footnotes";
const EXTENSION_DESCRIPTION_LISTS: &str = "description_lists";
const EXTENSION_FRONT_MATTER_DELIMITER: &str = "front_matter_delimiter";
const EXTENSION_MULTILINE_BLOCK_QUOTES: &str = "multiline_block_quotes";
const EXTENSION_MATH_DOLLARS: &str = "math_dollars";
const EXTENSION_MATH_CODE: &str = "math_code";
const EXTENSION_SHORTCODES: &str = "shortcodes";
const EXTENSION_WIKILINKS_TITLE_AFTER_PIPE: &str = "wikilinks_title_after_pipe";
const EXTENSION_WIKILINKS_TITLE_BEFORE_PIPE: &str = "wikilinks_title_before_pipe";
const EXTENSION_UNDERLINE: &str = "underline";
const EXTENSION_SPOILER: &str = "spoiler";
const EXTENSION_GREENTEXT: &str = "greentext";
const EXTENSION_SUBSCRIPT: &str = "subscript";
const EXTENSION_ALERTS: &str = "alerts";

fn iterate_extension_options(comrak_options: &mut ComrakOptions, options_hash: RHash) {
    options_hash
        .foreach(|key: Symbol, value: Value| {
            match key.name()? {
                Cow::Borrowed(EXTENSION_STRIKETHROUGH) => {
                    comrak_options.extension.strikethrough = TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(EXTENSION_TAGFILTER) => {
                    comrak_options.extension.tagfilter = TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(EXTENSION_TABLE) => {
                    comrak_options.extension.table = TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(EXTENSION_AUTOLINK) => {
                    comrak_options.extension.autolink = TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(EXTENSION_TASKLIST) => {
                    comrak_options.extension.tasklist = TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(EXTENSION_SUPERSCRIPT) => {
                    comrak_options.extension.superscript = TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(EXTENSION_HEADER_IDS) => {
                    comrak_options.extension.header_ids = try_convert_string(value);
                }
                Cow::Borrowed(EXTENSION_FOOTNOTES) => {
                    comrak_options.extension.footnotes = TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(EXTENSION_DESCRIPTION_LISTS) => {
                    comrak_options.extension.description_lists = TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(EXTENSION_FRONT_MATTER_DELIMITER) => {
                    if let Some(option) = try_convert_string(value) {
                        if !option.is_empty() {
                            comrak_options.extension.front_matter_delimiter = Some(option);
                        }
                    }
                }
                Cow::Borrowed(EXTENSION_MULTILINE_BLOCK_QUOTES) => {
                    comrak_options.extension.multiline_block_quotes =
                        TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(EXTENSION_MATH_DOLLARS) => {
                    comrak_options.extension.math_dollars = TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(EXTENSION_MATH_CODE) => {
                    comrak_options.extension.math_code = TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(EXTENSION_SHORTCODES) => {
                    comrak_options.extension.shortcodes = TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(EXTENSION_WIKILINKS_TITLE_AFTER_PIPE) => {
                    comrak_options.extension.wikilinks_title_after_pipe =
                        TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(EXTENSION_WIKILINKS_TITLE_BEFORE_PIPE) => {
                    comrak_options.extension.wikilinks_title_before_pipe =
                        TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(EXTENSION_UNDERLINE) => {
                    comrak_options.extension.underline = TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(EXTENSION_SPOILER) => {
                    comrak_options.extension.spoiler = TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(EXTENSION_GREENTEXT) => {
                    comrak_options.extension.greentext = TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(EXTENSION_SUBSCRIPT) => {
                    comrak_options.extension.subscript = TryConvert::try_convert(value)?;
                }
                Cow::Borrowed(EXTENSION_ALERTS) => {
                    comrak_options.extension.alerts = TryConvert::try_convert(value)?;
                }
                _ => {}
            }
            Ok(ForEach::Continue)
        })
        .unwrap();
}

pub fn iterate_options_hash(
    comrak_options: &mut ComrakOptions,
    key: Symbol,
    value: RHash,
) -> Result<ForEach, Error> {
    assert!(value.is_kind_of(class::hash()));

    if key.name().unwrap() == "parse" {
        iterate_parse_options(comrak_options, value);
    }
    if key.name().unwrap() == "render" {
        iterate_render_options(comrak_options, value);
    }
    if key.name().unwrap() == "extension" {
        iterate_extension_options(comrak_options, value);
    }
    Ok(ForEach::Continue)
}
