use std::sync::LazyLock;

use magnus::value::ReprValue;
use magnus::TryConvert;
use magnus::{r_hash::ForEach, Error, RHash, Ruby, Symbol, Value};

// Commonmarker's default options (different from comrak defaults)
pub static DEFAULT_OPTIONS: LazyLock<comrak::Options> = LazyLock::new(|| {
    let mut options = comrak::Options::default();

    // Parse options
    options.parse.smart = false;
    options.parse.default_info_string = Some(String::new());
    options.parse.relaxed_tasklist_matching = false;
    options.parse.relaxed_autolinks = false;
    options.parse.ignore_setext = false;
    options.parse.leave_footnote_definitions = false;

    // Render options
    options.render.hardbreaks = true;
    options.render.github_pre_lang = true;
    options.render.full_info_string = false;
    options.render.width = 80;
    options.render.r#unsafe = false;
    options.render.escape = false;
    options.render.sourcepos = false;
    options.render.escaped_char_spans = true;
    options.render.ignore_empty_links = false;
    options.render.gfm_quirks = false;
    options.render.prefer_fenced = false;
    options.render.tasklist_classes = false;

    // Extension options
    options.extension.strikethrough = true;
    options.extension.tagfilter = true;
    options.extension.table = true;
    options.extension.autolink = true;
    options.extension.tasklist = true;
    options.extension.superscript = false;
    options.extension.header_ids = Some(String::new());
    options.extension.footnotes = false;
    options.extension.inline_footnotes = false;
    options.extension.description_lists = false;
    options.extension.front_matter_delimiter = None;
    options.extension.multiline_block_quotes = false;
    options.extension.math_dollars = false;
    options.extension.math_code = false;
    options.extension.shortcodes = true;
    options.extension.wikilinks_title_before_pipe = false;
    options.extension.wikilinks_title_after_pipe = false;
    options.extension.underline = false;
    options.extension.spoiler = false;
    options.extension.greentext = false;
    options.extension.subscript = false;
    options.extension.subtext = false;
    options.extension.alerts = false;
    options.extension.cjk_friendly_emphasis = false;
    options.extension.highlight = false;

    options
});

const PARSE: &str = "parse";
const RENDER: &str = "render";
const EXTENSION: &str = "extension";

const PARSE_SMART: &str = "smart";
const PARSE_DEFAULT_INFO_STRING: &str = "default_info_string";
const PARSE_RELAXED_TASKLIST_MATCHING: &str = "relaxed_tasklist_matching";
const PARSE_RELAXED_AUTOLINKS: &str = "relaxed_autolinks";
const PARSE_LEAVE_FOOTNOTE_DEFINITIONS: &str = "leave_footnote_definitions";

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

const EXTENSION_STRIKETHROUGH: &str = "strikethrough";
const EXTENSION_TAGFILTER: &str = "tagfilter";
const EXTENSION_TABLE: &str = "table";
const EXTENSION_AUTOLINK: &str = "autolink";
const EXTENSION_TASKLIST: &str = "tasklist";
const EXTENSION_SUPERSCRIPT: &str = "superscript";
const EXTENSION_HEADER_IDS: &str = "header_ids";
const EXTENSION_FOOTNOTES: &str = "footnotes";
const EXTENSION_INLINE_FOOTNOTES: &str = "inline_footnotes";
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
const EXTENSION_SUBTEXT: &str = "subtext";
const EXTENSION_ALERTS: &str = "alerts";
const EXTENSION_CJK_FRIENDLY_EMPHASIS: &str = "cjk_friendly_emphasis";
const EXTENSION_HIGHLIGHT: &str = "highlight";

// Comrak's default options (for when user explicitly sets nil)
pub static COMRAK_DEFAULTS: LazyLock<comrak::Options> = LazyLock::new(comrak::Options::default);

/// Validates a boolean option value.
/// Returns the value if valid (true or false), default_for_nil if nil, Err if invalid type.
fn validate_bool(
    ruby: &Ruby,
    value: Value,
    key: &str,
    category: &str,
    default_for_nil: bool,
) -> Result<bool, Error> {
    if value.is_nil() {
        return Ok(default_for_nil);
    }
    // Strictly check for TrueClass or FalseClass, reject other types
    let class_name = crate::utils::get_classname(value);
    match class_name.as_ref() {
        "TrueClass" => Ok(true),
        "FalseClass" => Ok(false),
        _ => Err(Error::new(
            ruby.exception_type_error(),
            format!(
                "{} option `{}` must be Boolean; got {}",
                category,
                format_args!(":{}", key),
                class_name
            ),
        )),
    }
}

