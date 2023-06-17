# frozen_string_literal: true

require 'markly'

MARKDOWN = <<-MARKDOWN
One extension:

| a   | b   |
| --- | --- |
| c   | d   |
| **x** | |

Another extension:

~~hi~~
MARKDOWN

describe Markly do
	let(:markdown) {MARKDOWN}
	let(:extensions) {[]}
	let(:document) {Markly.parse(markdown, extensions: extensions)}
	let(:html) {document.to_html}
	
	let(:renderer) {Markly::Renderer::HTML.new}
	
	with "invalid string extensions" do
		let(:extensions) {['table']}
		
		it "raises an error" do
			expect{html}.to raise_exception(TypeError)
		end	
	end
	
	with "non-existant extension" do
		let(:extensions) {[:non_existant]}
		
		it "raises an error" do
			expect{html}.to raise_exception(ArgumentError)
		end
	end
	
	with "no extensions" do
		it "doesn't render tables" do
			expect(html).to be == <<~HTML
				<p>One extension:</p>
				<p>| a   | b   |
				| --- | --- |
				| c   | d   |
				| <strong>x</strong> | |</p>
				<p>Another extension:</p>
				<p>~~hi~~</p>
			HTML
		end
	end
	
	with "table extension" do
		let(:extensions) {[:table]}
		let(:expected_html) do
			<<~HTML
				<p>One extension:</p>
				<table>
				<thead>
				<tr>
				<th>a</th>
				<th>b</th>
				</tr>
				</thead>
				<tbody>
				<tr>
				<td>c</td>
				<td>d</td>
				</tr>
				<tr>
				<td><strong>x</strong></td>
				<td></td>
				</tr>
				</tbody>
				</table>
				<p>Another extension:</p>
				<p>~~hi~~</p>
			HTML
		end
		
		it "renders tables" do
			expect(html).to be == expected_html
		end
		
		it "renders table with renderer" do
			expect(renderer.render(document)).to be == expected_html
		end	
	end
	
	with "strikethrough extension" do
		let(:extensions) {[:strikethrough]}
		let(:expected_html) do
			<<~HTML
				<p>One extension:</p>
				<p>| a   | b   |
				| --- | --- |
				| c   | d   |
				| <strong>x</strong> | |</p>
				<p>Another extension:</p>
				<p><del>hi</del></p>
			HTML
		end
		
		it "renders strikethrough" do
			expect(html).to be == expected_html
		end
		
		it "renders strikethrough with renderer" do
			expect(renderer.render(document)).to be == expected_html
		end
	end
	
	with "double tilde strikethrough extension" do
		let(:markdown) {'~a~ ~~b~~ ~~~c~~~'}
		let(:extensions) {[:strikethrough]}
		let(:document) {Markly.parse(markdown, flags: Markly::STRIKETHROUGH_DOUBLE_TILDE, extensions: extensions)}
		
		it "renders double tilde strikethrough" do
			expect(html).to be == <<~HTML
				<p>~a~ <del>b</del> ~~~c~~~</p>
			HTML
		end
	end
	
	with "table and strikethrough extensions" do
		let(:extensions) {[:table, :strikethrough]}
		
		with "#to_plaintext" do
			let(:markdown) do
				<<~MARKDOWN
					Hello ~there~.
					
					| a |
					| --- |
					| b |
				MARKDOWN
			end
			
			it "renders plaintext" do
				expect(document.to_plaintext).to be == <<~PLAINTEXT
					Hello ~there~.
					
					| a |
					| --- |
					| b |
				PLAINTEXT
			end
		end
	end
end


#     Renderer::HTML.new.render(doc).tap do |out|
#       refute out.include?('| a')
#       %w[<table> <tr> <th> a </th> <td> c </td> <strong>x</strong>].each { |html| assert out.include?(html) }
#       assert out.include?('~~hi~~')
#     end

#     doc = Markly.parse('~a~ ~~b~~ ~~~c~~~', flags: Markly::STRIKETHROUGH_DOUBLE_TILDE, extensions: [:strikethrough])
#     assert_equal Renderer::HTML.new.render(doc), "<p>~a~ <del>b</del> ~~~c~~~</p>\n"
#   end

# 	end
# end


#   def test_comments_are_kept_as_expected
#     assert_equal "<!--hello--> <blah> &lt;xmp>\n", Markly.render_html("<!--hello--> <blah> <xmp>\n", flags: Markly::UNSAFE, extensions: %i[tagfilter])
#   end

#   def test_table_prefer_style_attributes
#     assert_equal(<<~HTML, Markly.render_html(<<~MD, flags: Markly::TABLE_PREFER_STYLE_ATTRIBUTES, extensions: %i[table]))
#       <table>
#       <thead>
#       <tr>
#       <th style="text-align: left">aaa</th>
#       <th>bbb</th>
#       <th style="text-align: center">ccc</th>
#       <th>ddd</th>
#       <th style="text-align: right">eee</th>
#       </tr>
#       </thead>
#       <tbody>
#       <tr>
#       <td style="text-align: left">fff</td>
#       <td>ggg</td>
#       <td style="text-align: center">hhh</td>
#       <td>iii</td>
#       <td style="text-align: right">jjj</td>
#       </tr>
#       </tbody>
#       </table>
#     HTML
#       aaa | bbb | ccc | ddd | eee
#       :-- | --- | :-: | --- | --:
#       fff | ggg | hhh | iii | jjj
#     MD
#   end

#
# end
