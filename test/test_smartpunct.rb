require 'test_helper'

class SmartPunctTest < Minitest::Test
  smart_punct = open_spec_file('smart_punct.txt')

  smart_punct.each do |testcase|
    doc = Node.parse_string(testcase[:markdown], :smart)

    define_method("test_smart_punct_example_#{testcase[:example]}") do
      actual = doc.to_html.strip

      assert_equal testcase[:html], actual, testcase[:markdown]
    end
  end
end
