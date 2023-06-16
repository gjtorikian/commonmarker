# frozen_string_literal: true

require 'test_helper'

class TestLinebreaks < Minitest::Test
  def test_hardbreak_no_spaces
    doc = Markly.parse("foo\nbaz")
    assert_equal "<p>foo<br />\nbaz</p>\n", doc.to_html(flags: Markly::HARD_BREAKS)
  end

  def test_hardbreak_with_spaces
    doc = Markly.parse("foo  \nbaz")
    assert_equal "<p>foo<br />\nbaz</p>\n", doc.to_html(flags: Markly::HARD_BREAKS)
  end
end
