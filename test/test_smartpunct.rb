# frozen_string_literal: true

require "test_helper"

class SmartPunctTest < Minitest::Test
  smart_punct = load_spec_file("smart_punct.txt")

  smart_punct.each do |testcase|
    opts = {
      parse: {
        smart: true,
      },
    }

    define_method("test_smart_punct_example_#{testcase[:example]}") do
      html = Commonmarker.to_html(testcase[:markdown], opts).strip

      assert_equal testcase[:html], html, testcase[:markdown]
    end
  end

  def test_smart_hardbreak_no_spaces_render_doc
    markdown = "\"foo\"\nbaz"
    result = "<p>“foo”<br />\nbaz</p>\n"
    opts = {
      parse: {
        smart: true,
      },
      render: {
        hardbreaks: true,
      },
    }
    html = Commonmarker.commonmark_to_html(markdown, opts)
    assert_equal(result, html)
  end
end
