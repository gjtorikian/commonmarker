# frozen_string_literal: true

require "test_helper"

class MathTest < Minitest::Test
  def test_math_dollars_to_html
    md = <<~MARKDOWN
      $1 + 2$ and $$x = y$$
    MARKDOWN
    expected = <<~HTML
      <p><span data-math-style="inline">1 + 2</span> and <span data-math-style="display">x = y</span></p>
    HTML

    assert_equal(expected, Commonmarker.to_html(md, options: { extension: { math_dollars: true } }))
  end

  def test_math_code_to_html
    md = <<~MARKDOWN
      $`1 + 2`$
    MARKDOWN
    expected = <<~HTML
      <p><code data-math-style="inline">1 + 2</code></p>
    HTML

    assert_equal(expected, Commonmarker.to_html(md, options: { extension: { math_code: true } }))
  end
end
