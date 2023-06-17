# frozen_string_literal: true

require 'markly'

describe Markly do
	with "Markly::FULL_INFO_STRING" do
		with "no extra metadata" do
			def input 
				<<~MD
					```ruby
					module Foo
					```
				MD
			end
			
			it "generates code without data-meta attribute"  do
				html = Markly.render_html(input, flags: Markly::FULL_INFO_STRING)
				expect(html).to be(:include?, '<pre><code class="language-ruby">')
			end
		end
		
		with "extra metadata" do
			def input
				<<~MD
					```ruby my info string
					module Foo
					```
				MD
			end
			
			it "generates code with data-meta attribute" do
				html = Markly.render_html(input, flags: Markly::FULL_INFO_STRING)
				expect(html).to be(:include?, '<pre><code class="language-ruby" data-meta="my info string">')
			end
		end
		
		with "extra metadata with null byte" do
			def input
				<<~MD
					```ruby my \x00 string
					module Foo
					```
				MD
			end
			
			it "generates code with data-meta attribute" do
				html = Markly.render_html(input, flags: Markly::FULL_INFO_STRING)
				expect(html).to be(:include?, %(<pre><code class="language-ruby" data-meta="my � string">))
			end
		end
	end
end
