# frozen_string_literal: true

require "test_helper"

class FrontmatterTest < Minitest::Test
  def test_frontmatter_does_not_interfere_with_codeblock
    md = "\n```\n\nx\n\n```\n"
    expected = <<~HTML
      <pre><code>
      x

      </code></pre>
    HTML

    assert_equal(expected, Commonmarker.to_html(md, plugins: nil))
  end

  def test_frontmatter_custom_delimiter
    md = "---\nyaml: true\nage: 42\n---\nThis is some text"
    expected = <<~HTML
      <p>This is some text</p>
    HTML

    assert_equal(expected, Commonmarker.to_html(md, options: { extension: { front_matter_delimiter: "---" } }))
  end
end