/// Validates an integer option value.
/// Returns the value if valid, default_for_nil if nil, Err if invalid type.
fn validate_usize(
    ruby: &Ruby,
    value: Value,
    key: &str,
    category: &str,
    default_for_nil: usize,
) -> Result<usize, Error> {
    if value.is_nil() {
        return Ok(default_for_nil);
    }
    TryConvert::try_convert(value).map_err(|_| {
        Error::new(
            ruby.exception_type_error(),
            format!(
                "{} option `{}` must be Integer; got {}",
                category,
                format_args!(":{}", key),
                crate::utils::get_classname(value)
            ),
        )
    })
}

/// Validates an optional string option value (for Option<String> fields).
/// nil means None (disable the feature), valid string means Some(string).
fn validate_optional_string(
    ruby: &Ruby,
    value: Value,
    key: &str,
    category: &str,
) -> Result<Option<String>, Error> {
    if value.is_nil() {
        return Ok(None); // nil means disable the feature
    }
    let s: String = TryConvert::try_convert(value).map_err(|_| {
        Error::new(
            ruby.exception_type_error(),
            format!(
                "{} option `{}` must be String; got {}",
                category,
                format_args!(":{}", key),
                crate::utils::get_classname(value)
            ),
        )
    })?;
    Ok(Some(s))
}

/// Formats and validates options from Ruby, merging with defaults.
/// Accepts Option<Value> and returns ComrakOptions.
///
/// Logic:
/// - If no options: use DEFAULT_OPTIONS (commonmarker defaults)
/// - If options provided but category absent: use DEFAULT_OPTIONS for that category
/// - If category provided: start with commonmarker defaults, apply non-nil values from user
///   (nil values mean "keep default for this field")
pub fn format_options(
    ruby: &Ruby,
    rb_options: Option<Value>,
) -> Result<comrak::Options<'_>, Error> {
    let rb_options = match rb_options {
        None => return Ok(DEFAULT_OPTIONS.clone()),
        Some(v) if v.is_nil() => return Ok(DEFAULT_OPTIONS.clone()),
        Some(v) => v,
    };

    let options_hash: RHash = TryConvert::try_convert(rb_options).map_err(|_| {
        Error::new(
            ruby.exception_type_error(),
            format!(
                "options must be a Hash; got {}",
                crate::utils::get_classname(rb_options)
            ),
        )
    })?;

    if options_hash.is_empty() {
        return Ok(DEFAULT_OPTIONS.clone());
    }

    // Start with commonmarker defaults
    let mut options = DEFAULT_OPTIONS.clone();

    // Process parse options
    match options_hash.get(ruby.to_symbol(PARSE)) {
        None => {
            // Category not provided, keep commonmarker defaults (already set)
        }
        Some(parse_value) if parse_value.is_nil() => {
            // Category explicitly nil, keep commonmarker defaults (already set)
        }
        Some(parse_value) => {
            // Category provided, apply user values over commonmarker defaults
            let parse_hash: RHash = TryConvert::try_convert(parse_value).map_err(|_| {
                Error::new(
                    ruby.exception_type_error(),
                    format!(
                        "parse options must be a Hash; got {}",
                        crate::utils::get_classname(parse_value)
                    ),
                )
            })?;
            iterate_parse_options_with_validation(ruby, &mut options.parse, parse_hash)?;
        }
    }

    // Process render options
    match options_hash.get(ruby.to_symbol(RENDER)) {
        None => {
            // Keep commonmarker defaults (already set)
        }
        Some(render_value) if render_value.is_nil() => {
            // Category explicitly nil, keep commonmarker defaults (already set)
        }
        Some(render_value) => {
            let render_hash: RHash = TryConvert::try_convert(render_value).map_err(|_| {
                Error::new(
                    ruby.exception_type_error(),
                    format!(
                        "render options must be a Hash; got {}",
                        crate::utils::get_classname(render_value)
                    ),
                )
            })?;
            iterate_render_options_with_validation(ruby, &mut options.render, render_hash)?;
        }
    }

    // Process extension options
    match options_hash.get(ruby.to_symbol(EXTENSION)) {
        None => {
            // Keep commonmarker defaults (already set)
        }
        Some(extension_value) if extension_value.is_nil() => {
            // Category explicitly nil, keep commonmarker defaults (already set)
        }
        Some(extension_value) => {
            let extension_hash: RHash = TryConvert::try_convert(extension_value).map_err(|_| {
                Error::new(
                    ruby.exception_type_error(),
                    format!(
                        "extension options must be a Hash; got {}",
                        crate::utils::get_classname(extension_value)
                    ),
                )
            })?;
            iterate_extension_options_with_validation(
                ruby,
                &mut options.extension,
                extension_hash,
            )?;
        }
    }

    Ok(options)
}

