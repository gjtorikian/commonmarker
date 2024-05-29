# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023, by Samuel Williams.

# require 'markly'
# require 'markly'

require "test_helper"

class NodeCreationTest < Minitest::Test
  def test_it_can_make_all_the_nodes
    node_types = [
      [:document],
      [:block_quote],
      [:footnote_definition, name: "footnote", total_references: 1],
      [:list, type: :bullet],
      [:list, type: :ordered, tight: true],
      [:description_list],
      [:description_item],
      [:description_term],
      [:description_details],
      [:code_block, fenced: true],
      [:html_block],
      [:paragraph],
      [:heading, level: 1],
      [:thematic_break],
      [:table, alignments: [:left, :right], num_columns: 2, num_rows: 2, num_nonempty_cells: 0],
      [:table_row, header: false],
      [:table_cell],
      [:text, content: "wow"],
      [:taskitem],
      [:softbreak],
      [:linebreak],
      [:html_inline],
      [:emph],
      [:strong],
      [:strikethrough],
      [:superscript],
      [:link, url: "www.yetto.app/billy.png"],
      [:image, url: "www.yetto.app/billy.png"],
      [:footnote_reference, name: "^1"],
      [:shortcode, code: "troll"],
      [:math, dollar_math: true, display_math: false, literal: "$a+b=2$"],
      [:multiline_block_quote, fence_length: 2, fence_offset: 0],
      [:escaped],
      [:wikilink, url: "www.yetto.app/billy.png"],
    ]
    node_types.each do |type, arguments|
      node = arguments.nil? ? Commonmarker::Node.new(type) : Commonmarker::Node.new(type, **arguments)

      assert_equal(type, node.type)
    end
  end

  def test_errors_reported
    node_types = [
      [:list, type: :bar],
      [:heading, level: "wow"],
    ]
    assert_raises(ArgumentError) do
      node_types.each do |type, arguments|
        node = arguments.empty? ? Commonmarker::Node.new(type) : Commonmarker::Node.new(type, **arguments)

        assert_equal(type, node.type)
      end
    end
  end
end
