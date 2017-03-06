require 'test_helper'
require 'json'

class TestSpec < Minitest::Test
  spec = open_spec_file('spec.txt')

  spec.each do |testcase|
    # next unless testcase['example'] == 420
    doc = CommonMarker.render_doc(testcase[:markdown], :DEFAULT, testcase[:extensions])

    define_method("test_to_html_example_#{testcase[:example]}") do
      actual = doc.to_html(:DEFAULT, testcase[:extensions]).rstrip
      assert_equal testcase[:html], actual, testcase[:markdown]
    end

    unless testcase[:extensions].any?
      define_method("test_html_renderer_example_#{testcase[:example]}") do
        actual = HtmlRenderer.new.render(doc).rstrip
        File.write('test.txt', testcase[:html])
        File.write('actual.txt', actual)
        assert_equal testcase[:html], actual, testcase[:markdown]
      end
    end
  end
end
