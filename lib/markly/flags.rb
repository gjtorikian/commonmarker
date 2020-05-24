# frozen_string_literal: true

module Markly
	DEFAULT = 0
	VALIDATE_UTF8 = 1 << 9
	SMART = 1 << 10
	LIBERAL_HTML_TAG = 1 << 12
	FOOTNOTES = 1 << 13
	STRIKETHROUGH_DOUBLE_TILDE = 1 << 14
	UNSAFE = 1 << 17
	
	PARSE_FLAGS = {
		validate_utf8: VALIDATE_UTF8,
		smart_quotes: SMART,
		liberal_html_tags: LIBERAL_HTML_TAG,
		footnotes: FOOTNOTES,
		strikethrough_double_tilde: STRIKETHROUGH_DOUBLE_TILDE,
		unsafe: UNSAFE,
	}
	
	SOURCE_POSITION = 1 << 1
	HARD_BREAKS = 1 << 2
	NO_BREAKS = 1 << 4
	GITHUB_PRE_LANG = 1 << 11
	TABLE_PREFER_STYLE_ATTRIBUTES = 1 << 15
	FULL_INFO_STRING = 1 << 16
	
	RENDER_FLAGS = {
		source_position: SOURCE_POSITION,
		hard_breaks: HARD_BREAKS,
		no_breaks: NO_BREAKS,
		pre_lang: GITHUB_PRE_LANG,
		table_prefer_style_attributes: TABLE_PREFER_STYLE_ATTRIBUTES,
		full_info_string: FULL_INFO_STRING,
		unsafe: UNSAFE,
	}
end
