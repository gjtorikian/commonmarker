use std::sync::LazyLock;

use magnus::value::ReprValue;
use magnus::TryConvert;
use magnus::{r_hash::ForEach, Error, RHash, Ruby, Symbol, Value};

use crate::nesting::DEFAULT_MAX_NESTING_DEPTH;

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
    options.parse.sourcepos_chars = false;
    options.parse.tasklist_in_table = false;
    options.parse.escaped_char_spans = false;

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
    options.render.compact_html = false;
    options.render.alert_style = comrak::options::AlertStyleType::Specific;
    options.render.list_style = comrak::options::ListStyleType::Dash;
    options.render.figure_with_caption = false;
    options.render.ol_width = 0;
    options.render.experimental_minimize_commonmark = false;
    options.render.attributes = false;

    // Extension options
    options.extension.strikethrough = true;
    options.extension.table = true;
    options.extension.autolink = true;
    options.extension.tasklist = true;
    options.extension.superscript = false;
    options.extension.header_id_prefix = Some(String::new());
    options.extension.header_id_prefix_in_href = false;
    options.extension.footnotes = false;
    options.extension.inline_footnotes = false;
    options.extension.description_lists = false;
    options.extension.front_matter_delimiter = None;
    options.extension.multiline_block_quotes = false;
    options.extension.math_dollars = false;
    options.extension.math_code = false;
    options.extension.math_latex = false;
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
    options.extension.insert = false;
    options.extension.block_directive = false;
    options.extension.math_dollars_block = false;
    options.extension.wikilinks_ignore_embeds = false;
    options.extension.ofm_callouts = false;
    options.extension.ofm_comments = false;
    options.extension.ofm_block_ids = false;
    options.extension.header_attributes = false;
    options.extension.fenced_code_attributes = false;
    options.extension.inline_code_attributes = false;
    options.extension.link_attributes = false;

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
const PARSE_IGNORE_SETEXT: &str = "ignore_setext";
const PARSE_SOURCEPOS_CHARS: &str = "sourcepos_chars";
const PARSE_MAX_NESTING_DEPTH: &str = "max_nesting_depth";
const PARSE_TASKLIST_IN_TABLE: &str = "tasklist_in_table";
const PARSE_ESCAPED_CHAR_SPANS: &str = "escaped_char_spans";

const RENDER_HARDBREAKS: &str = "hardbreaks";
const RENDER_GITHUB_PRE_LANG: &str = "github_pre_lang";
const RENDER_FULL_INFO_STRING: &str = "full_info_string";
const RENDER_WIDTH: &str = "width";
const RENDER_UNSAFE: &str = "unsafe";
const RENDER_ESCAPE: &str = "escape";
const RENDER_SOURCEPOS: &str = "sourcepos";
const RENDER_ESCAPED_CHAR_SPANS: &str = "escaped_char_spans";
const RENDER_IGNORE_EMPTY_LINKS: &str = "ignore_empty_links";
const RENDER_GFM_QUIRKS: &str = "gfm_quirks";
const RENDER_PREFER_FENCED: &str = "prefer_fenced";
const RENDER_TASKLIST_CLASSES: &str = "tasklist_classes";
const RENDER_COMPACT_HTML: &str = "compact_html";
const RENDER_ALERT_STYLE: &str = "alert_style";
const RENDER_LIST_STYLE: &str = "list_style";
const RENDER_FIGURE_WITH_CAPTION: &str = "figure_with_caption";
const RENDER_OL_WIDTH: &str = "ol_width";
const RENDER_EXPERIMENTAL_MINIMIZE_COMMONMARK: &str = "experimental_minimize_commonmark";
const RENDER_ATTRIBUTES: &str = "attributes";

/// The names `alert_style` accepts, as Strings or Symbols.
const ALERT_STYLES: &[&str] = &["specific", "semantic"];
/// The names `list_style` accepts, as Strings or Symbols.
const LIST_STYLES: &[&str] = &["dash", "plus", "star"];

