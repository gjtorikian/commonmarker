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

#             ComrakNodeValue::List(..) => Symbol::new("list"),
#             ComrakNodeValue::DescriptionList => Symbol::new("description_list"),
#             ComrakNodeValue::DescriptionItem(_) => Symbol::new("description_item"),
#             ComrakNodeValue::DescriptionTerm => Symbol::new("description_term"),
#             ComrakNodeValue::DescriptionDetails => Symbol::new("description_details"),
#             ComrakNodeValue::Item(..) => Symbol::new("item"),
#             ComrakNodeValue::CodeBlock(..) => Symbol::new("code_block"),
#             ComrakNodeValue::HtmlBlock(..) => Symbol::new("html_block"),
#             ComrakNodeValue::Paragraph => Symbol::new("paragraph"),
#             ComrakNodeValue::Heading(..) => Symbol::new("heading"),
#             ComrakNodeValue::ThematicBreak => Symbol::new("thematic_break"),
#             ComrakNodeValue::Table(..) => Symbol::new("table"),
#             ComrakNodeValue::TableRow(..) => Symbol::new("table_row"),
#             ComrakNodeValue::TableCell => Symbol::new("table_cell"),
#             ComrakNodeValue::Text(..) => Symbol::new("text"),
#             ComrakNodeValue::SoftBreak => Symbol::new("softbreak"),
#             ComrakNodeValue::LineBreak => Symbol::new("linebreak"),
#             ComrakNodeValue::Image(..) => Symbol::new("image"),
#             ComrakNodeValue::Link(..) => Symbol::new("link"),
#             ComrakNodeValue::Emph => Symbol::new("emph"),
#             ComrakNodeValue::Strong => Symbol::new("strong"),
#             ComrakNodeValue::Code(..) => Symbol::new("code"),
#             ComrakNodeValue::HtmlInline(..) => Symbol::new("html_inline"),
#             ComrakNodeValue::Strikethrough => Symbol::new("strikethrough"),
#             ComrakNodeValue::FrontMatter(_) => Symbol::new("frontmatter"),
#             ComrakNodeValue::TaskItem { .. } => Symbol::new("taskitem"),
#             ComrakNodeValue::Superscript => Symbol::new("superscript"),
#             ComrakNodeValue::FootnoteReference(..) => Symbol::new("footnote_reference"),
#             ComrakNodeValue::ShortCode(_) => Symbol::new("shortcode"),
#             ComrakNodeValue::MultilineBlockQuote(_) => Symbol::new("multiline_block_quote"),
#             ComrakNodeValue::Escaped => Symbol::new("escaped"),
#             ComrakNodeValue::Math(..) => Symbol::new("math"),
