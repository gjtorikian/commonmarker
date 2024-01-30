# frozen_string_literal: true

require "test_helper"

class LinebreaksTest < Minitest::Test
  def setup
    @options = { parse: { hardbreaks: true } }
  end

  def test_hardbreak_no_spaces
    html = Commonmarker.to_html("foo\nbaz", options: @options)

    assert_equal("<p>foo<br />\nbaz</p>\n", html)
  end

  def test_hardbreak_with_spaces
    html = Commonmarker.to_html("foo  \nbaz", options: @options)

    assert_equal("<p>foo<br />\nbaz</p>\n", html)
  end
end