const EXTENSION_STRIKETHROUGH: &str = "strikethrough";
const EXTENSION_TABLE: &str = "table";
const EXTENSION_AUTOLINK: &str = "autolink";
const EXTENSION_TASKLIST: &str = "tasklist";
const EXTENSION_SUPERSCRIPT: &str = "superscript";
const EXTENSION_HEADER_IDS: &str = "header_ids";
const EXTENSION_HEADER_ID_PREFIX_IN_HREF: &str = "header_id_prefix_in_href";
const EXTENSION_FOOTNOTES: &str = "footnotes";
const EXTENSION_INLINE_FOOTNOTES: &str = "inline_footnotes";
const EXTENSION_DESCRIPTION_LISTS: &str = "description_lists";
const EXTENSION_FRONT_MATTER_DELIMITER: &str = "front_matter_delimiter";
const EXTENSION_MULTILINE_BLOCK_QUOTES: &str = "multiline_block_quotes";
const EXTENSION_MATH_DOLLARS: &str = "math_dollars";
const EXTENSION_MATH_CODE: &str = "math_code";
const EXTENSION_MATH_LATEX: &str = "math_latex";
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
const EXTENSION_INSERT: &str = "insert";
const EXTENSION_BLOCK_DIRECTIVE: &str = "block_directive";
const EXTENSION_MATH_DOLLARS_BLOCK: &str = "math_dollars_block";
const EXTENSION_WIKILINKS_IGNORE_EMBEDS: &str = "wikilinks_ignore_embeds";
const EXTENSION_OFM_CALLOUTS: &str = "ofm_callouts";
const EXTENSION_OFM_COMMENTS: &str = "ofm_comments";
const EXTENSION_OFM_BLOCK_IDS: &str = "ofm_block_ids";
const EXTENSION_HEADER_ATTRIBUTES: &str = "header_attributes";
const EXTENSION_FENCED_CODE_ATTRIBUTES: &str = "fenced_code_attributes";
const EXTENSION_INLINE_CODE_ATTRIBUTES: &str = "inline_code_attributes";
const EXTENSION_LINK_ATTRIBUTES: &str = "link_attributes";

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

