# frozen_string_literal: true

require "test_helper"
require "json"

class TestSpec < Minitest::Test
  spec = load_spec_file("spec.txt")

  spec.each do |testcase|
    html = Commonmarker.to_html(testcase[:markdown])
    focus
    define_method("test_to_html_example_#{testcase[:example]}") do
      opts = {
        render: {
          unsafe_: true,
        },
        extension: testcase[:extensions].each_with_object({}) do |ext, hash|
          hash[ext] = true
        end
      }

      options = Commonmarker::Config.merged_with_defaults(opts)
      options[:extension].delete(:header_ids) # this interefers with the spec.txt extension-less capability
      actual = Commonmarker.to_html(testcase[:markdown].strip, options: options).rstrip
      # debugger if actual != testcase[:html]
      Commonmarker.to_html(testcase[:markdown].strip, options: options).rstrip
      assert_equal testcase[:html], actual, testcase[:markdown]
    end
  end
end
