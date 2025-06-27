# frozen_string_literal: true

require "test_helper"

class SourceposTest < Minitest::Test
  def test_to_html
    md = <<~MARKDOWN
      # heading
      paragraph

      - list1
    MARKDOWN
    expected = <<~HTML
      <h1 data-sourcepos="1:1-1:9"><a inert href="#heading" aria-hidden="true" class="anchor" id="heading"></a>heading</h1>
      <p data-sourcepos="2:1-2:9">paragraph</p>
      <ul data-sourcepos="4:1-4:7">
      <li data-sourcepos="4:1-4:7">list1</li>
      </ul>
    HTML

    assert_equal(expected, Commonmarker.to_html(md, options: { render: { sourcepos: true } }))
  end

  def test_can_generate_source_positions
    md = <<~MARKDOWN
      ## Try CommonMark

      You can try CommonMark here.  This dingus is powered by
      [commonmark.js](https://github.com/jgm/commonmark.js), the
      JavaScript reference implementation.

      1. item one
      2. item two
         - sublist
         - sublist
    MARKDOWN
    doc = Commonmarker.parse(md)

    source_positions = []

    doc.walk do |node|
      source_positions << node.source_position
    end

    source_positions.delete_if { |h| h.values.all?(&:zero?) }

    assert_equal(
      [
        { start_line: 1, start_column: 1, end_line: 10, end_column: 12 },
        { start_line: 1, start_column: 1, end_line: 1, end_column: 17 },
        { start_line: 1, start_column: 4, end_line: 1, end_column: 17 },
        { start_line: 3, start_column: 1, end_line: 5, end_column: 36 },
        { start_line: 3, start_column: 1, end_line: 3, end_column: 55 },
        { start_line: 3, start_column: 56, end_line: 3, end_column: 56 },
        { start_line: 4, start_column: 1, end_line: 4, end_column: 53 },
        { start_line: 4, start_column: 2, end_line: 4, end_column: 14 },
        { start_line: 4, start_column: 54, end_line: 4, end_column: 58 },
        { start_line: 4, start_column: 59, end_line: 4, end_column: 59 },
        { start_line: 5, start_column: 1, end_line: 5, end_column: 36 },
        { start_line: 7, start_column: 1, end_line: 10, end_column: 12 },
        { start_line: 7, start_column: 1, end_line: 7, end_column: 11 },
        { start_line: 7, start_column: 4, end_line: 7, end_column: 11 },
        { start_line: 7, start_column: 4, end_line: 7, end_column: 11 },
        { start_line: 8, start_column: 1, end_line: 10, end_column: 12 },
        { start_line: 8, start_column: 4, end_line: 8, end_column: 11 },
        { start_line: 8, start_column: 4, end_line: 8, end_column: 11 },
        { start_line: 9, start_column: 4, end_line: 10, end_column: 12 },
        { start_line: 9, start_column: 4, end_line: 9, end_column: 12 },
        { start_line: 9, start_column: 6, end_line: 9, end_column: 12 },
        { start_line: 9, start_column: 6, end_line: 9, end_column: 12 },
        { start_line: 10, start_column: 4, end_line: 10, end_column: 12 },
        { start_line: 10, start_column: 6, end_line: 10, end_column: 12 },
        { start_line: 10, start_column: 6, end_line: 10, end_column: 12 },
      ],
      source_positions,
    )
  end
end