/// Validates a non-negative integer option value.
/// Returns the value if valid, default_for_nil if nil, Err if invalid type or negative.
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
    let n: i64 = TryConvert::try_convert(value).map_err(|_| {
        Error::new(
            ruby.exception_type_error(),
            format!(
                "{} option `{}` must be Integer; got {}",
                category,
                format_args!(":{}", key),
                crate::utils::get_classname(value)
            ),
        )
    })?;
    usize::try_from(n).map_err(|_| {
        Error::new(
            ruby.exception_arg_error(),
            format!(
                "{} option `{}` must be a non-negative Integer; got {}",
                category,
                format_args!(":{}", key),
                n
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

/// Validates an option that takes one of a fixed set of names (for enum-like
/// fields such as `list_style`). Accepts a String or a Symbol; nil means
/// "keep the default". Returns the matched name, or Err if the value is of
/// another type or is not one of `allowed`.
fn validate_enum(
    ruby: &Ruby,
    value: Value,
    key: &str,
    category: &str,
    allowed: &[&str],
) -> Result<Option<String>, Error> {
    if value.is_nil() {
        return Ok(None);
    }
    let name: String = if let Some(symbol) = Symbol::from_value(value) {
        symbol.name()?.into_owned()
    } else {
        String::try_convert(value).map_err(|_| {
            Error::new(
                ruby.exception_type_error(),
                format!(
                    "{} option `{}` must be a String or Symbol; got {}",
                    category,
                    format_args!(":{}", key),
                    crate::utils::get_classname(value)
                ),
            )
        })?
    };
    if allowed.contains(&name.as_str()) {
        return Ok(Some(name));
    }
    Err(Error::new(
        ruby.exception_arg_error(),
        format!(
            "{} option `{}` must be one of {}; got {:?}",
            category,
            format_args!(":{}", key),
            allowed
                .iter()
                .map(|a| format!(":{a}"))
                .collect::<Vec<_>>()
                .join(", "),
            name
        ),
    ))
}

/// The options Commonmarker accepts: comrak's own, plus `max_nesting_depth`,
/// which Commonmarker enforces itself (see `crate::nesting`).
pub struct Options {
    pub comrak: comrak::Options<'static>,
    pub max_nesting_depth: usize,
}

impl Options {
    /// Commonmarker's defaults (different from comrak's).
    fn defaults() -> Self {
        Options {
            comrak: DEFAULT_OPTIONS.clone(),
            max_nesting_depth: DEFAULT_MAX_NESTING_DEPTH,
        }
    }
}

/// Formats and validates options from Ruby, merging with defaults.
/// Accepts Option<Value> and returns Options.
///
/// Logic:
/// - If no options: use DEFAULT_OPTIONS (commonmarker defaults)
/// - If options provided but category absent: use DEFAULT_OPTIONS for that category
/// - If category provided: start with commonmarker defaults, apply non-nil values from user
///   (nil values mean "keep default for this field")
pub fn format_options(ruby: &Ruby, rb_options: Option<Value>) -> Result<Options, Error> {
    let rb_options = match rb_options {
        None => return Ok(Options::defaults()),
        Some(v) if v.is_nil() => return Ok(Options::defaults()),
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
        return Ok(Options::defaults());
    }

    // Start with commonmarker defaults
    let mut options = Options::defaults();

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
            iterate_parse_options_with_validation(
                ruby,
                &mut options.comrak.parse,
                &mut options.max_nesting_depth,
                parse_hash,
            )?;
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
            iterate_render_options_with_validation(ruby, &mut options.comrak.render, render_hash)?;
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
                &mut options.comrak.extension,
                extension_hash,
            )?;
        }
    }

    Ok(options)
}

fn iterate_parse_options_with_validation(
    ruby: &Ruby,
    comrak_options: &mut comrak::options::Parse,
    max_nesting_depth: &mut usize,
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
                PARSE_IGNORE_SETEXT => {
                    match validate_bool(
                        ruby,
                        value,
                        PARSE_IGNORE_SETEXT,
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
                PARSE_SOURCEPOS_CHARS => {
                    match validate_bool(
                        ruby,
                        value,
                        PARSE_SOURCEPOS_CHARS,
                        "parse",
                        defaults.sourcepos_chars,
                    ) {
                        Ok(v) => comrak_options.sourcepos_chars = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                PARSE_MAX_NESTING_DEPTH => {
                    match validate_usize(
                        ruby,
                        value,
                        PARSE_MAX_NESTING_DEPTH,
                        "parse",
                        DEFAULT_MAX_NESTING_DEPTH,
                    ) {
                        Ok(v) => *max_nesting_depth = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                PARSE_TASKLIST_IN_TABLE => {
                    match validate_bool(
                        ruby,
                        value,
                        PARSE_TASKLIST_IN_TABLE,
                        "parse",
                        defaults.tasklist_in_table,
                    ) {
                        Ok(v) => comrak_options.tasklist_in_table = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                PARSE_ESCAPED_CHAR_SPANS => {
                    match validate_bool(
                        ruby,
                        value,
                        PARSE_ESCAPED_CHAR_SPANS,
                        "parse",
                        defaults.escaped_char_spans,
                    ) {
                        Ok(v) => comrak_options.escaped_char_spans = v,
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
                RENDER_COMPACT_HTML => {
                    match validate_bool(
                        ruby,
                        value,
                        RENDER_COMPACT_HTML,
                        "render",
                        defaults.compact_html,
                    ) {
                        Ok(v) => comrak_options.compact_html = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                RENDER_ALERT_STYLE => {
                    match validate_enum(ruby, value, RENDER_ALERT_STYLE, "render", ALERT_STYLES) {
                        Ok(v) => {
                            comrak_options.alert_style = match v.as_deref() {
                                Some("semantic") => comrak::options::AlertStyleType::Semantic,
                                Some(_) => comrak::options::AlertStyleType::Specific,
                                None => defaults.alert_style,
                            }
                        }
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                RENDER_LIST_STYLE => {
                    match validate_enum(ruby, value, RENDER_LIST_STYLE, "render", LIST_STYLES) {
                        Ok(v) => {
                            comrak_options.list_style = match v.as_deref() {
                                Some("plus") => comrak::options::ListStyleType::Plus,
                                Some("star") => comrak::options::ListStyleType::Star,
                                Some(_) => comrak::options::ListStyleType::Dash,
                                None => defaults.list_style,
                            }
                        }
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                RENDER_FIGURE_WITH_CAPTION => {
                    match validate_bool(
                        ruby,
                        value,
                        RENDER_FIGURE_WITH_CAPTION,
                        "render",
                        defaults.figure_with_caption,
                    ) {
                        Ok(v) => comrak_options.figure_with_caption = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                RENDER_OL_WIDTH => {
                    match validate_usize(ruby, value, RENDER_OL_WIDTH, "render", defaults.ol_width)
                    {
                        Ok(v) => comrak_options.ol_width = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                RENDER_EXPERIMENTAL_MINIMIZE_COMMONMARK => {
                    match validate_bool(
                        ruby,
                        value,
                        RENDER_EXPERIMENTAL_MINIMIZE_COMMONMARK,
                        "render",
                        defaults.experimental_minimize_commonmark,
                    ) {
                        Ok(v) => comrak_options.experimental_minimize_commonmark = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                RENDER_ATTRIBUTES => {
                    match validate_bool(
                        ruby,
                        value,
                        RENDER_ATTRIBUTES,
                        "render",
                        defaults.attributes,
                    ) {
                        Ok(v) => comrak_options.attributes = v,
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
                        Ok(v) => comrak_options.header_id_prefix = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_HEADER_ID_PREFIX_IN_HREF => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_HEADER_ID_PREFIX_IN_HREF,
                        "extension",
                        defaults.header_id_prefix_in_href,
                    ) {
                        Ok(v) => comrak_options.header_id_prefix_in_href = v,
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
                EXTENSION_MATH_LATEX => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_MATH_LATEX,
                        "extension",
                        defaults.math_latex,
                    ) {
                        Ok(v) => comrak_options.math_latex = v,
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
                EXTENSION_INSERT => {
                    match validate_bool(ruby, value, EXTENSION_INSERT, "extension", defaults.insert)
                    {
                        Ok(v) => comrak_options.insert = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_BLOCK_DIRECTIVE => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_BLOCK_DIRECTIVE,
                        "extension",
                        defaults.block_directive,
                    ) {
                        Ok(v) => comrak_options.block_directive = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_MATH_DOLLARS_BLOCK => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_MATH_DOLLARS_BLOCK,
                        "extension",
                        defaults.math_dollars_block,
                    ) {
                        Ok(v) => comrak_options.math_dollars_block = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_WIKILINKS_IGNORE_EMBEDS => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_WIKILINKS_IGNORE_EMBEDS,
                        "extension",
                        defaults.wikilinks_ignore_embeds,
                    ) {
                        Ok(v) => comrak_options.wikilinks_ignore_embeds = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_OFM_CALLOUTS => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_OFM_CALLOUTS,
                        "extension",
                        defaults.ofm_callouts,
                    ) {
                        Ok(v) => comrak_options.ofm_callouts = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_OFM_COMMENTS => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_OFM_COMMENTS,
                        "extension",
                        defaults.ofm_comments,
                    ) {
                        Ok(v) => comrak_options.ofm_comments = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_OFM_BLOCK_IDS => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_OFM_BLOCK_IDS,
                        "extension",
                        defaults.ofm_block_ids,
                    ) {
                        Ok(v) => comrak_options.ofm_block_ids = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_HEADER_ATTRIBUTES => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_HEADER_ATTRIBUTES,
                        "extension",
                        defaults.header_attributes,
                    ) {
                        Ok(v) => comrak_options.header_attributes = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_FENCED_CODE_ATTRIBUTES => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_FENCED_CODE_ATTRIBUTES,
                        "extension",
                        defaults.fenced_code_attributes,
                    ) {
                        Ok(v) => comrak_options.fenced_code_attributes = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_INLINE_CODE_ATTRIBUTES => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_INLINE_CODE_ATTRIBUTES,
                        "extension",
                        defaults.inline_code_attributes,
                    ) {
                        Ok(v) => comrak_options.inline_code_attributes = v,
                        Err(e) => {
                            error = Some(e);
                            return Ok(ForEach::Stop);
                        }
                    }
                }
                EXTENSION_LINK_ATTRIBUTES => {
                    match validate_bool(
                        ruby,
                        value,
                        EXTENSION_LINK_ATTRIBUTES,
                        "extension",
                        defaults.link_attributes,
                    ) {
                        Ok(v) => comrak_options.link_attributes = v,
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
    parse.aset(
        ruby.to_symbol(PARSE_IGNORE_SETEXT),
        DEFAULT_OPTIONS.parse.ignore_setext,
    )?;
    parse.aset(
        ruby.to_symbol(PARSE_SOURCEPOS_CHARS),
        DEFAULT_OPTIONS.parse.sourcepos_chars,
    )?;
    parse.aset(
        ruby.to_symbol(PARSE_MAX_NESTING_DEPTH),
        DEFAULT_MAX_NESTING_DEPTH,
    )?;
    parse.aset(
        ruby.to_symbol(PARSE_TASKLIST_IN_TABLE),
        DEFAULT_OPTIONS.parse.tasklist_in_table,
    )?;
    parse.aset(
        ruby.to_symbol(PARSE_ESCAPED_CHAR_SPANS),
        DEFAULT_OPTIONS.parse.escaped_char_spans,
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
    render.aset(
        ruby.to_symbol(RENDER_COMPACT_HTML),
        DEFAULT_OPTIONS.render.compact_html,
    )?;
    render.aset(
        ruby.to_symbol(RENDER_ALERT_STYLE),
        ruby.to_symbol(match DEFAULT_OPTIONS.render.alert_style {
            comrak::options::AlertStyleType::Semantic => "semantic",
            _ => "specific",
        }),
    )?;
    render.aset(
        ruby.to_symbol(RENDER_LIST_STYLE),
        ruby.to_symbol(match DEFAULT_OPTIONS.render.list_style {
            comrak::options::ListStyleType::Plus => "plus",
            comrak::options::ListStyleType::Star => "star",
            _ => "dash",
        }),
    )?;
    render.aset(
        ruby.to_symbol(RENDER_FIGURE_WITH_CAPTION),
        DEFAULT_OPTIONS.render.figure_with_caption,
    )?;
    render.aset(
        ruby.to_symbol(RENDER_OL_WIDTH),
        DEFAULT_OPTIONS.render.ol_width,
    )?;
    render.aset(
        ruby.to_symbol(RENDER_EXPERIMENTAL_MINIMIZE_COMMONMARK),
        DEFAULT_OPTIONS.render.experimental_minimize_commonmark,
    )?;
    render.aset(
        ruby.to_symbol(RENDER_ATTRIBUTES),
        DEFAULT_OPTIONS.render.attributes,
    )?;
    options.aset(ruby.to_symbol(RENDER), render)?;

    // Extension options
    let extension = ruby.hash_new();
    extension.aset(
        ruby.to_symbol(EXTENSION_STRIKETHROUGH),
        DEFAULT_OPTIONS.extension.strikethrough,
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
            .header_id_prefix
            .as_deref()
            .unwrap_or(""),
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_HEADER_ID_PREFIX_IN_HREF),
        DEFAULT_OPTIONS.extension.header_id_prefix_in_href,
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
        ruby.to_symbol(EXTENSION_MATH_LATEX),
        DEFAULT_OPTIONS.extension.math_latex,
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
    extension.aset(
        ruby.to_symbol(EXTENSION_INSERT),
        DEFAULT_OPTIONS.extension.insert,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_BLOCK_DIRECTIVE),
        DEFAULT_OPTIONS.extension.block_directive,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_MATH_DOLLARS_BLOCK),
        DEFAULT_OPTIONS.extension.math_dollars_block,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_WIKILINKS_IGNORE_EMBEDS),
        DEFAULT_OPTIONS.extension.wikilinks_ignore_embeds,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_OFM_CALLOUTS),
        DEFAULT_OPTIONS.extension.ofm_callouts,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_OFM_COMMENTS),
        DEFAULT_OPTIONS.extension.ofm_comments,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_OFM_BLOCK_IDS),
        DEFAULT_OPTIONS.extension.ofm_block_ids,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_HEADER_ATTRIBUTES),
        DEFAULT_OPTIONS.extension.header_attributes,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_FENCED_CODE_ATTRIBUTES),
        DEFAULT_OPTIONS.extension.fenced_code_attributes,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_INLINE_CODE_ATTRIBUTES),
        DEFAULT_OPTIONS.extension.inline_code_attributes,
    )?;
    extension.aset(
        ruby.to_symbol(EXTENSION_LINK_ATTRIBUTES),
        DEFAULT_OPTIONS.extension.link_attributes,
    )?;
    options.aset(ruby.to_symbol(EXTENSION), extension)?;

    Ok(options)
}
