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
      <h1 data-sourcepos="1:1-1:9"><a href="#heading" aria-hidden="true" class="anchor" id="heading"></a>heading</h1>
      <p data-sourcepos="2:1-2:9">paragraph</p>
      <ul data-sourcepos="4:1-4:7">
      <li data-sourcepos="4:1-4:7">list1</li>
      </ul>
    HTML

    assert_equal(expected, Commonmarker.to_html(md, options: { render: { sourcepos: true } }))
  end
end
