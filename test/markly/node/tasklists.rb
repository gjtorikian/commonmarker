# frozen_string_literal: true

require 'markly'

TEXT = <<-MD
- [x] Add task list
- [ ] Define task list
MD

EXPECTED_HTML = <<-HTML
<ul>
<li><input type="checkbox" checked="" disabled="" /> Add task list</li>
<li><input type="checkbox" disabled="" /> Define task list</li>
</ul>
HTML

describe Markly do
	with "#tasklist" do
		let(:document) {Markly.parse(TEXT, extensions: [:tasklist])}
		
		it "can generate html" do
			expect(document.to_html).to be == EXPECTED_HTML
		end
		
		it "can generate html with renderer" do
			expect(Markly::Renderer::HTML.new.render(document)).to be == EXPECTED_HTML
		end
		
		it "can get tasklist state" do
			list = document.first_child
			expect(list.first_child.tasklist_item_checked?).to be == true
			expect(list.first_child.next.tasklist_item_checked?).to be == false
		end
		
		it "can set tasklist state" do
			list = document.first_child
			list.first_child.tasklist_item_checked = false
			expect(list.first_child.tasklist_item_checked?).to be == false
			list.first_child.next.tasklist_item_checked = true
			expect(list.first_child.next.tasklist_item_checked?).to be == true
		end
	end
end
