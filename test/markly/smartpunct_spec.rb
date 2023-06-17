# frozen_string_literal: true

require 'markly'
require 'markdown_spec'

MarkdownSpec.open('smart_punct.txt').each do |testcase|
	describe testcase[:section], unique: testcase[:example] do
		let(:document) {Markly.parse(testcase[:markdown], flags: Markly::SMART)}
		
		it "can convert to valid html" do
			actual = document.to_html.strip
			expect(actual).to be == testcase[:html]
		end
		
		it "can convert to valid html using the html renderer" do
			actual = Markly::Renderer::HTML.new(flags: Markly::UNSAFE, extensions: testcase[:extensions]).render(document).rstrip
			expect(actual).to be == testcase[:html]
		end
		
		it "can convert to valid html with source positions" do
			lhs = document.to_html(flags: Markly::UNSAFE|Markly::SOURCE_POSITION, extensions: testcase[:extensions]).rstrip
			rhs = Markly::Renderer::HTML.new(flags: Markly::UNSAFE|Markly::SOURCE_POSITION, extensions: testcase[:extensions]).render(document).rstrip
			expect(lhs).to be == rhs
		end
	end
end
