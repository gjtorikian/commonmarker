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
    md = "---\nyaml: true\nage: 42\n---\n# Title 1"
    expected = <<~HTML
      <h1>Title 1</h1>
    HTML

    assert_equal(expected, Commonmarker.to_html(md, options: { extension: { header_ids: nil, front_matter_delimiter: "---" } }))
  end
end
