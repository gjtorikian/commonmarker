# frozen_string_literal: true

require 'markly'

describe Markly::Node do
	let(:document) {Markly.parse("Hello[^hi].\n\n[^hi]: Hey!\n", flags: Markly::FOOTNOTES)}
	let(:expected_html) do
		<<~HTML
			<p>Hello<sup class="footnote-ref"><a href="#fn-hi" id="fnref-hi" data-footnote-ref>1</a></sup>.</p>
			<section class="footnotes" data-footnotes>
			<ol>
			<li id="fn-hi">
			<p>Hey! <a href="#fnref-hi" class="footnote-backref" data-footnote-backref data-footnote-backref-idx="1" aria-label="Back to reference 1">↩</a></p>
			</li>
			</ol>
			</section>
		HTML
	end
	
	with "Markly::FOOTNOTES" do
		it "can render HTML" do
			expect(document.to_html).to be == expected_html
		end
		
		it "can render HTML with a renderer" do
			renderer = Markly::Renderer::HTML.new
			expect(renderer.render(document)).to be == expected_html
		end
	end
end
