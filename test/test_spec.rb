require 'test_helper'
require 'json'

class TestSpec < Minitest::Test
  cases = JSON.parse(open('test/spec_tests.json', 'r').read)
  cases.each do |testcase|
    # next unless testcase['example'] == 307
    doc = Node.parse_string(testcase['markdown'])
    define_method("test_to_html_example_#{testcase['example']}") do
      actual = doc.to_html
      doc.free
      assert_equal testcase['html'], actual, testcase['markdown']
    end
    define_method("test_html_renderer_example_#{testcase['example']}") do
      actual = HtmlRenderer.new.render(doc)
      doc.free
      File.write('test.txt', testcase['html'])
      File.write('actual.txt', actual)
      assert_equal testcase['html'], actual, testcase['markdown']
    end
  end
end
