require 'test_helper'

class SmartPunctLinebreaksTest < Minitest::Test
  def test_smart_hardbreak_no_spaces
    markdown = '"foo"\nbaz'
    
    assert_equal "<p>“foo”<br />\nbaz</p>\n", CommonMarker.render_html(markdown, [:smart, :hardbreaks])
  end

  def test_smart_hardbreak_no_spaces
    markdown = '"foo"\nbaz'

    doc = CommonMarker.render_doc(markdown, [:smart, :hardbreaks])

    assert_equal "<p>“foo”<br />\nbaz</p>\n", doc.to_html
  end

end
