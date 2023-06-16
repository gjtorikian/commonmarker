# frozen_string_literal: true

require 'markly'

describe Markly::Node do
	let(:document) {Markly.parse("Hi *there*")}
	
	with '#to_html' do
		it "can convert to HTML" do
			expect(document.to_html).to be == "<p>Hi <em>there</em></p>\n"
		end
	end
	
	with '#render_html' do
		it "can convert to HTML" do
			expect(Markly.render_html("Hi *there*")).to be == "<p>Hi <em>there</em></p>\n"
		end
	end
end
