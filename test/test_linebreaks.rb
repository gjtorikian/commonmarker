require 'test_helper'

class TestLinebreaks < Minitest::Test
  def test_hardbreak_no_spaces
    doc = Node.parse_string("foo\nbaz")
    assert_equal "<p>foo\nbaz</p>\n", doc.to_html

    doc = Node.parse_string("foo\nbaz", :hardbreaks)
    assert_equal "<p>foo<br />\nbaz</p>\n", doc.to_html(:hardbreaks)
  end

  def test_hardbreak_with_spaces
    doc = Node.parse_string("foo  \nbaz")
    assert_equal "<p>foo<br />\nbaz</p>\n", doc.to_html

    doc = Node.parse_string("foo  \nbaz", :hardbreaks)
    assert_equal "<p>foo<br />\nbaz</p>\n", doc.to_html(:hardbreaks)
  end
end
