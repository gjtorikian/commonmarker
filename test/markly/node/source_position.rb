# frozen_string_literal: true

require 'markly'

MARKDOWN = <<~MARKDOWN
## Try CommonMark

You can try CommonMark here.  This dingus is powered by
[commonmark.js](https://github.com/jgm/commonmark.js), the
JavaScript reference implementation.

1. item one
2. item two
   - sublist
   - sublist
MARKDOWN

describe Markly::Node do
	let(:document) {Markly.parse(MARKDOWN)}
	
	with "#source_position" do
		it "can generate source positions" do
			source_positions = []
			
			document.walk do |node|
				source_positions << node.source_position
			end
			
			source_positions.delete_if{|h| h.values.all?(&:zero?)}
			
			expect(source_positions).to be == [
				{:start_line=>1, :start_column=>1, :end_line=>10, :end_column=>12},
				{:start_line=>1, :start_column=>1, :end_line=>1, :end_column=>17},
				{:start_line=>1, :start_column=>4, :end_line=>1, :end_column=>17},
				{:start_line=>3, :start_column=>1, :end_line=>5, :end_column=>36},
				{:start_line=>3, :start_column=>1, :end_line=>3, :end_column=>55},
				{:start_line=>4, :start_column=>1, :end_line=>4, :end_column=>53},
				{:start_line=>4, :start_column=>2, :end_line=>4, :end_column=>14},
				{:start_line=>4, :start_column=>54, :end_line=>4, :end_column=>58},
				{:start_line=>5, :start_column=>1, :end_line=>5, :end_column=>36},
				{:start_line=>7, :start_column=>1, :end_line=>10, :end_column=>12},
				{:start_line=>7, :start_column=>1, :end_line=>7, :end_column=>11},
				{:start_line=>7, :start_column=>4, :end_line=>7, :end_column=>11},
				{:start_line=>7, :start_column=>4, :end_line=>7, :end_column=>11},
				{:start_line=>8, :start_column=>1, :end_line=>10, :end_column=>12},
				{:start_line=>8, :start_column=>4, :end_line=>8, :end_column=>11},
				{:start_line=>8, :start_column=>4, :end_line=>8, :end_column=>11},
				{:start_line=>9, :start_column=>4, :end_line=>10, :end_column=>12},
				{:start_line=>9, :start_column=>4, :end_line=>9, :end_column=>12},
				{:start_line=>9, :start_column=>6, :end_line=>9, :end_column=>12},
				{:start_line=>9, :start_column=>6, :end_line=>9, :end_column=>12},
				{:start_line=>10, :start_column=>4, :end_line=>10, :end_column=>12},
				{:start_line=>10, :start_column=>6, :end_line=>10, :end_column=>12},
				{:start_line=>10, :start_column=>6, :end_line=>10, :end_column=>12}
			]
		end
	end
end
