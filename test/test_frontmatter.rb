# frozen_string_literal: true

require "test_helper"

class TestFrontmatter < Minitest::Test
  def test_frontmatter_does_not_interfere_with_codeblock
    md = "\n```\n\nx\n\n```\n"
    expected = <<~HTML
      <pre><code>
      x

      </code></pre>
    HTML

    assert_equal(expected, Commonmarker.to_html(md))
  end
end
