# frozen_string_literal: true

require 'markly'
require 'markly'

describe Markly::Node do
	let(:document) {Markly.parse('Hi *there*, I am mostly text!')}

	it "can walk all nodes" do
		nodes = []
		document.walk do |node|
			nodes << node.type
		end
		expect(nodes).to be == %i[document paragraph text emph text text]
	end

	it "can enumerate nodes" do
		nodes = []
		document.first_child.each do |node|
			nodes << node.type
		end
		expect(nodes).to be == %i[text emph text]
	end
	
	it "can select nodes" do
		nodes = document.first_child.select { |node| node.type == :text }
		expect(nodes.first).to be_a(Markly::Node)
		expect(nodes.map(&:type)).to be == %i[text text]
	end
	
	it "can map nodes" do
		nodes = document.first_child.map(&:type)
		expect(nodes).to be == %i[text emph text]
	end
	
	it "can't insert invalid node" do
		expect do
			document.insert_before(Markly::Node.new(:document))
		end.to raise_exception(Markly::Error)
	end
	
	it "can generate html" do
		expect(document.to_html).to be == "<p>Hi <em>there</em>, I am mostly text!</p>\n"
	end
	
	it "can generate html with the html renderer" do
		renderer = Markly::Renderer::HTML.new
		expect(renderer.render(document)).to be == "<p>Hi <em>there</em>, I am mostly text!</p>\n"
	end
	
	it "can walk and set string content" do
		document.walk do |node|
			node.string_content = 'world' if node.type == :text && node.string_content == 'there'
		end
		result = document.to_html
		expect(result).to be == "<p>Hi <em>world</em>, I am mostly text!</p>\n"
	end
	
	it "can walk and delete node" do
		document.walk do |node|
			if node.type == :emph
				node.insert_before(node.first_child)
				node.delete
			end
		end
		expect(document.to_html).to be == "<p>Hi there, I am mostly text!</p>\n"
	end
	
	with '#inspect' do
		it "can inspect a node" do
			expect(document.inspect).to be(:include?, "#<Markly::Node(document)")
		end
	end
end
