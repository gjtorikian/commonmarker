# frozen_string_literal: true

require "test_helper"

class RenderingTest < Minitest::Test
  def test_compact_html
    markdown = "# Hello\n\nWorld\n"

    default_output = Commonmarker.to_html(markdown)
    compact_output = Commonmarker.to_html(markdown, options: { render: { compact_html: true } })

    assert_operator(compact_output.count("\n"), :<, default_output.count("\n"))
  end
end
