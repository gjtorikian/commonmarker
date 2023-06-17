# frozen_string_literal: true

require 'markly'

describe Markly::Node do
	let(:document) {Markly.parse("Hi *there*. This has __many nodes__!")}
	
	with '#type' do
		it "has the document type" do
			expect(document.type).to be == :document
		end
		
		it "has the document type string" do
			expect(document.type_string).to be == "document"
		end
	end
	
	with '#first_child' do
		it "has a first child" do
			expect(document.first_child.type).to be == :paragraph
		end
		
		it "has a next sibling" do
			expect(document.first_child.first_child.next.type).to be == :emph
		end
	end
	
	with "#insert_before" do
		it "can insert a node before another node" do
			paragraph = Markly::Node.new(:paragraph)
			expect(document.first_child.insert_before(paragraph)).to be == true
			expect(document.to_html).to be =~ /<p><\/p>\n<p>Hi <em>there<\/em>/
		end
	end
	
	with "#insert_after" do
		it "can insert a node after another node" do
			paragraph = Markly::Node.new(:paragraph)
			expect(document.first_child.insert_after(paragraph)).to be == true
			expect(document.to_html).to be =~ /<strong>many nodes<\/strong>!<\/p>\n<p><\/p>\n/
		end
	end
	
	with "#prepend_child" do
		it "can prepend a child node" do
			code = Markly::Node.new(:code)
			expect(document.first_child.prepend_child(code)).to be == true
			expect(document.to_html).to be =~ /<p><code><\/code>Hi <em>there<\/em>/
		end
	end
	
	with "#append_child" do
		it "can append a child node" do
			strong = Markly::Node.new(:strong)
			expect(document.first_child.append_child(strong)).to be == true
			expect(document.to_html).to be =~ /!<strong><\/strong><\/p>\n/
		end
	end
	
	with "#last_child" do
		it "has a last child" do
			expect(document.last_child.type).to be == :paragraph
		end
	end

	with "#parent" do
		it "has a parent" do
			expect(document.first_child.parent.type).to be == :document
			expect(document.first_child.parent).to be == document
		end
	end
	
	with '#next' do
		it "has a next sibling" do
			expect(document.first_child.first_child.next.type).to be == :emph
			expect(document.first_child.first_child.next).to be == document.first_child.first_child.next
		end
	end
	
	with "#previous" do
		it "has a previous sibling" do
			expect(document.first_child.first_child.next.previous.type).to be == :text
			expect(document.first_child.first_child.next.previous).to be == document.first_child.first_child
		end
	end
	
	with '#url' do
		let(:document) {Markly.parse("[GitHub](https://www.github.com)")}
		let(:url_node) {document.first_child.first_child}
		
		it "has a url" do
			expect(url_node.url).to be == "https://www.github.com"
		end
		
		it "can set a url" do
			url_node.url = "https://www.google.com"
			expect(url_node.url).to be == "https://www.google.com"
			expect(document.to_html).to be =~ /<a href="https:\/\/www.google.com">GitHub<\/a>/
		end
	end
	
	with '#title' do
		let(:document) {Markly.parse('![alt text](https://github.com/favicon.ico "Favicon")')}
		let(:title_node) {document.first_child.first_child}
		
		it "has a title" do
			expect(title_node.title).to be == "Favicon"
		end
		
		it "can set a title" do
			title_node.title = "Google"
			expect(title_node.title).to be == "Google"
			expect(document.to_html).to be =~ /<img src="https:\/\/github.com\/favicon.ico" alt="alt text" title="Google" \/>/
		end
	end
	
	with '#header_level' do
		let(:document) {Markly.parse('### Header Three')}
		let(:header_node) {document.first_child}
		
		it "has a header level" do
			expect(header_node.header_level).to be == 3
		end
		
		it "can set a header level" do
			header_node.header_level = 6
			expect(header_node.header_level).to be == 6
			expect(document.to_html).to be =~ /<h6>Header Three<\/h6>/
		end
	end
	
	with '#list_type' do
		let(:document) {Markly.parse("* Bullet\n* Bullet")}
		let(:list_node) {document.first_child}
		
		it "has a list type" do
			expect(list_node.list_type).to be == :bullet_list
		end
		
		it "can set a list type" do
			list_node.list_type = :ordered_list
			expect(list_node.list_type).to be == :ordered_list
			expect(document.to_html).to be =~ /<ol start="0">\n<li>Bullet<\/li>\n<li>Bullet<\/li>\n<\/ol>/
		end
	end
	
	with '#list_start' do
		let(:document) {Markly.parse("1. One\n2. Two")}
		let(:list_node) {document.first_child}
		
		it "has a list start" do
			expect(list_node.list_start).to be == 1
		end
		
		it "can set a list start" do
			list_node.list_start = 3
			expect(list_node.list_start).to be == 3
			expect(document.to_html).to be =~ /<ol start="3">\n<li>One<\/li>\n<li>Two<\/li>\n<\/ol>/
		end
	end
	
	with '#list_tight' do
		let(:ul_list) {Markly.parse("* Bullet\n* Bullet").first_child}
		let(:ol_list) {Markly.parse("1. One\n2. Two").first_child}
		
		it "has a list tight" do
			expect(ul_list.list_tight).to be == true
			expect(ol_list.list_tight).to be == true
		end
		
		it "can set a list tight" do
			ul_list.list_tight = false
			ol_list.list_tight = false
			expect(ul_list.list_tight).to be == false
			expect(ol_list.list_tight).to be == false
			expect(ul_list.to_html).to be == "<ul>\n<li>\n<p>Bullet</p>\n</li>\n<li>\n<p>Bullet</p>\n</li>\n</ul>\n"
			expect(ol_list.to_html).to be == "<ol>\n<li>\n<p>One</p>\n</li>\n<li>\n<p>Two</p>\n</li>\n</ol>\n"
		end
	end
	
	with '#fence_info' do
		let(:document) {Markly.parse("``` ruby\nputs 'wow'\n```")}
		let(:fence_node) {document.first_child}
		
		it "has a fence info" do
			expect(fence_node.fence_info).to be == "ruby"
		end
		
		it "can set a fence info" do
			fence_node.fence_info = "perl"
			expect(fence_node.fence_info).to be == "perl"
			expect(document.to_html).to be =~ /<pre><code class="language-perl">puts 'wow'\n<\/code><\/pre>/
		end
	end
	
	with '#find_header' do
		let(:document) {Markly.parse("# Heading\n\n## Subheading")}
		
		it "can find a heading" do
			expect(document.find_header("Heading")).to be == document.first_child
			expect(document.find_header("Subheading")).to be == document.first_child.next
		end
	end
	
	with '#replace_section' do
		let(:document) {Markly.parse("# Heading\n\n## Subheading")}
		let(:new_document) {Markly.parse("### New Heading")}
		
		it "can replace a section" do
			document.find_header("Heading").replace_section(new_document.first_child, remove_subsections: true)
			expect(document.to_html).to be == "<h3>New Heading</h3>\n"
		end
		
		it "can replace a section and subsections" do
			document.find_header("Heading").replace_section(new_document.first_child, remove_subsections: false)
			expect(document.to_html).to be == "<h3>New Heading</h3>\n"
		end
	end
end
