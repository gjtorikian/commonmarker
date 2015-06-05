require 'test_helper'

class TestLinebreaks < Minitest::Test
  def test_softbreak_no_spaces_as_hard
    doc = Node.parse_string("foo\nbaz", :hardbreaks)
    assert_equal "<p>Hi <em>there</em></p>\n", doc.to_html
  end

  def test_softbreak_with_spaces_as_hard
    doc = Node.parse_string("foo \n baz", :hardbreaks)
    assert_equal "<p>Hi <em>there</em></p>\n", doc.to_html
  end
end
