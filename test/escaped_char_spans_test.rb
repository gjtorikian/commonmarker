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

  def test_parse_option_keeps_escaped_nodes_in_the_ast
    md = "Hello \\@user"

    options = { parse: { escaped_char_spans: true }, render: { escaped_char_spans: false } }

    assert_includes(Commonmarker.parse(md, options: options).walk.map(&:type), :escaped)

    options = { parse: { escaped_char_spans: false }, render: { escaped_char_spans: false } }

    refute_includes(Commonmarker.parse(md, options: options).walk.map(&:type), :escaped)
  end
end
