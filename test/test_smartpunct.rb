# frozen_string_literal: true

require 'test_helper'

class SmartPunctTest < Minitest::Test
  smart_punct = open_spec_file('smart_punct.txt')

  smart_punct.each do |testcase|
    doc = Markly.parse(testcase[:markdown], flags: Markly::SMART)

    define_method("test_smart_punct_example_#{testcase[:example]}") do
      actual = doc.to_html.strip

      assert_equal testcase[:html], actual, testcase[:markdown]
    end
  end

  def test_smart_hardbreak_no_spaces_parse
    markdown = "\"foo\"\nbaz"
    result = "<p>“foo”<br />\nbaz</p>\n"
    doc = Markly.parse(markdown, flags: Markly::SMART)
    assert_equal result, doc.to_html(flags: Markly::HARD_BREAKS)
  end
end
