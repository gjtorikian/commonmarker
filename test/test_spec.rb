require 'test_helper'
require 'json'

class TestSpec < Minitest::Test
  spec = open_spec_file('spec.txt', normalize: true)

  spec.each do |testcase|
    # next unless testcase['example'] == 420
    doc = CommonMarker.render_doc(testcase[:markdown])

    define_method("test_to_html_example_#{testcase[:example]}") do
      actual = doc.to_html.rstrip
      assert_equal testcase[:html], actual, testcase[:markdown]
    end

    define_method("test_html_renderer_example_#{testcase[:example]}") do
      actual = HtmlRenderer.new.render(doc).rstrip
      File.write('test.txt', testcase[:html])
      File.write('actual.txt', actual)
      assert_equal testcase[:html], actual, testcase[:markdown]
    end
  end
end
