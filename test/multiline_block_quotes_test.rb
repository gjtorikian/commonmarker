# frozen_string_literal: true

require "test_helper"

class MultilineBlockQuotesTest < Minitest::Test
  def test_to_html
    md = <<~MARKDOWN
      >>>
      Paragraph 1

      Paragraph 2
      >>>
    MARKDOWN
    expected = <<~HTML
      <blockquote>
      <p>Paragraph 1</p>
      <p>Paragraph 2</p>
      </blockquote>
    HTML

    assert_equal(expected, Commonmarker.to_html(md, options: { extension: { multiline_block_quotes: true } }))
  end
end
