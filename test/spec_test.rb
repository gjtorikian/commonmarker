# frozen_string_literal: true

require "test_helper"
require "json"

class SpecTest < Minitest::Test
  spec = load_spec_file("spec.txt")

  spec.each do |testcase|
    next if testcase[:extensions].include?(:tagfilter)

    define_method(:"test_to_html_example_#{testcase[:example]}") do
      # The defaults are the spec's: only the spec's own raw-HTML and GFM
      # quirk settings are added, plus the extensions each example names.
      options = {
        render: { unsafe: true, gfm_quirks: true },
        extension: { tasklist: true },
      }

      testcase[:extensions].each do |ext|
        options[:extension][ext] = true
      end

      actual = Commonmarker.to_html(testcase[:markdown], options: options).rstrip

      assert_equal testcase[:html], actual, testcase[:markdown]
    end
  end
end
