# frozen_string_literal: true

require 'markly'

describe Markly do
	let(:document) {Markly.parse(markdown, flags: Markly::SMART)}
	let(:html) {document.to_html}
	
	with "UTF-8 encoded markdown with smart quotes" do
		let(:markdown) {"This curly quote “makes markly throw an exception”."}
		
		it "has the correct text" do
			# see http://git.io/vq4FR
			expect(html).to be == "<p>This curly quote “makes markly throw an exception”.</p>\n"
		end
	end
	
	with "UTF-8 encoded markdown with smart quotes and a link" do
		let(:markdown) {"Hi *there*"}
		let(:text_node) {document.first_child.last_child.first_child}
		
		it "should be encoded with UTF-8" do
			expect(text_node.string_content).to be == "there"
			expect(text_node.string_content.encoding).to be == Encoding::UTF_8
		end
	end
end
