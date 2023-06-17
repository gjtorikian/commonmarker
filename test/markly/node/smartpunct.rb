# frozen_string_literal: true

require 'markly'
require 'markdown_spec'

describe Markly do
	with "Markly::SMART" do
		# I don't really know what this is testing?
		it "doesn't doesn't insert spaces for smart punctuation" do
			markdown = "\"foo\"\nbaz"
			result = "<p>“foo”<br />\nbaz</p>\n"
			doc = Markly.parse(markdown, flags: Markly::SMART)
			expect(result).to be == doc.to_html(flags: Markly::HARD_BREAKS)
		end
	end
end
