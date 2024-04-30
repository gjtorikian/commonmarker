# frozen_string_literal: true

require "test_helper"

class EscapeCharSpansTest < Minitest::Test
  def test_to_html
    md = <<~MARKDOWN
      Hello \\@user

      Hey, @user!
    MARKDOWN
    expected = <<~HTML
      <p>Hello <span data-escaped-char>@</span>user</p>
      <p>Hey, @user!</p>
    HTML

    assert_equal(expected, Commonmarker.to_html(md, options: { render: { escaped_char_spans: true } }))
  end
end
