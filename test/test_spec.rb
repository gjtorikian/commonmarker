require 'test_helper'
require 'json'

class TestSpec < Minitest::Unit::TestCase
  cases = JSON.parse(open("test/spec_tests.json", 'r').read)
  cases.each do |testcase|
    define_method("test_to_html_example_#{testcase['example']}") do
      doc = Node.parse_string(testcase['markdown'])
      actual = doc.to_html
      doc.free
      assert_equal testcase['html'], actual, testcase['markdown']
    end
    define_method("test_html_renderer_example_#{testcase['example']}") do
      doc = Node.parse_string(testcase['markdown'])
      actual = HtmlRenderer.new.render(doc)
      doc.free
      assert_equal testcase['html'], actual, testcase['markdown']
    end
  end
end
