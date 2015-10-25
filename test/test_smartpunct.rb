require 'test_helper'

class SmartPunctTest < Minitest::Test
  smart_punct = open_spec_file('smart_punct.txt', normalize: true)

  smart_punct.each do |testcase|
    doc = CommonMarker.render_doc(testcase[:markdown], [:smart])

    define_method("test_smart_punct_example_#{testcase[:example]}") do
      actual = doc.to_html.strip

      assert_equal testcase[:html], actual, testcase[:markdown]
    end
  end

  def test_smart_hardbreak_no_spaces
    markdown = "\"foo\"\nbaz"

    assert_equal "<p>“foo”<br />\nbaz</p>\n", CommonMarker.render_html(markdown, [:smart, :hardbreaks])
  end

  def test_smart_hardbreak_spaces
    markdown = "\"foo\"  \nbaz"

    assert_equal "<p>“foo”<br />\nbaz</p>\n", CommonMarker.render_html(markdown, [:smart, :hardbreaks])
  end
end
