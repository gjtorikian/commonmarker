# frozen_string_literal: true

require 'markly'

describe Markly::Renderer::HTML do
	let(:markdown) {"# Introduction\nHi *there*"}
	let(:document) {Markly.parse(markdown)}
	let(:renderer) {subject.new}
	
	it "can render HTML" do
		expect(renderer.render(document)).to be == "<h1>Introduction</h1>\n<p>Hi <em>there</em></p>\n"
	end
	
	with "ids" do
		let(:renderer) {subject.new(ids: true)}
		
		it "can render HTML with ids" do
			expect(renderer.render(document)).to be == "<section id=\"introduction\"><h1>Introduction</h1>\n<p>Hi <em>there</em></p>\n</section>"
		end
	end
	
	with "multiple tables" do
		let(:markdown) do
			<<~MARKDOWN
				| Input       | Expected         | Actual    |
				| ----------- | ---------------- | --------- |
				| One         | Two              | Three     |
				
				| Header   | Row  | Example |
				| :------: | ---: | :------ |
				| Foo      | Bar  | Baz     |
			MARKDOWN
		end
		let(:document) {Markly.parse(markdown, extensions: %i[autolink table tagfilter])}
		
		it "can render multiple tables" do
			expect(renderer.render(document).scan(/<tbody>/).size).to be == 2
		end
	end
end
