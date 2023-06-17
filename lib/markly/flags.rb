# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.

module Markly
	# The default parsing system.
	DEFAULT = 0
	# Replace illegal sequences with the replacement character `U+FFFD`.
	VALIDATE_UTF8 = 1 << 9
	# Use smart punctuation (curly quotes, etc.).
	SMART = 1 << 10
	# Support liberal parsing of inline HTML tags.
	LIBERAL_HTML_TAG = 1 << 12
	# Parse footnotes.
	FOOTNOTES = 1 << 13
	# Support strikethrough using double tildes.
	STRIKETHROUGH_DOUBLE_TILDE = 1 << 14
	# Allow raw/custom HTML and unsafe links.
	UNSAFE = 1 << 17
	
	PARSE_FLAGS = {
		validate_utf8: VALIDATE_UTF8,
		smart_quotes: SMART,
		liberal_html_tags: LIBERAL_HTML_TAG,
		footnotes: FOOTNOTES,
		strikethrough_double_tilde: STRIKETHROUGH_DOUBLE_TILDE,
		unsafe: UNSAFE,
	}
	
	# Include source position in rendered HTML.
	SOURCE_POSITION = 1 << 1
	# Treat `\n` as hardbreaks (by adding `<br/>`).
	HARD_BREAKS = 1 << 2
	# Translate `\n` in the source to a single whitespace.
	NO_BREAKS = 1 << 4
	# Use GitHub-style `<pre lang>` for fenced code blocks.
	GITHUB_PRE_LANG = 1 << 11
	# Use `style` insted of `align` for table cells.
	TABLE_PREFER_STYLE_ATTRIBUTES = 1 << 15
	# Include full info strings of code blocks in separate attribute.
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