fn iterate_parse_options_with_validation(
    ruby: &Ruby,
    comrak_options: &mut comrak::options::Parse,
    options_hash: RHash,
) -> Result<(), Error> {
    let mut error: Option<Error> = None;
    let defaults = &COMRAK_DEFAULTS.parse;

    options_hash
        .foreach(|key: Symbol, value: Value| {
            match key.name()?.as_ref() {
                PARSE_SMART => {
                    match validate_bool(ruby, value, PARSE_SMART, "parse", defaults.smart) {
                        Ok(v) => comrak_options.smart = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                PARSE_DEFAULT_INFO_STRING => {
                    match validate_optional_string(ruby, value, PARSE_DEFAULT_INFO_STRING, "parse")
                    {
                        Ok(v) => comrak_options.default_info_string = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                PARSE_RELAXED_TASKLIST_MATCHING => {
                    match validate_bool(
                        ruby,
                        value,
                        PARSE_RELAXED_TASKLIST_MATCHING,
                        "parse",
                        defaults.relaxed_tasklist_matching,
                    ) {
                        Ok(v) => comrak_options.relaxed_tasklist_matching = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                RENDER_IGNORE_SETEXT => {
                    match validate_bool(
                        ruby,
                        value,
                        RENDER_IGNORE_SETEXT,
                        "parse",
                        defaults.ignore_setext,
                    ) {
                        Ok(v) => comrak_options.ignore_setext = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                PARSE_RELAXED_AUTOLINKS => {
                    match validate_bool(
                        ruby,
                        value,
                        PARSE_RELAXED_AUTOLINKS,
                        "parse",
                        defaults.relaxed_autolinks,
                    ) {
                        Ok(v) => comrak_options.relaxed_autolinks = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                PARSE_LEAVE_FOOTNOTE_DEFINITIONS => {
                    match validate_bool(
                        ruby,
                        value,
                        PARSE_LEAVE_FOOTNOTE_DEFINITIONS,
                        "parse",
                        defaults.leave_footnote_definitions,
                    ) {
                        Ok(v) => comrak_options.leave_footnote_definitions = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                _ => {}
            }
            Ok(ForEach::Continue)
        })
        .unwrap();

    match error {
        Some(e) => Err(e),
        None => Ok(()),
    }
}

fn iterate_render_options_with_validation(
    ruby: &Ruby,
    comrak_options: &mut comrak::options::Render,
    options_hash: RHash,
) -> Result<(), Error> {
    let mut error: Option<Error> = None;
    let defaults = &COMRAK_DEFAULTS.render;

    options_hash
        .foreach(|key: Symbol, value: Value| {
            match key.name()?.as_ref() {
                RENDER_HARDBREAKS => {
                    match validate_bool(
                        ruby,
                        value,
                        RENDER_HARDBREAKS,
                        "render",
                        defaults.hardbreaks,
                    ) {
                        Ok(v) => comrak_options.hardbreaks = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                RENDER_GITHUB_PRE_LANG => {
                    match validate_bool(
                        ruby,
                        value,
                        RENDER_GITHUB_PRE_LANG,
                        "render",
                        defaults.github_pre_lang,
                    ) {
                        Ok(v) => comrak_options.github_pre_lang = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                RENDER_FULL_INFO_STRING => {
                    match validate_bool(
                        ruby,
                        value,
                        RENDER_FULL_INFO_STRING,
                        "render",
                        defaults.full_info_string,
                    ) {
                        Ok(v) => comrak_options.full_info_string = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                RENDER_WIDTH => {
                    match validate_usize(ruby, value, RENDER_WIDTH, "render", defaults.width) {
                        Ok(v) => comrak_options.width = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                RENDER_UNSAFE => {
                    match validate_bool(ruby, value, RENDER_UNSAFE, "render", defaults.r#unsafe) {
                        Ok(v) => comrak_options.r#unsafe = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                RENDER_ESCAPE => {
                    match validate_bool(ruby, value, RENDER_ESCAPE, "render", defaults.escape) {
                        Ok(v) => comrak_options.escape = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                RENDER_SOURCEPOS => {
                    match validate_bool(ruby, value, RENDER_SOURCEPOS, "render", defaults.sourcepos)
                    {
                        Ok(v) => comrak_options.sourcepos = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                RENDER_ESCAPED_CHAR_SPANS => {
                    match validate_bool(
                        ruby,
                        value,
                        RENDER_ESCAPED_CHAR_SPANS,
                        "render",
                        defaults.escaped_char_spans,
                    ) {
                        Ok(v) => comrak_options.escaped_char_spans = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                RENDER_IGNORE_EMPTY_LINKS => {
                    match validate_bool(
                        ruby,
                        value,
                        RENDER_IGNORE_EMPTY_LINKS,
                        "render",
                        defaults.ignore_empty_links,
                    ) {
                        Ok(v) => comrak_options.ignore_empty_links = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                RENDER_GFM_QUIRKS => {
                    match validate_bool(
                        ruby,
                        value,
                        RENDER_GFM_QUIRKS,
                        "render",
                        defaults.gfm_quirks,
                    ) {
                        Ok(v) => comrak_options.gfm_quirks = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                RENDER_PREFER_FENCED => {
                    match validate_bool(
                        ruby,
                        value,
                        RENDER_PREFER_FENCED,
                        "render",
                        defaults.prefer_fenced,
                    ) {
                        Ok(v) => comrak_options.prefer_fenced = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                RENDER_TASKLIST_CLASSES => {
                    match validate_bool(
                        ruby,
                        value,
                        RENDER_TASKLIST_CLASSES,
                        "render",
                        defaults.tasklist_classes,
                    ) {
                        Ok(v) => comrak_options.tasklist_classes = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                _ => {}
            }
            Ok(ForEach::Continue)
        })
        .unwrap();

    match error {
        Some(e) => Err(e),
        None => Ok(()),
    }
}

fn iterate_extension_options_with_validation(
    ruby: &Ruby,
    comrak_options: &mut comrak::options::Extension,
    options_hash: RHash,
) -> Result<(), Error> {
    let mut error: Option<Error> = None;
    let defaults = &COMRAK_DEFAULTS.extension;

    options_hash
        .foreach(|key: Symbol, value: Value| {
            match key.name()?.as_ref() {
                EXTENSION_STRIKETHROUGH => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_STRIKETHROUGH,
                        "extension",
                        defaults.strikethrough,
                    ) {
                        Ok(v) => comrak_options.strikethrough = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_TAGFILTER => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_TAGFILTER,
                        "extension",
                        defaults.tagfilter,
                    ) {
                        Ok(v) => comrak_options.tagfilter = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_TABLE => {
                    match validate_bool(ruby, value, EXTENSION_TABLE, "extension", defaults.table) {
                        Ok(v) => comrak_options.table = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_AUTOLINK => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_AUTOLINK,
                        "extension",
                        defaults.autolink,
                    ) {
                        Ok(v) => comrak_options.autolink = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_TASKLIST => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_TASKLIST,
                        "extension",
                        defaults.tasklist,
                    ) {
                        Ok(v) => comrak_options.tasklist = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_SUPERSCRIPT => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_SUPERSCRIPT,
                        "extension",
                        defaults.superscript,
                    ) {
                        Ok(v) => comrak_options.superscript = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_HEADER_IDS => {
                    match validate_optional_string(ruby, value, EXTENSION_HEADER_IDS, "extension") {
                        Ok(v) => comrak_options.header_ids = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_FOOTNOTES => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_FOOTNOTES,
                        "extension",
                        defaults.footnotes,
                    ) {
                        Ok(v) => comrak_options.footnotes = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_INLINE_FOOTNOTES => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_INLINE_FOOTNOTES,
                        "extension",
                        defaults.inline_footnotes,
                    ) {
                        Ok(v) => comrak_options.inline_footnotes = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_DESCRIPTION_LISTS => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_DESCRIPTION_LISTS,
                        "extension",
                        defaults.description_lists,
                    ) {
                        Ok(v) => comrak_options.description_lists = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_FRONT_MATTER_DELIMITER => {
                    match validate_optional_string(
                        ruby,
                        value,
                        EXTENSION_FRONT_MATTER_DELIMITER,
                        "extension",
                    ) {
                        Ok(v) => comrak_options.front_matter_delimiter = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_MULTILINE_BLOCK_QUOTES => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_MULTILINE_BLOCK_QUOTES,
                        "extension",
                        defaults.multiline_block_quotes,
                    ) {
                        Ok(v) => comrak_options.multiline_block_quotes = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_MATH_DOLLARS => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_MATH_DOLLARS,
                        "extension",
                        defaults.math_dollars,
                    ) {
                        Ok(v) => comrak_options.math_dollars = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_MATH_CODE => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_MATH_CODE,
                        "extension",
                        defaults.math_code,
                    ) {
                        Ok(v) => comrak_options.math_code = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_SHORTCODES => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_SHORTCODES,
                        "extension",
                        defaults.shortcodes,
                    ) {
                        Ok(v) => comrak_options.shortcodes = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_WIKILINKS_TITLE_AFTER_PIPE => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_WIKILINKS_TITLE_AFTER_PIPE,
                        "extension",
                        defaults.wikilinks_title_after_pipe,
                    ) {
                        Ok(v) => comrak_options.wikilinks_title_after_pipe = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_WIKILINKS_TITLE_BEFORE_PIPE => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_WIKILINKS_TITLE_BEFORE_PIPE,
                        "extension",
                        defaults.wikilinks_title_before_pipe,
                    ) {
                        Ok(v) => comrak_options.wikilinks_title_before_pipe = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_UNDERLINE => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_UNDERLINE,
                        "extension",
                        defaults.underline,
                    ) {
                        Ok(v) => comrak_options.underline = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_SPOILER => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_SPOILER,
                        "extension",
                        defaults.spoiler,
                    ) {
                        Ok(v) => comrak_options.spoiler = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_GREENTEXT => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_GREENTEXT,
                        "extension",
                        defaults.greentext,
                    ) {
                        Ok(v) => comrak_options.greentext = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_SUBSCRIPT => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_SUBSCRIPT,
                        "extension",
                        defaults.subscript,
                    ) {
                        Ok(v) => comrak_options.subscript = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_SUBTEXT => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_SUBTEXT,
                        "extension",
                        defaults.subtext,
                    ) {
                        Ok(v) => comrak_options.subtext = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_ALERTS => {
                    match validate_bool(ruby, value, EXTENSION_ALERTS, "extension", defaults.alerts)
                    {
                        Ok(v) => comrak_options.alerts = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_CJK_FRIENDLY_EMPHASIS => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_CJK_FRIENDLY_EMPHASIS,
                        "extension",
                        defaults.cjk_friendly_emphasis,
                    ) {
                        Ok(v) => comrak_options.cjk_friendly_emphasis = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_HIGHLIGHT => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_HIGHLIGHT,
                        "extension",
                        defaults.highlight,
                    ) {
                        Ok(v) => comrak_options.highlight = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                _ => {}
            }
            Ok(ForEach::Continue)
        })
        .unwrap();

    match error {
        Some(e) => Err(e),
        None => Ok(()),
    }
}

/// Returns the default options as a Ruby Hash for introspection.
pub fn default_options_to_hash(ruby: &Ruby) -> Result<RHash, Error> {
    let options = ruby.hash_new();

    // Parse options
    let parse = ruby.hash_new();
    parse.aset(ruby.to_symbol(PARSE_SMART), DEFAULT_OPTIONS.parse.smart)?;
    parse.aset(
        ruby.to_symbol(PARSE_DEFAULT_INFO_STRING),
        DEFAULT_OPTIONS
            .parse
            .default_info_string
            .as_deref()
            .unwrap_or(""),
    )?;
    parse.aset(
        ruby.to_symbol(PARSE_RELAXED_TASKLIST_MATCHING),
        DEFAULT_OPTIONS.parse.relaxed_tasklist_matching,
    )?;
    parse.aset(
        ruby.to_symbol(PARSE_RELAXED_AUTOLINKS),
        DEFAULT_OPTIONS.parse.relaxed_autolinks,
    )?;
    parse.aset(
        ruby.to_symbol(PARSE_LEAVE_FOOTNOTE_DEFINITIONS),
        DEFAULT_OPTIONS.parse.leave_footnote_definitions,
    )?;
    options.aset(ruby.to_symbol(PARSE), parse)?;

    // Render options
    let render = ruby.hash_new();
    render.aset(
        ruby.to_symbol(RENDER_HARDBREAKS),
        DEFAULT_OPTIONS.render.hardbreaks,
    )?;
    render.aset(
        ruby.to_symbol(RENDER_GITHUB_PRE_LANG),
        DEFAULT_OPTIONS.render.github_pre_lang,
    )?;
    render.aset(
        ruby.to_symbol(RENDER_FULL_INFO_STRING),
        DEFAULT_OPTIONS.render.full_info_string,
    )?;
    render.aset(ruby.to_symbol(RENDER_WIDTH), DEFAULT_OPTIONS.render.width)?;
    render.aset(
        ruby.to_symbol(RENDER_UNSAFE),
        DEFAULT_OPTIONS.render.r#unsafe,
    )?;
    render.aset(ruby.to_symbol(RENDER_ESCAPE), DEFAULT_OPTIONS.render.escape)?;
    render.aset(
        ruby.to_symbol(RENDER_SOURCEPOS),
        DEFAULT_OPTIONS.render.sourcepos,
    )?;
    render.aset(
        ruby.to_symbol(RENDER_ESCAPED_CHAR_SPANS),
        DEFAULT_OPTIONS.render.escaped_char_spans,
    )?;
    render.aset(
        ruby.to_symbol(RENDER_IGNORE_SETEXT),
        DEFAULT_OPTIONS.parse.ignore_setext,
    )?;
    render.aset(
        ruby.to_symbol(RENDER_IGNORE_EMPTY_LINKS),
        DEFAULT_OPTIONS.render.ignore_empty_links,
    )?;
    render.aset(
        ruby.to_symbol(RENDER_GFM_QUIRKS),
        DEFAULT_OPTIONS.render.gfm_quirks,
    )?;
    render.aset(
        ruby.to_symbol(RENDER_PREFER_FENCED),
        DEFAULT_OPTIONS.render.prefer_fenced,
    )?;
    render.aset(
        ruby.to_symbol(RENDER_TASKLIST_CLASSES),
        DEFAULT_OPTIONS.render.tasklist_classes,
    )?;
    options.aset(ruby.to_symbol(RENDER), render)?;

    // Extension options
    let extension = ruby.hash_new();
    extension.aset(
        ruby.to_symbol(EXTENSION_STRIKETHROUGH),
        DEFAULT_OPTIONS.extension.strikethrough,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_TAGFILTER),
        DEFAULT_OPTIONS.extension.tagfilter,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_TABLE),
        DEFAULT_OPTIONS.extension.table,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_AUTOLINK),
        DEFAULT_OPTIONS.extension.autolink,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_TASKLIST),
        DEFAULT_OPTIONS.extension.tasklist,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_SUPERSCRIPT),
        DEFAULT_OPTIONS.extension.superscript,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_HEADER_IDS),
        DEFAULT_OPTIONS
            .extension
            .header_ids
            .as_deref()
            .unwrap_or(""),
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_FOOTNOTES),
        DEFAULT_OPTIONS.extension.footnotes,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_INLINE_FOOTNOTES),
        DEFAULT_OPTIONS.extension.inline_footnotes,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_DESCRIPTION_LISTS),
        DEFAULT_OPTIONS.extension.description_lists,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_FRONT_MATTER_DELIMITER),
        DEFAULT_OPTIONS
            .extension
            .front_matter_delimiter
            .as_deref()
            .unwrap_or(""),
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_MULTILINE_BLOCK_QUOTES),
        DEFAULT_OPTIONS.extension.multiline_block_quotes,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_MATH_DOLLARS),
        DEFAULT_OPTIONS.extension.math_dollars,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_MATH_CODE),
        DEFAULT_OPTIONS.extension.math_code,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_SHORTCODES),
        DEFAULT_OPTIONS.extension.shortcodes,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_WIKILINKS_TITLE_BEFORE_PIPE),
        DEFAULT_OPTIONS.extension.wikilinks_title_before_pipe,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_WIKILINKS_TITLE_AFTER_PIPE),
        DEFAULT_OPTIONS.extension.wikilinks_title_after_pipe,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_UNDERLINE),
        DEFAULT_OPTIONS.extension.underline,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_SPOILER),
        DEFAULT_OPTIONS.extension.spoiler,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_GREENTEXT),
        DEFAULT_OPTIONS.extension.greentext,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_SUBSCRIPT),
        DEFAULT_OPTIONS.extension.subscript,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_SUBTEXT),
        DEFAULT_OPTIONS.extension.subtext,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_ALERTS),
        DEFAULT_OPTIONS.extension.alerts,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_CJK_FRIENDLY_EMPHASIS),
        DEFAULT_OPTIONS.extension.cjk_friendly_emphasis,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_HIGHLIGHT),
        DEFAULT_OPTIONS.extension.highlight,
    )?;
    options.aset(ruby.to_symbol(EXTENSION), extension)?;

    Ok(options)
}
