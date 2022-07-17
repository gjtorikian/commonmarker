# frozen_string_literal: true

require "test_helper"

class TestLinebreaks < Minitest::Test
  def test_hardbreak_no_spaces
    doc = Commonmarker.to_html("foo\nbaz")
    assert_equal("<p>foo<br />\nbaz</p>\n", doc.to_html(:HARDBREAKS))
  end

  def test_hardbreak_with_spaces
    doc = Commonmarker.to_html("foo  \nbaz")
    assert_equal("<p>foo<br />\nbaz</p>\n", doc.to_html(:HARDBREAKS))
  end
end
